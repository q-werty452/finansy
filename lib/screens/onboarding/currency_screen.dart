import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../../theme.dart';
import '../../util/currencies.dart';
import '../../util/icons.dart';
import '../../widgets/common.dart';

class CurrencyScreen extends StatefulWidget {
  final String selected;
  final bool asPicker;
  final ValueChanged<String>? onNext;
  const CurrencyScreen({super.key, this.selected = 'RUB', this.asPicker = false, this.onNext});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  late String _sel = widget.selected;
  final _q = TextEditingController();
  late final List<Currency> _all = [...kCurrencies]..sort((a, b) => a.name.compareTo(b.name));
  static const _rowH = 56.0;
  late final ScrollController _sc;

  @override
  void initState() {
    super.initState();
    final i = _all.indexWhere((c) => c.code == _sel);
    _sc = ScrollController(initialScrollOffset: i <= 3 ? 0 : (i - 3) * _rowH);
  }

  @override
  void dispose() {
    _q.dispose();
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final q = _q.text.trim().toLowerCase();
    final list = q.isEmpty
        ? _all
        : _all
              .where((c) => c.name.toLowerCase().contains(q) || c.code.toLowerCase().contains(q) || c.en.toLowerCase().contains(q))
              .toList();
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion(
      value: kLightStatus,
      child: Scaffold(
        backgroundColor: p.bg,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: top + 30),
                Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: widget.asPicker
                          ? IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(PI.caretLeft, color: p.text, size: 28),
                            )
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        tr('Выберите валюту\nпо умолчанию'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.text, fontSize: 24, height: 1.55, letterSpacing: 0.2),
                      ),
                    ),
                    const SizedBox(width: 56),
                  ],
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _q,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: p.text, fontSize: 17),
                    decoration: InputDecoration(
                      hintText: tr('Поиск'),
                      suffixIcon: Icon(PI.magnifyingGlass, color: p.text, size: 26),
                      suffixIconConstraints: const BoxConstraints(minHeight: 30, minWidth: 30),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.builder(
                    controller: _sc,
                    itemExtent: _rowH,
                    padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 110),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final c = list[i];
                      final on = c.code == _sel;
                      return InkWell(
                        onTap: () => setState(() => _sel = c.code),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          color: on ? p.selectedRow : Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(c.name, style: TextStyle(color: p.text, fontSize: 17.5, letterSpacing: 0.2)),
                              ),
                              Text(c.code, style: TextStyle(color: p.text, fontSize: 17.5, letterSpacing: 0.2)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 44,
              child: Center(
                child: YellowButton(
                  text: widget.asPicker ? tr('Готово') : tr('Далее'),
                  onTap: () => widget.asPicker ? Navigator.pop(context, _sel) : widget.onNext?.call(_sel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
