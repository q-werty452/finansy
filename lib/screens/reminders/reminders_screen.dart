import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../l10n.dart';
import '../../services/notifications.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../util/format.dart';
import '../../util/icons.dart';
import '../../widgets/common.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _desc = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.watch<AppState>();
    final list = [...s.reminders]..sort((a, b) => _desc ? b.remindAt.compareTo(a.remindAt) : a.remindAt.compareTo(b.remindAt));
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          Column(
            children: [
              AppHeader(title: tr('Напоминания')),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 8, 0),
                  child: IconButton(
                    onPressed: () => setState(() => _desc = !_desc),
                    icon: AnimatedRotation(
                      turns: _desc ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(PI.sortAscending, color: p.text, size: 30),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? EmptyState(text: tr('Напоминаний пока нет'), icon: PI.bellSimple)
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.paddingOf(context).bottom + 110),
                        itemCount: list.length,
                        itemBuilder: (_, i) => FadeSlideIn(
                          index: i,
                          child: _ReminderCard(r: list[i]),
                        ),
                      ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 28,
            child: Center(child: YellowFab(onTap: () => Navigator.push(context, pageRoute(const ReminderEditScreen())))),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder r;
  const _ReminderCard({required this.r});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(r.id),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(color: p.danger, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          child: const Icon(PI.trash, color: Colors.white),
        ),
        confirmDismiss: (_) => confirm(context, tr('Удалить напоминание?'), danger: true, yes: 'УДАЛИТЬ'),
        onDismissed: (_) => s.deleteReminder(r).catchError((e) {
          if (context.mounted) showError(context, e);
        }),
        child: Material(
          color: p.card,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.push(context, pageRoute(ReminderEditScreen(edit: r))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: TextStyle(color: p.text, fontSize: 18.5, letterSpacing: 0.2)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(PI.calendarDots, size: 22, color: p.secondary),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${fullDate(r.remindAt)}, ${hhmm(r.remindAt)}${r.period == 'once' ? '' : ' · ${periodName(r.period).toLowerCase()}'}',
                                style: TextStyle(color: p.secondary, fontSize: 15.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SmallSwitch(
                    value: r.enabled,
                    onChanged: (v) async {
                      if (v) await Notifications.requestPermission();
                      s.toggleReminder(r, v).catchError((e) {
                        if (context.mounted) showError(context, e);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReminderEditScreen extends StatefulWidget {
  final Reminder? edit;
  const ReminderEditScreen({super.key, this.edit});

  @override
  State<ReminderEditScreen> createState() => _ReminderEditScreenState();
}

class _ReminderEditScreenState extends State<ReminderEditScreen> {
  late final AppState s = context.read<AppState>();
  late final Reminder? e = widget.edit;
  late final _name = TextEditingController(text: e?.name ?? '');
  late final _comment = TextEditingController(text: e?.comment ?? '');
  late String _period = e?.period ?? 'once';
  late DateTime _at = e?.remindAt ?? DateTime.now().add(const Duration(hours: 1)).copyWith(second: 0, millisecond: 0, microsecond: 0);
  bool _tried = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await Notifications.requestPermission();
      await s.saveReminder(
        id: e?.id,
        name: _name.text.trim(),
        period: _period,
        at: _at,
        comment: _comment.text.trim(),
        enabled: e?.enabled ?? true,
      );
      if (mounted) Navigator.pop(context);
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirm(context, tr('Удалить напоминание?'), danger: true, yes: 'УДАЛИТЬ')) return;
    try {
      await s.deleteReminder(e!);
      if (mounted) Navigator.pop(context);
    } catch (err) {
      if (mounted) showError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            back: true,
            title: e == null ? tr('Создать напоминание') : tr('Напоминания'),
            actions: [if (e != null) HeaderIcon(icon: PI.trash, onTap: _delete)],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(0, 34, 0, MediaQuery.paddingOf(context).bottom + 30),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('Имя напоминания'), style: TextStyle(color: p.secondary, fontSize: 13.8)),
                      TextField(
                        controller: _name,
                        autofocus: e == null,
                        onChanged: (_) => setState(() {}),
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(color: p.text, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: tr('Имя'),
                          errorText: _tried && _name.text.trim().isEmpty ? tr('Обязательное поле для заполнения') : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (bc) => LabeledValue(
                    label: tr('Периодичность напоминания'),
                    value: periodName(_period),
                    onTap: () async {
                      final box = bc.findRenderObject() as RenderBox;
                      final pos = box.localToGlobal(Offset(16, box.size.height - 10));
                      final r = await showAnchoredMenu<String>(context, pos, [
                        for (final k in ['once', 'day', 'week', 'month', 'year']) (k, periodName(k), null),
                      ]);
                      if (r != null) setState(() => _period = r);
                    },
                  ),
                ),
                LabeledValue(
                  label: tr('Дата'),
                  value: fullDate(_at),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _at,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      locale: Locale(L10n.locale),
                    );
                    if (d != null) setState(() => _at = DateTime(d.year, d.month, d.day, _at.hour, _at.minute));
                  },
                ),
                LabeledValue(
                  label: tr('Время'),
                  value: hhmm(_at),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_at));
                    if (t != null) setState(() => _at = DateTime(_at.year, _at.month, _at.day, t.hour, t.minute));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
                const SizedBox(height: 70),
                Center(
                  child: YellowButton(text: e == null ? tr('Создать') : tr('Сохранить'), loading: _saving, onTap: _save),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
