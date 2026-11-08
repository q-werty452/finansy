import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n.dart';
import '../../state/app_state.dart';
import '../../state/prefs.dart';
import '../../theme.dart';
import '../../util/icons.dart';
import '../../widgets/common.dart';
import '../../widgets/pickers.dart';
import '../lock/lock_screen.dart';
import 'legal.dart';

Offset _anchor(BuildContext bc) {
  final box = bc.findRenderObject() as RenderBox;
  return box.localToGlobal(Offset(56, box.size.height - 14));
}

Widget _info(BuildContext context, String title, String text) => IconButton(
  onPressed: () => showAppDialog(
    context,
    (c) => AppDialog(
      title: title,
      content: Text(text, style: TextStyle(color: c.pal.text, fontSize: 16, height: 1.35)),
      actions: [DialogButton(tr('OK'), onTap: () => Navigator.pop(c))],
    ),
  ),
  icon: Icon(PI.info, color: context.pal.text, size: 24),
);

// ---------------------------------------------------------------------
//  Персонализация
// ---------------------------------------------------------------------
class PersonalizationScreen extends StatelessWidget {
  const PersonalizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.watch<AppState>();
    final home = s.setting<String>('homeAccount', 'total');
    final homeName = home == 'total' ? tr('Итого') : (s.accountById(home)?.name ?? tr('Итого'));
    final merge = s.mergeSmall;
    final defAcc = s.accountById(s.setting<String?>('defaultAccount', null));
    final fields = ['tags', 'comment', 'photo'].where(s.fieldOn).length;
    final fieldsLabel = fields == 3 ? tr('Все') : (fields == 0 ? tr('Отключено') : '$fields/3');
    final monthStart = s.setting<int>('monthStart', 1);
    final periodNames = {'day': tr('День'), 'week': tr('Неделя'), 'month': tr('Месяц'), 'year': tr('Год')};

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(back: true, title: tr('Персонализация')),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 20),
              children: [
                SectionLabel('Главная', padding: const EdgeInsets.fromLTRB(16, 22, 16, 0)),
                SettingTile(
                  icon: PI.moneyWavy,
                  title: tr('Показывать по умолчанию'),
                  value: homeName,
                  trailing: _info(
                    context,
                    tr('Показывать по умолчанию'),
                    tr('Какой счет будет выбран на главном экране при запуске приложения.'),
                  ),
                  onTap: () async {
                    final r = await showAccountPicker(context, selected: home == 'total' ? '' : home, showBalances: false);
                    if (r != null) {
                      await s.setSetting('homeAccount', r.isEmpty ? 'total' : r);
                      s.selectHomeAccount(r.isEmpty ? null : r);
                    }
                  },
                ),
                Builder(
                  builder: (bc) => SettingTile(
                    icon: PI.chartPieSlice,
                    title: tr('Объединить малые траты'),
                    value: merge == 0 ? tr('Отключено') : tr('Менее {p}%', {'p': merge}),
                    trailing: _info(
                      context,
                      tr('Объединить малые траты'),
                      tr('Категории, доля которых меньше выбранного процента, на диаграмме объединяются в одну — «Малые траты».'),
                    ),
                    onTap: () async {
                      final r = await showAnchoredMenu<int>(context, _anchor(bc), [
                        (0, tr('Отключено'), null),
                        for (final v in [1, 2, 3, 5, 10]) (v, tr('Менее {p}%', {'p': v}), null),
                      ]);
                      if (r != null) s.setSetting('mergeSmall', r);
                    },
                  ),
                ),
                const SectionLabel('Периоды'),
                Builder(
                  builder: (bc) => SettingTile(
                    icon: PI.calendar,
                    title: tr('Период по умолчанию'),
                    value: periodNames[s.setting<String>('defaultPeriod', 'week')],
                    trailing: _info(context, tr('Период по умолчанию'), tr('Период, который открывается на главном экране.')),
                    onTap: () async {
                      final r = await showAnchoredMenu<String>(context, _anchor(bc), [
                        for (final e in periodNames.entries) (e.key, e.value, null),
                      ]);
                      if (r != null) s.setSetting('defaultPeriod', r);
                    },
                  ),
                ),
                SettingTile(
                  icon: PI.calendarCheck,
                  title: tr('Свой месяц'),
                  value: monthStart == 1 ? tr('По умолчанию') : tr('С {d} числа', {'d': monthStart}),
                  trailing: _info(
                    context,
                    tr('Свой месяц'),
                    tr('Если зарплата приходит, например, 10 числа — месяц на главном экране будет считаться с 10 по 9 число.'),
                  ),
                  onTap: () async {
                    final r = await showRadioPicker<int>(context, tr('Свой месяц'), [
                      (1, tr('По умолчанию')),
                      for (var d = 2; d <= 28; d++) (d, tr('С {d} числа', {'d': d})),
                    ], monthStart);
                    if (r != null) s.setSetting('monthStart', r);
                  },
                ),
                const SectionLabel('Добавление операции '),
                SettingTile(
                  icon: PI.moneyWavy,
                  title: tr('Счет по умолчанию'),
                  value: defAcc?.name ?? tr('Не выбран'),
                  trailing: _info(context, tr('Счет по умолчанию'), tr('Этот счет будет подставляться при добавлении новой операции.')),
                  onTap: () async {
                    final r = await showRadioPicker<String>(context, tr('Выберите счет'), [
                      ('', tr('Не выбран')),
                      for (final a in s.accounts) (a.id, a.name),
                    ], defAcc?.id ?? '');
                    if (r != null) s.setSetting('defaultAccount', r.isEmpty ? null : r);
                  },
                ),
                SettingTile(
                  icon: PI.listChecks,
                  title: tr('Дополнительные поля'),
                  value: fieldsLabel,
                  trailing: _info(
                    context,
                    tr('Дополнительные поля'),
                    tr('При добавлении расходов и доходов будут отображаться только отмеченные блоки дополнительной информации.'),
                  ),
                  onTap: () => _fieldsDialog(context, s),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fieldsDialog(BuildContext context, AppState s) async {
    final sel = {
      for (final f in ['tags', 'comment', 'photo']) f: s.fieldOn(f),
    };
    final names = {'tags': tr('Теги'), 'comment': tr('Комментарий'), 'photo': tr('Фото')};
    final ok = await showAppDialog<bool>(
      context,
      (c) => StatefulBuilder(
        builder: (c, set) {
          final p = c.pal;
          final all = sel.values.every((v) => v);
          Widget row(bool on, String t, VoidCallback tap, {double indent = 0}) => InkWell(
            onTap: tap,
            child: Padding(
              padding: EdgeInsets.fromLTRB(indent, 7, 0, 7),
              child: Row(
                children: [
                  AppCheck(on: on, size: 26),
                  const SizedBox(width: 22),
                  Text(t, style: TextStyle(color: p.text, fontSize: 19)),
                ],
              ),
            ),
          );
          return AppDialog(
            title: tr('Дополнительные поля'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: p.infoBox, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(PI.info, color: p.text, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr('При добавлении расходов и доходов будут отображаться только отмеченные блоки дополнительной информации.'),
                          style: TextStyle(color: p.text, fontSize: 15.5, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                row(all, tr('Все'), () => set(() => sel.updateAll((_, _) => !all))),
                for (final f in sel.keys) row(sel[f]!, names[f]!, () => set(() => sel[f] = !sel[f]!), indent: 30),
                const SizedBox(height: 40),
              ],
            ),
            actions: [
              DialogButton(tr('ОТМЕНА'), onTap: () => Navigator.pop(c)),
              DialogButton(tr('ВЫБРАТЬ'), onTap: () => Navigator.pop(c, true)),
            ],
          );
        },
      ),
    );
    if (ok == true) {
      for (final e in sel.entries) {
        await s.setSetting('field_${e.key}', e.value);
      }
    }
  }
}

// ---------------------------------------------------------------------
//  Внешний вид
// ---------------------------------------------------------------------
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  static const _icon = MethodChannel('finansy/icon');

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final prefs = context.watch<LocalPrefs>();
    final themes = {'default': tr('По умолчанию'), 'light': tr('Светлая тема'), 'dark': tr('Темная тема')};
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(back: true, title: tr('Внешний вид')),
          const SizedBox(height: 18),
          Builder(
            builder: (bc) => SettingTile(
              icon: PI.globe,
              title: tr('Выбор языка'),
              value: prefs.lang == 'en' ? 'English' : 'Русский',
              onTap: () async {
                final r = await showAnchoredMenu<String>(context, _anchor(bc), [('ru', 'Русский', null), ('en', 'English', null)]);
                if (r != null) prefs.lang = r;
              },
            ),
          ),
          Builder(
            builder: (bc) => SettingTile(
              icon: PI.sunHorizon,
              title: tr('Выбор темы'),
              value: themes[prefs.theme],
              onTap: () async {
                final r = await showAnchoredMenu<String>(context, _anchor(bc), [for (final e in themes.entries) (e.key, e.value, null)]);
                if (r != null) prefs.theme = r;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(tr('Иконка приложения'), style: TextStyle(color: p.text, fontSize: 17.5)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                for (var i = 0; i < 4; i++)
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      prefs.appIcon = i;
                      if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
                        try {
                          await _icon.invokeMethod('setIcon', {'index': i});
                        } catch (_) {}
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: prefs.appIcon == i ? p.accent : Colors.transparent, width: 1.6),
                        color: prefs.appIcon == i ? p.card : Colors.transparent,
                      ),
                      child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset(appIconAsset(i), width: 64, height: 64)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  Расширенные настройки
// ---------------------------------------------------------------------
class AdvancedScreen extends StatelessWidget {
  const AdvancedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.watch<AppState>();
    final days = {0: tr('По умолчанию'), 1: tr('Понедельник'), 7: tr('Воскресенье'), 6: tr('Суббота')};
    final seps = {'default': tr('По умолчанию'), 'point': tr('Точка'), 'comma': tr('Запятая')};
    Widget toggle(Widget icon, String title, String key, bool def) => SettingTile(
      leading: icon,
      title: title,
      vPad: 13,
      onTap: () => s.setSetting(key, !s.setting(key, def)),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: SmallSwitch(value: s.setting(key, def), onChanged: (v) => s.setSetting(key, v)),
      ),
    );
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(back: true, title: tr('Расширенные настройки')),
          const SizedBox(height: 18),
          Builder(
            builder: (bc) => SettingTile(
              icon: PI.calendarBlank,
              title: tr('Первый день недели'),
              value: days[s.setting<int>('firstDay', 0)],
              onTap: () async {
                final r = await showAnchoredMenu<int>(context, _anchor(bc), [for (final e in days.entries) (e.key, e.value, null)]);
                if (r != null) s.setSetting('firstDay', r);
              },
            ),
          ),
          Builder(
            builder: (bc) => SettingTile(
              icon: PI.percent,
              title: tr('Десятичный разделитель'),
              value: seps[s.setting<String>('decimalSep', 'default')],
              onTap: () async {
                final r = await showAnchoredMenu<String>(context, _anchor(bc), [
                  ('default', tr('По умолчанию'), L10n.lang == 'en' ? '0.1' : '0,1'),
                  ('point', tr('Точка'), '0.1'),
                  ('comma', tr('Запятая'), '0,1'),
                ]);
                if (r != null) s.setSetting('decimalSep', r);
              },
            ),
          ),
          toggle(
            FittedBox(
              child: Text(
                '0,0',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(color: p.text, fontSize: 19, fontWeight: FontWeight.w300),
              ),
            ),
            tr('Показывать копейки'),
            'showCents',
            false,
          ),
          toggle(Icon(PI.pencilSimpleLine, color: p.text, size: 28), tr('Валюта операции из счета'), 'accountCurrency', true),
          toggle(Icon(PI.arrowsInLineVertical, color: p.text, size: 28), tr('Компактный вид списка операций'), 'compact', false),
          toggle(Icon(PI.plusCircle, color: p.text, size: 30), tr('Доходы в приоритете'), 'incomeFirst', false),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  Данные
// ---------------------------------------------------------------------
class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.read<AppState>();
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(back: true, title: tr('Данные')),
          const SizedBox(height: 18),
          SettingTile(
            icon: PI.arrowsClockwise,
            title: tr('Пересчитать баланс'),
            vPad: 13,
            onTap: () async {
              try {
                await s.recalcBalances();
                if (context.mounted) await showToast(context, tr('Баланс пересчитан'));
              } catch (e) {
                if (context.mounted) showError(context, e);
              }
            },
          ),
          SettingTile(
            icon: PI.deviceMobile,
            title: tr('Резервное копирование'),
            vPad: 13,
            trailing: Icon(PI.caretRight, color: p.secondary, size: 26),
            onTap: () => Navigator.push(context, pageRoute(const BackupScreen())),
          ),
          const SizedBox(height: 8),
          Divider(color: p.divider, height: 1, thickness: 1),
          const SizedBox(height: 8),
          SettingTile(
            icon: PI.trash,
            title: tr('Удалить все данные'),
            titleColor: p.danger,
            vPad: 13,
            onTap: () async {
              if (!await confirm(context, tr('Удалить все данные? Это действие нельзя отменить.'), danger: true, yes: 'УДАЛИТЬ')) return;
              try {
                await s.deleteAllData();
                if (context.mounted) {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }
              } catch (e) {
                if (context.mounted) showError(context, e);
              }
            },
          ),
        ],
      ),
    );
  }
}

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  Future<void> _create() async {
    if (!await confirm(context, tr('Создать резервную копию?'))) return;
    setState(() => _busy = true);
    try {
      final data = await context.read<AppState>().exportBackup();
      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final name = '${df('yyyy_MM_dd_HH_mm_ss').format(now)}_${now.microsecond.toString().padLeft(6, '0')}.fbackup';
      final file = File('${dir.path}/$name');
      await file.writeAsString(const JsonEncoder.withIndent(' ').convert(data));
      if (!mounted) return;
      setState(() => _busy = false);
      await showAppDialog(
        context,
        (c) => AppDialog(
          padding: const EdgeInsets.fromLTRB(24, 10, 10, 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(c),
                  icon: Icon(Icons.close, color: c.pal.text, size: 28),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF639F86), width: 4),
                  ),
                  child: const Icon(Icons.check, color: Color(0xFF639F86), size: 44),
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text(
                  tr('Резервная копия создана успешно! Сохраните файл в надежном месте.'),
                  style: TextStyle(color: c.pal.text, fontSize: 17.5, height: 1.3),
                ),
              ),
              const SizedBox(height: 18),
              DialogButton(
                tr('СОХРАНИТЬ'),
                onTap: () async {
                  await SharePlus.instance.share(
                    ShareParams(
                      files: [XFile(file.path, mimeType: 'application/json')],
                      fileNameOverrides: [name],
                    ),
                  );
                  if (c.mounted) Navigator.pop(c);
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty || files.first.path == null) return;
    try {
      final data = jsonDecode(await File(files.first.path!).readAsString()) as Map<String, dynamic>;
      if (data['format'] != 'finansy-backup') throw Exception(tr('Неверный формат файла'));
      if (!mounted) return;
      if (!await confirm(context, tr('Восстановить данные из файла? Текущие данные будут заменены.'))) return;
      setState(() => _busy = true);
      await context.read<AppState>().restoreBackup(data);
      if (mounted) await showToast(context, tr('Данные восстановлены'));
    } catch (e) {
      if (mounted) showError(context, e is FormatException ? tr('Неверный формат файла') : e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget row(IconData icon, String t, String sub, String info, VoidCallback onTap) => InkWell(
      onTap: _busy ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: p.text, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t, style: TextStyle(color: p.text, fontSize: 17.5)),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(color: p.hint, fontSize: 15, height: 1.2)),
                ],
              ),
            ),
            _info(context, t, info),
          ],
        ),
      ),
    );
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(back: true, title: tr('Резервное копирование')),
          const SizedBox(height: 18),
          row(
            PI.uploadSimple,
            tr('Создать резервную копию'),
            tr('Сохранение полной копии ваших данных в файл. Храните полученный файл в надежном месте'),
            tr(
              'Файл содержит все счета, категории, операции, переводы, регулярные платежи и напоминания. Его можно сохранить в «Файлы», отправить себе в мессенджер или на почту.',
            ),
            _create,
          ),
          row(
            PI.downloadSimple,
            tr('Восстановить резервную копию'),
            tr('Загрузка ранее созданной резервной копии данных приложения. Текущие данные будут заменены'),
            tr('Выберите файл .fbackup, созданный ранее. Все текущие данные аккаунта будут заменены данными из файла.'),
            _restore,
          ),
          if (_busy)
            Padding(
              padding: const EdgeInsets.all(30),
              child: CircularProgressIndicator(color: p.accent),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  Дополнительно
// ---------------------------------------------------------------------
class AdditionalScreen extends StatelessWidget {
  const AdditionalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(back: true, title: tr('Дополнительные настройки')),
          const SizedBox(height: 18),
          SettingTile(
            icon: PI.clipboardText,
            title: tr('Политика конфиденциальности'),
            vPad: 13,
            onTap: () => Navigator.push(context, pageRoute(LegalScreen(title: tr('Политика конфиденциальности'), text: privacyText()))),
          ),
          SettingTile(
            icon: PI.clipboardText,
            title: tr('Пользовательское соглашение (EULA)'),
            vPad: 13,
            onTap: () => Navigator.push(context, pageRoute(LegalScreen(title: tr('Пользовательское соглашение (EULA)'), text: eulaText()))),
          ),
        ],
      ),
    );
  }
}
