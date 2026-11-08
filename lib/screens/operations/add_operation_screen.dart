import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../l10n.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../util/currencies.dart';
import '../../util/format.dart';
import '../../util/icons.dart';
import '../../widgets/calculator.dart';
import '../../widgets/common.dart';
import '../../widgets/pickers.dart';
import '../../widgets/local_image.dart';
import '../../widgets/tags.dart';

class AddOperationScreen extends StatefulWidget {
  final OpType type;
  final String? accountId;
  final Operation? edit;
  const AddOperationScreen({super.key, this.type = OpType.expense, this.accountId, this.edit});

  @override
  State<AddOperationScreen> createState() => _AddOperationScreenState();
}

class _AddOperationScreenState extends State<AddOperationScreen> with SingleTickerProviderStateMixin {
  late final AppState s = context.read<AppState>();
  late final Operation? e = widget.edit;
  late final TabController _tabs = TabController(length: 2, vsync: this, initialIndex: (e?.type ?? widget.type) == OpType.income ? 1 : 0);
  late final _amount = TextEditingController(text: e == null ? '' : fmtNum(e!.amount).replaceAll(' ', ' '));
  late final _comment = TextEditingController(text: e?.comment ?? '');
  final _amountFocus = FocusNode();
  late String? _accountId = e?.accountId ?? widget.accountId ?? s.setting<String?>('defaultAccount', null) ?? s.accounts.firstOrNull?.id;
  late final Map<OpType, String?> _cat = {
    OpType.expense: e?.type == OpType.expense ? e?.categoryId : null,
    OpType.income: e?.type == OpType.income ? e?.categoryId : null,
  };
  late DateTime _date = e?.date ?? DateTime.now();
  late List<String> _tags = [...?e?.tags];
  late final List<String> _photos = [...?e?.photos];
  final Set<int> _uploading = {};
  bool _saving = false;
  final Map<OpType, String?> _extraCat = {};

  @override
  void initState() {
    super.initState();
    if (s.accountById(_accountId) == null) _accountId = s.accounts.firstOrNull?.id;
    _tabs.addListener(() => setState(() {}));
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _amount.dispose();
    _comment.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  OpType get _type => _tabs.index == 1 ? OpType.income : OpType.expense;
  double? get _value => parseAmount(_amount.text);
  bool get _valid => (_value ?? 0) > 0 && _cat[_type] != null && _accountId != null && _uploading.isEmpty;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final d = _date;
      final now = DateTime.now();
      final when = e != null || !sameDay(d, now) ? d : now;
      await s.saveOperation(
        id: e?.id,
        type: _type,
        amount: _value!,
        accountId: _accountId!,
        categoryId: _cat[_type],
        date: when,
        tags: _tags,
        comment: _comment.text.trim(),
        photos: _photos,
      );
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context, true);
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirm(context, tr('Удалить операцию?'), danger: true, yes: 'УДАЛИТЬ')) return;
    try {
      await s.deleteOperation(e!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (err) {
      if (mounted) showError(context, err);
    }
  }

  Future<void> _pickAccount() async {
    final r = await showAccountPicker(context, selected: _accountId, withTotal: false);
    if (r != null && r.isNotEmpty) setState(() => _accountId = r);
  }

  Future<void> _more() async {
    final c = await showCategoryPicker(context, _type);
    if (c != null) {
      setState(() {
        _cat[_type] = c.id;
        _extraCat[_type] = c.id;
      });
    }
  }

  Future<void> _calc() async {
    final v = await showCalculator(context, _value ?? 0);
    if (v != null) _amount.text = v == 0 ? '' : fmtNum(v).replaceAll(' ', ' ');
  }

  Future<void> _addPhoto(int slot) async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.pal.dialog,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(PI.camera, color: c.pal.text),
              title: Text(tr('Сделать фото')),
              onTap: () => Navigator.pop(c, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(PI.image, color: c.pal.text),
              title: Text(tr('Выбрать из галереи')),
              onTap: () => Navigator.pop(c, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (src == null) return;
    final x = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 80);
    if (x == null) return;
    setState(() => _uploading.add(slot));
    try {
      final url = await s.uploadFile('photos', await x.readAsBytes(), 'jpg');
      setState(() => _photos.add(url));
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _uploading.remove(slot));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final st = context.watch<AppState>();
    final acc = st.accountById(_accountId);
    final cats = st.categoriesOf(_type);
    final selId = _cat[_type];
    final bottom = MediaQuery.paddingOf(context).bottom;
    final kb = MediaQuery.viewInsetsOf(context).bottom;

    // В сетке: первые 7 категорий (+ выбранная через «Еще», если её там нет) и кнопка «Еще»
    var shown = cats.take(7).toList();
    final extra = _extraCat[_type] ?? selId;
    if (extra != null && !shown.any((c) => c.id == extra)) {
      final c = st.categoryById(extra);
      if (c != null) shown = [...cats.take(6), c];
    }

    return Scaffold(
      backgroundColor: p.bg,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Column(
            children: [
              AppHeader(
                back: true,
                title: e == null ? tr('Добавление операции') : tr('Редактирование'),
                actions: [if (e != null) HeaderIcon(icon: PI.trash, onTap: _delete)],
                bottom: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: HeaderTabs(controller: _tabs, labels: [tr('РАСХОДЫ'), tr('ДОХОДЫ')]),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(bottom: 120 + bottom + kb),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 18),
                    _amountRow(p, acc),
                    const SizedBox(height: 23),
                    LabeledValue(label: tr('Счет'), value: acc?.name ?? tr('Не задан'), onTap: _pickAccount),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 29),
                      child: Text(tr('Категории'), style: TextStyle(color: p.secondary, fontSize: 15, letterSpacing: 0.2)),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: GridView.count(
                        key: ValueKey(_type),
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        mainAxisSpacing: 0,
                        childAspectRatio: 1.07,
                        children: [
                          for (final c in shown)
                            CategoryCell(
                              circle: IconCircle(icon: c.icon, color: c.col),
                              label: c.name,
                              selected: c.id == selId,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _cat[_type] = c.id);
                              },
                            ),
                          CategoryCell(
                            circle: SizedBox(
                              width: 64,
                              height: 64,
                              child: Center(
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: const BoxDecoration(color: Color(0xFF758B84), shape: BoxShape.circle),
                                  child: const Icon(Icons.add, color: Color(0xFFFAFAF5), size: 36),
                                ),
                              ),
                            ),
                            label: tr('Еще'),
                            onTap: _more,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 17),
                    _dates(p),
                    if (st.fieldOn('tags')) ...[
                      const SizedBox(height: 12),
                      TagsBlock(tags: _tags, onChanged: (t) => setState(() => _tags = t)),
                    ],
                    if (st.fieldOn('comment')) ...[
                      const SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('Комментарий'), style: TextStyle(color: p.secondary, fontSize: 15, letterSpacing: 0.2)),
                            TextField(
                              controller: _comment,
                              textCapitalization: TextCapitalization.sentences,
                              maxLines: null,
                              style: TextStyle(color: p.text, fontSize: 17.5),
                              decoration: InputDecoration(
                                hintText: tr('Комментарий'),
                                hintStyle: TextStyle(color: p.hint, fontSize: 17.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (st.fieldOn('photo')) ...[
                      const SizedBox(height: 21),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(tr('Фото'), style: TextStyle(color: p.secondary, fontSize: 15, letterSpacing: 0.2)),
                      ),
                      const SizedBox(height: 14),
                      _photosRow(p),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: (kb > 0 ? kb + 12 : bottom + 13),
            child: Center(
              child: YellowButton(text: e == null ? tr('Добавить') : tr('Сохранить'), loading: _saving, onTap: _valid ? _save : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(Pal p, Account? acc) {
    final cur = acc?.currency ?? s.baseCurrency;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 56),
        SizedBox(
          width: 130,
          child: TextField(
            controller: _amount,
            focusNode: _amountFocus,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]'))],
            style: TextStyle(color: p.text, fontSize: 28),
            cursorHeight: 30,
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: p.secondary, fontSize: 28),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.line, width: 2)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.accent, width: 2)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(cur, style: TextStyle(color: p.accent, fontSize: 28)),
        IconButton(
          onPressed: _calc,
          icon: Icon(PI.calculator, color: p.text.withValues(alpha: 0.8), size: 34),
        ),
      ],
    );
  }

  Widget _dates(Pal p) {
    final today = dayStart(DateTime.now());
    final days = [today, today.subtract(const Duration(days: 1)), today.subtract(const Duration(days: 2))];
    final names = [tr('сегодня'), tr('вчера'), tr('позавчера')];
    final custom = !days.any((d) => sameDay(d, _date));
    Widget chip(DateTime d, String sub, bool sel, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(color: sel ? p.accent : Colors.transparent, borderRadius: BorderRadius.circular(4)),
        child: Column(
          children: [
            Text(df('dd.MM').format(d), style: TextStyle(color: sel ? const Color(0xFFF4F4E8) : p.text, fontSize: 15.5, height: 1.15)),
            Text(sub, style: TextStyle(color: sel ? const Color(0xFFF4F4E8) : p.text, fontSize: 15.5, height: 1.15)),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) chip(days[i], names[i], !custom && sameDay(days[i], _date), () => setState(() => _date = days[i])),
          if (custom) chip(_date, df('E').format(_date).toLowerCase(), true, () {}),
          const Spacer(),
          IconButton(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                locale: Locale(L10n.locale),
              );
              if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
            },
            icon: Icon(PI.calendarDots, color: p.accent, size: 34),
          ),
        ],
      ),
    );
  }

  Widget _photosRow(Pal p) {
    final slots = <Widget>[];
    for (var i = 0; i < 3; i++) {
      final url = i < _photos.length ? _photos[i] : null;
      slots.add(
        SizedBox(
          width: i < 2 ? 112 : 96,
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 16 : 0),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: url != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => Dialog.fullscreen(
                                backgroundColor: Colors.black,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: InteractiveViewer(child: appImage(url, fit: BoxFit.contain)),
                                ),
                              ),
                            ),
                            child: appImage(url),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _photos.remove(url)),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Material(
                        color: const Color(0xFF758B84),
                        child: InkWell(
                          onTap: _uploading.isEmpty && i == _photos.length ? () => _addPhoto(i) : null,
                          child: Center(
                            child: _uploading.contains(i)
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4)
                                : const Icon(PI.plus, color: Color(0xFFFAFAF5), size: 44),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(children: slots),
    );
  }
}

String accountCurrencyLabel(String code) => currencyByCode(code).code;
