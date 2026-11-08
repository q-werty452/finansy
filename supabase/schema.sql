-- =====================================================================
--  Финансы — схема бэкенда (Supabase / PostgreSQL)
--  Выполнить целиком в Supabase → SQL Editor → New query → Run.
--  Скрипт идемпотентный: можно запускать повторно.
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
--  Таблицы
-- ---------------------------------------------------------------------
create sequence if not exists public.profile_short_id_seq start 14921444;

create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  short_id    bigint not null default nextval('public.profile_short_id_seq'),
  name        text not null default '',
  email       text,
  avatar_url  text,
  currency    text,                       -- валюта по умолчанию; null = онбординг не пройден
  settings    jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.accounts (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name            text not null,
  icon            text not null default 'money',
  color           text not null default '#9BB68E',
  currency        text not null default 'RUB',
  initial_balance numeric(18,2) not null default 0,
  balance         numeric(18,2) not null default 0,
  in_total        boolean not null default true,
  position        int not null default 0,
  created_at      timestamptz not null default now()
);

create table if not exists public.categories (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  type       text not null check (type in ('expense','income')),
  name       text not null,
  icon       text not null default 'question',
  color      text not null default '#888888',
  position   int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.operations (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  type         text not null check (type in ('expense','income')),
  amount       numeric(18,2) not null check (amount > 0),
  account_id   uuid not null references public.accounts(id) on delete cascade,
  category_id  uuid references public.categories(id) on delete set null,
  date         timestamptz not null default now(),
  tags         text[] not null default '{}',
  comment      text not null default '',
  photos       text[] not null default '{}',
  recurring_id uuid,
  created_at   timestamptz not null default now()
);
create index if not exists operations_user_date on public.operations(user_id, date desc);

create table if not exists public.transfers (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  from_account uuid not null references public.accounts(id) on delete cascade,
  to_account   uuid not null references public.accounts(id) on delete cascade,
  amount_from  numeric(18,2) not null check (amount_from > 0),
  amount_to    numeric(18,2) not null check (amount_to > 0),
  date         timestamptz not null default now(),
  comment      text not null default '',
  created_at   timestamptz not null default now(),
  check (from_account <> to_account)
);

create table if not exists public.tags (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name    text not null,
  primary key (user_id, name)
);

create table if not exists public.recurring_payments (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  type        text not null check (type in ('expense','income')),
  name        text not null,
  period      text not null default 'month' check (period in ('day','week','month','quarter','year')),
  auto_add    boolean not null default false,
  start_at    timestamptz not null,
  end_date    date,
  next_run    timestamptz not null,
  account_id  uuid references public.accounts(id) on delete set null,
  category_id uuid references public.categories(id) on delete set null,
  amount      numeric(18,2),
  tags        text[] not null default '{}',
  comment     text not null default '',
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);

create table if not exists public.reminders (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name       text not null,
  period     text not null default 'once' check (period in ('once','day','week','month','year')),
  remind_at  timestamptz not null,
  comment    text not null default '',
  enabled    boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.feedback (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid default auth.uid() references auth.users(id) on delete set null,
  subject    text not null,
  email      text not null,
  message    text not null,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
--  Row Level Security: каждый видит только свои данные
-- ---------------------------------------------------------------------
alter table public.profiles           enable row level security;
alter table public.accounts           enable row level security;
alter table public.categories         enable row level security;
alter table public.operations         enable row level security;
alter table public.transfers          enable row level security;
alter table public.tags               enable row level security;
alter table public.recurring_payments enable row level security;
alter table public.reminders          enable row level security;
alter table public.feedback           enable row level security;

do $$
declare t text;
begin
  foreach t in array array['accounts','categories','operations','transfers','tags','recurring_payments','reminders'] loop
    execute format('drop policy if exists own_rows on public.%I', t);
    execute format('create policy own_rows on public.%I for all using (user_id = auth.uid()) with check (user_id = auth.uid())', t);
  end loop;
end $$;

drop policy if exists own_profile on public.profiles;
create policy own_profile on public.profiles for all using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists feedback_insert on public.feedback;
create policy feedback_insert on public.feedback for insert with check (user_id = auth.uid());

-- ---------------------------------------------------------------------
--  Баланс счетов: всегда пересчитывается из операций и переводов
-- ---------------------------------------------------------------------
create or replace function public.refresh_account_balance(acc uuid)
returns void language sql security definer set search_path = public as $$
  update accounts a set balance = a.initial_balance
    + coalesce((select sum(case when o.type = 'income' then o.amount else -o.amount end)
                from operations o where o.account_id = a.id), 0)
    + coalesce((select sum(t.amount_to) from transfers t where t.to_account = a.id), 0)
    - coalesce((select sum(t.amount_from) from transfers t where t.from_account = a.id), 0)
  where a.id = acc;
$$;

create or replace function public.trg_operations_balance()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op in ('UPDATE','DELETE') then perform refresh_account_balance(old.account_id); end if;
  if tg_op in ('INSERT','UPDATE') then perform refresh_account_balance(new.account_id); end if;
  return null;
end $$;

create or replace function public.trg_transfers_balance()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op in ('UPDATE','DELETE') then
    perform refresh_account_balance(old.from_account);
    perform refresh_account_balance(old.to_account);
  end if;
  if tg_op in ('INSERT','UPDATE') then
    perform refresh_account_balance(new.from_account);
    perform refresh_account_balance(new.to_account);
  end if;
  return null;
end $$;

create or replace function public.trg_accounts_initial()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' or new.initial_balance is distinct from old.initial_balance then
    perform refresh_account_balance(new.id);
  end if;
  return null;
end $$;

drop trigger if exists operations_balance on public.operations;
create trigger operations_balance after insert or update or delete on public.operations
  for each row execute function public.trg_operations_balance();

drop trigger if exists transfers_balance on public.transfers;
create trigger transfers_balance after insert or update or delete on public.transfers
  for each row execute function public.trg_transfers_balance();

drop trigger if exists accounts_initial on public.accounts;
create trigger accounts_initial after insert or update of initial_balance on public.accounts
  for each row execute function public.trg_accounts_initial();

create or replace function public.recalc_balances()
returns void language plpgsql security invoker set search_path = public as $$
declare a record;
begin
  for a in select id from accounts where user_id = auth.uid() loop
    perform refresh_account_balance(a.id);
  end loop;
end $$;

-- Теги: каждое новое слово попадает в словарь для поиска
create or replace function public.trg_collect_tags()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into tags(user_id, name)
    select new.user_id, unnest(new.tags) on conflict do nothing;
  return null;
end $$;

drop trigger if exists operations_tags on public.operations;
create trigger operations_tags after insert or update of tags on public.operations
  for each row execute function public.trg_collect_tags();
drop trigger if exists recurring_tags on public.recurring_payments;
create trigger recurring_tags after insert or update of tags on public.recurring_payments
  for each row execute function public.trg_collect_tags();

-- ---------------------------------------------------------------------
--  Новый пользователь: профиль + стандартные категории
-- ---------------------------------------------------------------------
create or replace function public.seed_categories(uid uuid)
returns void language sql security definer set search_path = public as $$
  insert into categories(user_id, type, name, icon, color, position) values
    (uid,'expense','Здоровье','heartbeat','#F63535',0),
    (uid,'expense','Досуг','wallet','#41BCA8',1),
    (uid,'expense','Дом','house','#FB8837',2),
    (uid,'expense','Кафе','forkKnife','#A788D6',3),
    (uid,'expense','Образование','graduationCap','#4895DD',4),
    (uid,'expense','Подарки','gift','#E16095',5),
    (uid,'expense','Продукты','basket','#67AF45',6),
    (uid,'expense','Семья','users','#F2B108',7),
    (uid,'expense','Спорт','barbell','#EA6F18',8),
    (uid,'expense','Транспорт','bus','#2E78CF',9),
    (uid,'expense','Другое','question','#888888',10),
    (uid,'income','Зарплата','handCoins','#2E78CF',0),
    (uid,'income','Подарок','gift','#E16095',1),
    (uid,'income','Проценты по вкладам','bank','#67AF45',2),
    (uid,'income','Другое','question','#67AF45',3);
$$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into profiles(id, name, email, avatar_url)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data->>'full_name',''),
             nullif(new.raw_user_meta_data->>'name',''),
             split_part(coalesce(new.email,''),'@',1)),
    new.email,
    coalesce(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture')
  ) on conflict (id) do nothing;
  perform seed_categories(new.id);
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------
--  Регулярные платежи: автодобавление операций
-- ---------------------------------------------------------------------
create or replace function public.next_period(ts timestamptz, period text)
returns timestamptz language sql immutable as $$
  select case period
    when 'day'     then ts + interval '1 day'
    when 'week'    then ts + interval '1 week'
    when 'month'   then ts + interval '1 month'
    when 'quarter' then ts + interval '3 months'
    else                ts + interval '1 year' end;
$$;

-- Обрабатывает просроченные платежи; uid = null → всех пользователей (для cron)
create or replace function public.process_recurring_for(uid uuid)
returns int language plpgsql security definer set search_path = public as $$
declare r record; n int := 0;
begin
  for r in
    select * from recurring_payments
    where active and next_run <= now() and (uid is null or user_id = uid)
    for update skip locked
  loop
    while r.next_run <= now() and (r.end_date is null or r.next_run::date <= r.end_date) loop
      if r.auto_add and r.account_id is not null and coalesce(r.amount,0) > 0 then
        insert into operations(user_id, type, amount, account_id, category_id, date, tags, comment, recurring_id)
        values (r.user_id, r.type, r.amount, r.account_id, r.category_id, r.next_run, r.tags,
                case when r.comment = '' then r.name else r.comment end, r.id);
        n := n + 1;
      end if;
      r.next_run := next_period(r.next_run, r.period);
    end loop;
    update recurring_payments set next_run = r.next_run,
      active = (r.end_date is null or r.next_run::date <= r.end_date)
    where id = r.id;
  end loop;
  return n;
end $$;

create or replace function public.process_my_recurring()
returns int language sql security invoker set search_path = public as $$
  select process_recurring_for(auth.uid());
$$;

revoke execute on function public.process_recurring_for(uuid) from public, anon, authenticated;
revoke execute on function public.refresh_account_balance(uuid) from public, anon;

-- Если в проекте включён pg_cron (Database → Extensions → pg_cron),
-- раскомментируйте, чтобы платежи добавлялись даже при закрытом приложении:
-- select cron.schedule('process-recurring', '*/10 * * * *', $$select public.process_recurring_for(null)$$);

-- ---------------------------------------------------------------------
--  Данные: удалить всё / удалить аккаунт / бэкап
-- ---------------------------------------------------------------------
create or replace function public.delete_all_data()
returns void language plpgsql security invoker set search_path = public as $$
begin
  delete from operations where user_id = auth.uid();
  delete from transfers where user_id = auth.uid();
  delete from recurring_payments where user_id = auth.uid();
  delete from reminders where user_id = auth.uid();
  delete from tags where user_id = auth.uid();
  delete from accounts where user_id = auth.uid();
  delete from categories where user_id = auth.uid();
  perform seed_categories(auth.uid());
  update profiles set currency = null, settings = '{}'::jsonb where id = auth.uid();
end $$;

create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public, auth as $$
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  delete from auth.users where id = auth.uid();
end $$;
revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

create or replace function public.export_backup()
returns jsonb language sql security invoker set search_path = public as $$
  select jsonb_build_object(
    'format', 'finansy-backup', 'version', 1, 'created_at', now(),
    'profile',    (select jsonb_build_object('currency', currency, 'settings', settings) from profiles where id = auth.uid()),
    'accounts',   coalesce((select jsonb_agg(to_jsonb(a) - 'user_id') from accounts a where user_id = auth.uid()), '[]'),
    'categories', coalesce((select jsonb_agg(to_jsonb(c) - 'user_id') from categories c where user_id = auth.uid()), '[]'),
    'operations', coalesce((select jsonb_agg(to_jsonb(o) - 'user_id') from operations o where user_id = auth.uid()), '[]'),
    'transfers',  coalesce((select jsonb_agg(to_jsonb(t) - 'user_id') from transfers t where user_id = auth.uid()), '[]'),
    'recurring',  coalesce((select jsonb_agg(to_jsonb(r) - 'user_id') from recurring_payments r where user_id = auth.uid()), '[]'),
    'reminders',  coalesce((select jsonb_agg(to_jsonb(r) - 'user_id') from reminders r where user_id = auth.uid()), '[]')
  );
$$;

create or replace function public.restore_backup(data jsonb)
returns void language plpgsql security invoker set search_path = public as $$
declare uid uuid := auth.uid();
begin
  if data->>'format' is distinct from 'finansy-backup' then
    raise exception 'Неверный формат файла';
  end if;
  delete from operations where user_id = uid;
  delete from transfers where user_id = uid;
  delete from recurring_payments where user_id = uid;
  delete from reminders where user_id = uid;
  delete from accounts where user_id = uid;
  delete from categories where user_id = uid;

  insert into categories select (jsonb_populate_record(null::categories, x || jsonb_build_object('user_id', uid))).*
    from jsonb_array_elements(data->'categories') x;
  insert into accounts select (jsonb_populate_record(null::accounts, x || jsonb_build_object('user_id', uid))).*
    from jsonb_array_elements(data->'accounts') x;
  insert into operations select (jsonb_populate_record(null::operations, x || jsonb_build_object('user_id', uid))).*
    from jsonb_array_elements(data->'operations') x;
  insert into transfers select (jsonb_populate_record(null::transfers, x || jsonb_build_object('user_id', uid))).*
    from jsonb_array_elements(data->'transfers') x;
  insert into recurring_payments select (jsonb_populate_record(null::recurring_payments, x || jsonb_build_object('user_id', uid))).*
    from jsonb_array_elements(data->'recurring') x;
  insert into reminders select (jsonb_populate_record(null::reminders, x || jsonb_build_object('user_id', uid))).*
    from jsonb_array_elements(data->'reminders') x;

  update profiles set
    currency = coalesce(data->'profile'->>'currency', currency),
    settings = coalesce(data->'profile'->'settings', settings)
  where id = uid;
  perform recalc_balances();
end $$;

-- ---------------------------------------------------------------------
--  Хранилище: аватарки и фото чеков (папка = id пользователя)
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public) values ('avatars','avatars',true)  on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('photos','photos',true)    on conflict (id) do nothing;

drop policy if exists "own files insert" on storage.objects;
create policy "own files insert" on storage.objects for insert to authenticated
  with check (bucket_id in ('avatars','photos') and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "own files update" on storage.objects;
create policy "own files update" on storage.objects for update to authenticated
  using (bucket_id in ('avatars','photos') and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "own files delete" on storage.objects;
create policy "own files delete" on storage.objects for delete to authenticated
  using (bucket_id in ('avatars','photos') and (storage.foldername(name))[1] = auth.uid()::text);
