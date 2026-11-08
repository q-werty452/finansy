import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../l10n.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../util/icons.dart';
import '../../widgets/common.dart';
import '../accounts/account_edit_screen.dart' show ColorRow;

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  OpType get _type => _tabs.index == 1 ? OpType.income : OpType.expense;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            title: tr('Категории'),
            centerTitle: false,
            actions: [
              HeaderIcon(
                icon: PI.selectionForeground,
                size: 30,
                onTap: () => Navigator.push(context, pageRoute(ReorderCategoriesScreen(type: _type))),
              ),
            ],
            bottom: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: HeaderTabs(controller: _tabs, labels: [tr('РАСХОДЫ'), tr('ДОХОДЫ')]),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _Grid(type: OpType.expense),
                _Grid(type: OpType.income),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final OpType type;
  const _Grid({required this.type});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cats = s.categoriesOf(type);
    return GridView.count(
      crossAxisCount: 4,
      padding: EdgeInsets.fromLTRB(6, 12, 6, MediaQuery.paddingOf(context).bottom + 20),
      childAspectRatio: 1.07,
      mainAxisSpacing: 0,
      children: [
        for (var i = 0; i < cats.length; i++)
          FadeSlideIn(
            index: i,
            child: CategoryCell(
              circle: IconCircle(icon: cats[i].icon, color: cats[i].col),
              label: cats[i].name,
              onTap: () => Navigator.push(context, pageRoute(CategoryEditScreen(type: type, category: cats[i]))),
            ),
          ),
        FadeSlideIn(
          index: cats.length,
          child: CategoryCell(
            circle: SizedBox(
              width: 64,
              height: 64,
              child: Center(
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: context.pal.yellow, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Color(0xFFFAFAF5), size: 36),
                ),
              ),
            ),
            label: tr('Создать'),
            onTap: () => Navigator.push(context, pageRoute(CategoryEditScreen(type: type))),
          ),
        ),
      ],
    );
  }
}

class CategoryEditScreen extends StatefulWidget {
  final OpType type;
  final Category? category;
  const CategoryEditScreen({super.key, required this.type, this.category});

  @override
  State<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends State<CategoryEditScreen> {
  late final AppState s = context.read<AppState>();
  late final Category? c = widget.category;
  late final _name = TextEditingController(text: c?.name ?? '');
  late String _icon = c?.icon ?? 'shoppingCart';
  late String _color = c?.color ?? '#46BF8D';
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
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await s.saveCategory(id: c?.id, type: widget.type, name: _name.text.trim(), icon: _icon, color: _color);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirm(context, tr('Удалить категорию?'), subtitle: tr('Операции останутся без категории'), danger: true, yes: 'УДАЛИТЬ'))
      return;
    try {
      await s.deleteCategory(c!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
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
            title: c == null ? tr('Новая категория') : tr('Редактировать категорию'),
            actions: [if (c != null) HeaderIcon(icon: PI.trash, onTap: _delete)],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(0, 20, 0, MediaQuery.paddingOf(context).bottom + 30),
              children: [
                Center(
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: hexColor(_color)),
                    duration: const Duration(milliseconds: 250),
                    builder: (_, col, _) => IconCircle(icon: _icon, color: col!, size: 84),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    widget.type == OpType.expense ? tr('Расходы') : tr('Доходы'),
                    style: TextStyle(color: p.secondary, fontSize: 14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _name,
                    autofocus: c == null,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: p.text, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: tr('Название'),
                      errorText: _tried && _name.text.trim().isEmpty ? tr('Обязательное поле для заполнения') : null,
                    ),
                  ),
                ),
                const SectionLabel('Цвет'),
                ColorRow(selected: _color, onChanged: (v) => setState(() => _color = v)),
                const SectionLabel('Иконка'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Wrap(
                    children: [
                      for (final i in kCategoryIconNames)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _icon = i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.all(5),
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(color: _icon == i ? hexColor(_color) : p.card, shape: BoxShape.circle),
                            child: Center(
                              child: CatGlyph(name: i, color: _icon == i ? Colors.white : p.text, size: kCatArt.containsKey(i) ? 36 : 30),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: YellowButton(text: c == null ? tr('Создать') : tr('Сохранить'), loading: _saving, onTap: _save),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReorderCategoriesScreen extends StatefulWidget {
  final OpType type;
  const ReorderCategoriesScreen({super.key, required this.type});

  @override
  State<ReorderCategoriesScreen> createState() => _ReorderCategoriesScreenState();
}

class _ReorderCategoriesScreenState extends State<ReorderCategoriesScreen> {
  late final AppState s = context.read<AppState>();
  late final List<Category> _list = s.categoriesOf(widget.type);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(back: true, title: tr('Перемещение категорий')),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(tr('Перетащите категории, чтобы изменить порядок'), style: TextStyle(color: p.secondary, fontSize: 15)),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 20),
              itemCount: _list.length,
              proxyDecorator: (child, _, _) => Material(color: p.card, elevation: 6, child: child),
              onReorderItem: (a, b) {
                HapticFeedback.mediumImpact();
                setState(() {
                  _list.insert(b, _list.removeAt(a));
                });
                s.reorderCategories(widget.type, _list).catchError((e) {
                  if (context.mounted) showError(context, e);
                });
              },
              itemBuilder: (_, i) => ListTile(
                key: ValueKey(_list[i].id),
                leading: IconCircle(icon: _list[i].icon, color: _list[i].col, size: 40),
                title: Text(_list[i].name, style: TextStyle(color: p.text, fontSize: 17)),
                trailing: ReorderableDragStartListener(
                  index: i,
                  child: Icon(PI.dotsSixVertical, color: p.secondary, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
