import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../l10n.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../util/format.dart';
import '../../util/icons.dart';
import '../../widgets/common.dart';
import '../../widgets/pickers.dart';
import '../../widgets/tags.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  bool _search = false;
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.watch<AppState>();
    final q = _q.text.trim().toLowerCase();
    final list = s.recurring.where((r) => q.isEmpty || r.name.toLowerCase().contains(q) || r.comment.toLowerCase().contains(q)).toList();
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          Column(
            children: [
              AppHeader(
                title: tr('Регулярные платежи'),
                titleWidget: _search
                    ? TextField(
                        controller: _q,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: p.onHeader, fontSize: 18),
                        cursorColor: p.onHeader,
                        decoration: InputDecoration(
                          hintText: tr('Поиск'),
                          hintStyle: TextStyle(color: p.headerInactive),
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      )
                    : null,
                actions: [
                  HeaderIcon(
                    icon: _search ? Icons.close : PI.magnifyingGlass,
                    size: 30,
                    onTap: () => setState(() {
                      _search = !_search;
                      if (!_search) _q.clear();
                    }),
                  ),
                ],
              ),
              Expanded(
                child: s.recurring.isEmpty
                    ? EmptyState(text: tr('Добавьте регулярный\nплатеж'), icon: PI.arrowsClockwise, inner: PI.plus)
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.paddingOf(context).bottom + 110),
                        itemCount: list.length,
                        itemBuilder: (_, i) => FadeSlideIn(
                          index: i,
                          child: _RecurringCard(r: list[i]),
                        ),
                      ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 28,
            child: Center(child: YellowFab(onTap: () => Navigator.push(context, pageRoute(const RecurringEditScreen())))),
          ),
        ],
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  final Recurring r;
  const _RecurringCard({required this.r});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.read<AppState>();
    final c = s.categoryById(r.categoryId);
    final a = s.accountById(r.accountId);
    final due = !r.nextRun.isAfter(DateTime.now().add(const Duration(days: 1)));
    final canPay = !r.autoAdd && a != null && (r.amount ?? 0) > 0 && r.active;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: p.card,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => Navigator.push(context, pageRoute(RecurringEditScreen(edit: r))),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    IconCircle(icon: c?.icon ?? 'arrowsClockwise', color: c?.col ?? p.accentDim, size: 42),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name, style: TextStyle(color: p.text, fontSize: 16)),
                          const SizedBox(height: 3),
                          Text(periodName(r.period), style: TextStyle(color: p.secondary, fontSize: 14)),
                        ],
                      ),
                    ),
                    if (r.amount != null)
                      Text(
                        '${r.type == OpType.income ? '+' : '-'}${fmtMoney(r.amount!, a?.currency ?? s.baseCurrency)}',
                        style: TextStyle(color: r.type == OpType.income ? p.accent : p.text, fontSize: 17, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(PI.calendarDots, size: 20, color: due ? p.danger : p.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.active ? tr('Следующий платеж: {d}', {'d': df('d MMMM, HH:mm').format(r.nextRun)}) : tr('Завершен'),
                        style: TextStyle(color: due && r.active ? p.danger : p.secondary, fontSize: 14.5),
                      ),
                    ),
                    if (r.autoAdd)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
                        child: Text(tr('Автоматически'), style: TextStyle(color: p.accent, fontSize: 12.5)),
                      )
                    else if (canPay)
                      GestureDetector(
                        onTap: () async {
                          try {
                            await s.payRecurring(r);
                            HapticFeedback.mediumImpact();
                            if (context.mounted) showSnack(context, tr('Платеж внесен'));
                          } catch (e) {
                            if (context.mounted) showError(context, e);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: p.yellow, borderRadius: BorderRadius.circular(14)),
                          child: Text(tr('Внести платеж'), style: TextStyle(color: p.onYellow, fontSize: 13.5)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecurringEditScreen extends StatefulWidget {
  final Recurring? edit;
  const RecurringEditScreen({super.key, this.edit});

  @override
  State<RecurringEditScreen> createState() => _RecurringEditScreenState();
}

class _RecurringEditScreenState extends State<RecurringEditScreen> with SingleTickerProviderStateMixin {
  late final AppState s = context.read<AppState>();
  late final Recurring? e = widget.edit;
  late final TabController _tabs = TabController(length: 2, vsync: this, initialIndex: e?.type == OpType.income ? 1 : 0);
  late final _name = TextEditingController(text: e?.name ?? '');
  late final _amount = TextEditingController(text: e?.amount == null ? '' : fmtNum(e!.amount!).replaceAll(' ', ' '));
  late final _comment = TextEditingController(text: e?.comment ?? '');
  late String _period = e?.period ?? 'month';
  late bool _auto = e?.autoAdd ?? false;
  late DateTime _start = e?.startAt ?? DateTime.now().add(const Duration(hours: 1)).copyWith(second: 0, millisecond: 0, microsecond: 0);
  late DateTime? _end = e?.endDate;
  late String? _account = e?.accountId;
  late String? _category = e?.categoryId;
  late List<String> _tags = [...?e?.tags];
  bool _tried = false;
  bool _saving = false;
  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      final c = s.categoryById(_category);
      setState(() {
        if (c != null && c.type != _type) _category = null;
      });
    });
    _name.addListener(() => setState(() {}));
    _amount.addListener(() => setState(() {}));
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) setState(() => _tried = true);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _name.dispose();
    _amount.dispose();
    _comment.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  OpType get _type => _tabs.index == 1 ? OpType.income : OpType.expense;

  bool get _valid {
    if (_name.text.trim().isEmpty) return false;
    if (_auto && (_account == null || (parseAmount(_amount.text) ?? 0) <= 0)) return false;
    return true;
  }

  Future<void> _save() async {
    setState(() {
      _tried = true;
      _saving = true;
    });
    try {
      await s.saveRecurring(
        id: e?.id,
        type: _type,
        name: _name.text.trim(),
        period: _period,
        autoAdd: _auto,
        startAt: _start,
        endDate: _end,
        accountId: _account,
        categoryId: _category,
        amount: parseAmount(_amount.text),
        tags: _tags,
        comment: _comment.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirm(context, tr('Удалить платеж?'), danger: true, yes: 'УДАЛИТЬ')) return;
    try {
      await s.deleteRecurring(e!.id);
      if (mounted) Navigator.pop(context);
    } catch (err) {
      if (mounted) showError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final acc = s.accountById(_account);
    final cat = s.categoryById(_category);
    final nameErr = _tried && _name.text.trim().isEmpty;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            back: true,
            title: e == null ? tr('Создать напоминание') : tr('Регулярный платеж'),
            actions: [if (e != null) HeaderIcon(icon: PI.trash, onTap: _delete)],
            bottom: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: HeaderTabs(controller: _tabs, labels: [tr('РАСХОДЫ'), tr('ДОХОДЫ')]),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(0, 22, 0, MediaQuery.paddingOf(context).bottom + 30),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('Наименование платежа'), style: TextStyle(color: p.secondary, fontSize: 13.8)),
                      TextField(
                        controller: _name,
                        focusNode: _nameFocus,
                        autofocus: e == null,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(color: p.text, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: tr('Имя'),
                          errorText: nameErr ? tr('Обязательное поле для заполнения') : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (bc) => LabeledValue(
                    label: tr('Периодичность напоминания'),
                    value: periodName(_period),
                    onTap: () async {
                      final box = bc.findRenderObject() as RenderBox;
                      final pos = box.localToGlobal(Offset(16, box.size.height - 10));
                      final r = await showAnchoredMenu<String>(context, pos, [
                        for (final k in ['day', 'week', 'month', 'quarter', 'year']) (k, periodName(k), null),
                      ]);
                      if (r != null) setState(() => _period = r);
                    },
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _auto = !_auto),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 26, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(tr('Добавлять автоматически'), style: TextStyle(color: p.text, fontSize: 18)),
                        ),
                        SmallSwitch(value: _auto, onChanged: (v) => setState(() => _auto = v)),
                      ],
                    ),
                  ),
                ),
                LabeledValue(
                  label: tr('Дата начала напоминания'),
                  value: fullDate(_start),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _start,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      locale: Locale(L10n.locale),
                    );
                    if (d != null) setState(() => _start = DateTime(d.year, d.month, d.day, _start.hour, _start.minute));
                  },
                ),
                LabeledValue(
                  label: tr('Время'),
                  value: hhmm(_start),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start));
                    if (t != null) setState(() => _start = DateTime(_start.year, _start.month, _start.day, t.hour, t.minute));
                  },
                ),
                LabeledValue(
                  label: tr('Дата окончания напоминания'),
                  value: _end == null ? tr('Не задано') : fullDate(_end!),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _end ?? _start.add(const Duration(days: 365)),
                      firstDate: _start,
                      lastDate: DateTime(2100),
                      locale: Locale(L10n.locale),
                    );
                    setState(() => _end = d);
                  },
                ),
                LabeledValue(
                  label: tr('Счет'),
                  value: acc?.name ?? tr('Не задан'),
                  onTap: () async {
                    final r = await showAccountPicker(context, selected: _account, withTotal: false);
                    if (r != null && r.isNotEmpty) setState(() => _account = r);
                  },
                ),
                LabeledValue(
                  label: tr('Категория'),
                  value: cat?.name ?? tr('Выбрать категорию'),
                  onTap: () async {
                    final c = await showCategoryPicker(context, _type);
                    if (c != null) setState(() => _category = c.id);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('Сумма'), style: TextStyle(color: p.secondary, fontSize: 13.8)),
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _amount,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]'))],
                              style: TextStyle(color: p.text, fontSize: 16),
                              decoration: InputDecoration(hintText: tr('Не задано')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(acc?.currency ?? s.baseCurrency, style: TextStyle(color: p.text, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                TagsBlock(tags: _tags, onChanged: (t) => setState(() => _tags = t)),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('Комментарий'), style: TextStyle(color: p.secondary, fontSize: 13.8)),
                      TextField(
                        controller: _comment,
                        maxLines: null,
                        style: TextStyle(color: p.text, fontSize: 16),
                        decoration: InputDecoration(hintText: tr('Комментарий')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                Center(
                  child: YellowButton(text: e == null ? tr('Создать') : tr('Сохранить'), loading: _saving, onTap: _valid ? _save : null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
