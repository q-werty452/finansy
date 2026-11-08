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
import '../onboarding/currency_screen.dart';

class AccountEditScreen extends StatefulWidget {
  final Account? account;
  const AccountEditScreen({super.key, this.account});

  @override
  State<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen> {
  late final AppState s = context.read<AppState>();
  late final Account? a = widget.account;
  late final _name = TextEditingController(text: a?.name ?? '');
  late final _balance = TextEditingController(text: a == null ? '' : fmtNum(a!.balance).replaceAll(' ', ' '));
  late String _icon = a?.icon ?? 'creditCard';
  late String _color = a?.color ?? '#4895DD';
  late String _currency = a?.currency ?? s.baseCurrency;
  late bool _inTotal = a?.inTotal ?? true;
  bool _saving = false;
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await s.saveAccount(
        id: a?.id,
        name: _name.text.trim(),
        icon: _icon,
        color: _color,
        currency: _currency,
        balance: parseAmount(_balance.text) ?? 0,
        inTotal: _inTotal,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirm(context, tr('Удалить счет?'), subtitle: tr('Все операции этого счета будут удалены'), danger: true, yes: 'УДАЛИТЬ'))
      return;
    try {
      await s.removeAccount(a!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final err = _tried && _name.text.trim().isEmpty;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            back: true,
            title: a == null ? tr('Новый счет') : tr('Редактировать счет'),
            actions: [if (a != null && s.accounts.length > 1) HeaderIcon(icon: PI.trash, onTap: _delete)],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(0, 20, 0, MediaQuery.paddingOf(context).bottom + 30),
              children: [
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    child: IconCircle(icon: _icon, color: hexColor(_color), size: 80),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('Название счета'), style: TextStyle(color: p.secondary, fontSize: 15)),
                      TextField(
                        controller: _name,
                        autofocus: a == null,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(color: p.text, fontSize: 18),
                        decoration: InputDecoration(
                          hintText: tr('Название'),
                          errorText: err ? tr('Обязательное поле для заполнения') : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(a == null ? tr('Текущий баланс') : tr('Текущий баланс'), style: TextStyle(color: p.secondary, fontSize: 15)),
                      Row(
                        children: [
                          SizedBox(
                            width: 170,
                            child: TextField(
                              controller: _balance,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s-]'))],
                              style: TextStyle(color: p.text, fontSize: 20),
                              decoration: const InputDecoration(hintText: '0'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: () async {
                              final c = await Navigator.push<String>(
                                context,
                                pageRoute(CurrencyScreen(selected: _currency, asPicker: true)),
                              );
                              if (c != null) setState(() => _currency = c);
                            },
                            child: Text(
                              _currency,
                              style: TextStyle(color: p.accent, fontSize: 20, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SectionLabel('Иконка'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Wrap(
                    children: [
                      for (final i in kAccountIconNames)
                        GestureDetector(
                          onTap: () => setState(() => _icon = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.all(5),
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _icon == i ? p.text : Colors.transparent, width: 2),
                            ),
                            child: IconCircle(icon: i, color: _icon == i ? hexColor(_color) : p.card, size: 46, iconSize: 26),
                          ),
                        ),
                    ],
                  ),
                ),
                const SectionLabel('Цвет'),
                ColorRow(selected: _color, onChanged: (c) => setState(() => _color = c)),
                const SizedBox(height: 12),
                SettingTile(
                  icon: PI.sigma,
                  title: tr('Учитывать в итоговом балансе'),
                  trailing: SmallSwitch(value: _inTotal, onChanged: (v) => setState(() => _inTotal = v)),
                  onTap: () => setState(() => _inTotal = !_inTotal),
                ),
                const SizedBox(height: 30),
                Center(
                  child: YellowButton(text: tr('Сохранить'), loading: _saving, onTap: _save),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ColorRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const ColorRow({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        children: [
          for (final c in kPalette)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(c);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(5),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: hexColor(c),
                  shape: BoxShape.circle,
                  border: Border.all(color: selected == c ? p.text : Colors.transparent, width: 3),
                ),
                child: selected == c ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
              ),
            ),
        ],
      ),
    );
  }
}
