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

class TransferScreen extends StatefulWidget {
  final Transfer? edit;
  const TransferScreen({super.key, this.edit});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  late final AppState s = context.read<AppState>();
  late final Transfer? e = widget.edit;
  late String? _from = e?.fromAccount ?? s.accounts.firstOrNull?.id;
  late String? _to = e?.toAccount ?? (s.accounts.length > 1 ? s.accounts[1].id : null);
  late final _amount = TextEditingController(text: e == null ? '' : fmtNum(e!.amountFrom).replaceAll(' ', ' '));
  late final _amountTo = TextEditingController(text: e == null ? '' : fmtNum(e!.amountTo).replaceAll(' ', ' '));
  late final _comment = TextEditingController(text: e?.comment ?? '');
  late DateTime _date = e?.date ?? DateTime.now();
  bool _toEdited = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _toEdited = e != null;
    _amount.addListener(_sync);
    _amountTo.addListener(() => setState(() {}));
  }

  void _sync() {
    if (!_differs || _toEdited) {
      setState(() {});
      return;
    }
    final v = parseAmount(_amount.text);
    final a = s.accountById(_from)!, b = s.accountById(_to)!;
    if (v != null) {
      final inBase = s.toBase(v, a.currency);
      final rate = s.rates[b.currency];
      final converted = b.currency == s.baseCurrency ? inBase : (rate == null ? v : inBase * rate);
      _amountTo.text = fmtNum(converted).replaceAll(' ', ' ');
    }
    setState(() {});
  }

  @override
  void dispose() {
    _amount.dispose();
    _amountTo.dispose();
    _comment.dispose();
    super.dispose();
  }

  bool get _differs {
    final a = s.accountById(_from), b = s.accountById(_to);
    return a != null && b != null && a.currency != b.currency;
  }

  bool get _valid {
    final v = parseAmount(_amount.text) ?? 0;
    final v2 = _differs ? (parseAmount(_amountTo.text) ?? 0) : v;
    return _from != null && _to != null && _from != _to && v > 0 && v2 > 0;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final v = parseAmount(_amount.text)!;
      await s.saveTransfer(
        id: e?.id,
        from: _from!,
        to: _to!,
        amountFrom: v,
        amountTo: _differs ? parseAmount(_amountTo.text)! : v,
        date: _date,
        comment: _comment.text.trim(),
      );
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context);
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirm(context, tr('Удалить перевод?'), danger: true, yes: 'УДАЛИТЬ')) return;
    try {
      await s.deleteTransfer(e!.id);
      if (mounted) Navigator.pop(context);
    } catch (err) {
      if (mounted) showError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final a = s.accountById(_from), b = s.accountById(_to);
    Widget amountField(TextEditingController c, String label, String? cur, {VoidCallback? onEdit}) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: p.secondary, fontSize: 15)),
          Row(
            children: [
              SizedBox(
                width: 170,
                child: TextField(
                  controller: c,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]'))],
                  onChanged: (_) => onEdit?.call(),
                  style: TextStyle(color: p.text, fontSize: 22),
                  decoration: const InputDecoration(hintText: '0'),
                ),
              ),
              const SizedBox(width: 12),
              Text(cur ?? '', style: TextStyle(color: p.text, fontSize: 20)),
            ],
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            back: true,
            title: e == null ? tr('Создать перевод') : tr('Перевод'),
            actions: [if (e != null) HeaderIcon(icon: PI.trash, onTap: _delete)],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(0, 18, 0, MediaQuery.paddingOf(context).bottom + 30),
              children: [
                LabeledValue(
                  label: tr('Со счета'),
                  value: a?.name ?? tr('Не задан'),
                  onTap: () async {
                    final r = await showAccountPicker(context, selected: _from, withTotal: false);
                    if (r != null && r.isNotEmpty) setState(() => _from = r);
                  },
                ),
                Center(
                  child: IconButton(
                    onPressed: () => setState(() {
                      final t = _from;
                      _from = _to;
                      _to = t;
                    }),
                    icon: Icon(PI.arrowsDownUp, color: p.accent, size: 28),
                  ),
                ),
                LabeledValue(
                  label: tr('На счет'),
                  value: b?.name ?? tr('Не задан'),
                  onTap: () async {
                    final r = await showAccountPicker(context, selected: _to, withTotal: false);
                    if (r != null && r.isNotEmpty) setState(() => _to = r);
                  },
                ),
                amountField(_amount, tr('Сумма'), a?.currency),
                if (_differs) amountField(_amountTo, tr('Сумма зачисления'), b?.currency, onEdit: () => _toEdited = true),
                LabeledValue(
                  label: tr('Дата'),
                  value: fullDate(_date),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      locale: Locale(L10n.locale),
                    );
                    if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    controller: _comment,
                    style: TextStyle(color: p.text, fontSize: 17.5),
                    decoration: InputDecoration(hintText: tr('Комментарий')),
                  ),
                ),
                if (_from != null && _from == _to)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(tr('Выберите разные счета'), style: TextStyle(color: p.danger)),
                  ),
                const SizedBox(height: 40),
                Center(
                  child: YellowButton(text: e == null ? tr('Перевести') : tr('Сохранить'), loading: _saving, onTap: _valid ? _save : null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TransferHistoryScreen extends StatelessWidget {
  const TransferHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.watch<AppState>();
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(back: true, title: tr('История переводов')),
          Expanded(
            child: s.transfers.isEmpty
                ? EmptyState(text: tr('Переводов пока нет'), icon: PI.arrowsLeftRight)
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.paddingOf(context).bottom + 20),
                    itemCount: s.transfers.length,
                    itemBuilder: (_, i) {
                      final t = s.transfers[i];
                      final a = s.accountById(t.fromAccount), b = s.accountById(t.toAccount);
                      return FadeSlideIn(
                        index: i < 10 ? i : 0,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: p.card,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => Navigator.push(context, pageRoute(TransferScreen(edit: t))),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(12)),
                                      child: const Icon(PI.arrowsLeftRight, color: Color(0xFFF4F4E8)),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${a?.name ?? '—'}  →  ${b?.name ?? '—'}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: p.text, fontSize: 16.5),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            [df('d MMM yyyy, HH:mm').format(t.date), if (t.comment.isNotEmpty) t.comment].join(' · '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: p.secondary, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      fmtMoney(t.amountFrom, a?.currency ?? s.baseCurrency),
                                      style: TextStyle(color: p.text, fontSize: 17),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
