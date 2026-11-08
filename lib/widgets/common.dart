import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../theme.dart';
import '../util/icons.dart';
import 'money_bag.dart';

const kHeaderRadius = 30.0;

/// Ключ главного Scaffold с боковым меню (HomeShell). Разделы имеют свои Scaffold
/// без меню, поэтому Scaffold.of(context) из шапки раздела меню не находит.
final mainScaffoldKey = GlobalKey<ScaffoldState>();

void openMainMenu(BuildContext context) {
  final st = mainScaffoldKey.currentState;
  if (st != null) {
    st.openDrawer();
  } else {
    Scaffold.maybeOf(context)?.openDrawer();
  }
}

SystemUiOverlayStyle get kLightStatus => const SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.transparent,
);

/// Зелёная шапка со скруглённым низом
class AppHeader extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final bool centerTitle;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? bottom;
  final bool back;

  const AppHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.centerTitle = true,
    this.leading,
    this.actions = const [],
    this.bottom,
    this.back = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final top = MediaQuery.paddingOf(context).top;
    final lead =
        leading ??
        (back
            ? HeaderIcon(icon: PI.caretLeft, onTap: () => Navigator.maybePop(context), size: 30)
            : HeaderIcon(icon: PI.list, onTap: () => openMainMenu(context), size: 30));
    final t =
        titleWidget ??
        Text(
          title ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: p.onHeader, fontSize: 17.6, fontWeight: FontWeight.w500, letterSpacing: 0.15),
        );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kLightStatus,
      child: Container(
        decoration: BoxDecoration(
          color: p.header,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(kHeaderRadius)),
        ),
        padding: EdgeInsets.only(top: top + 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 56,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (centerTitle)
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 70), child: t)
                  else
                    Positioned(
                      left: 72,
                      right: 60 + actions.length * 30.0,
                      child: Align(alignment: Alignment.centerLeft, child: t),
                    ),
                  Positioned(left: 4, child: lead),
                  Positioned(
                    right: 4,
                    child: Row(mainAxisSize: MainAxisSize.min, children: actions),
                  ),
                ],
              ),
            ),
            if (bottom != null) bottom! else const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool material;
  final Color? color;
  const HeaderIcon({super.key, required this.icon, this.onTap, this.size = 28, this.material = false, this.color});

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    splashRadius: 24,
    padding: const EdgeInsets.all(10),
    icon: Icon(icon, size: size, color: color ?? context.pal.onHeader, weight: material ? 300 : null),
  );
}

/// Вкладки РАСХОДЫ / ДОХОДЫ в шапке
class HeaderTabs extends StatelessWidget {
  final TabController controller;
  final List<String> labels;
  final double fontSize;
  const HeaderTabs({super.key, required this.controller, required this.labels, this.fontSize = 18.6});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      height: 50,
      child: TabBar(
        controller: controller,
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 2.6, color: p.text),
          insets: const EdgeInsets.symmetric(horizontal: -10),
        ),
        labelColor: p.text,
        unselectedLabelColor: p.headerInactive,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        labelStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, letterSpacing: 0.3, fontFamily: 'Roboto'),
        unselectedLabelStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, letterSpacing: 0.3, fontFamily: 'Roboto'),
        splashFactory: NoSplash.splashFactory,
        tabs: [for (final l in labels) Tab(text: l, height: 46)],
      ),
    );
  }
}

/// Вкладки периода внутри карточки (День, Неделя…)
class CardTabs extends StatelessWidget {
  final TabController controller;
  final List<String> labels;
  final ValueChanged<int>? onTap;
  const CardTabs({super.key, required this.controller, required this.labels, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      height: 50,
      child: TabBar(
        controller: controller,
        onTap: onTap,
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 2.6, color: p.accent),
          insets: const EdgeInsets.symmetric(horizontal: -3),
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6.5),
        labelColor: p.accent,
        unselectedLabelColor: p.tabInactive,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        labelStyle: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
        unselectedLabelStyle: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w400, fontFamily: 'Roboto'),
        splashFactory: NoSplash.splashFactory,
        tabs: [for (final l in labels) Tab(text: l, height: 44)],
      ),
    );
  }
}

/// Жёлтая кнопка «Добавить», «Далее», «Создать»
class YellowButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final bool loading;
  final double width;
  const YellowButton({super.key, required this.text, this.onTap, this.loading = false, this.width = 230});

  @override
  State<YellowButton> createState() => _YellowButtonState();
}

class _YellowButtonState extends State<YellowButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final enabled = widget.onTap != null && !widget.loading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled || widget.loading ? 1 : 0.5,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: widget.width,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.yellow,
              borderRadius: BorderRadius.circular(24),
              boxShadow: enabled ? [BoxShadow(color: p.yellow.withValues(alpha: 0.28), blurRadius: 18, spreadRadius: 1)] : null,
            ),
            child: widget.loading
                ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: p.onYellow))
                : Text(
                    widget.text,
                    style: TextStyle(color: p.onYellow, fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: 0.2),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Круглая жёлтая кнопка «+»
class YellowFab extends StatefulWidget {
  final VoidCallback onTap;
  final double size;
  const YellowFab({super.key, required this.onTap, this.size = 56});

  @override
  State<YellowFab> createState() => _YellowFabState();
}

class _YellowFabState extends State<YellowFab> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.9 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: p.yellow,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: p.yellow.withValues(alpha: 0.3), blurRadius: 16, spreadRadius: 1)],
          ),
          child: const Icon(Icons.add, size: 34, color: Color(0xFF16160F)),
        ),
      ),
    );
  }
}

/// Цветной круг с белой иконкой
class IconCircle extends StatelessWidget {
  final String icon;
  final Color color;
  final double size;
  final double? iconSize;
  const IconCircle({super.key, required this.icon, required this.color, this.size = 64, this.iconSize});

  @override
  Widget build(BuildContext context) {
    final art = kCatArt.containsKey(icon);
    final grey = color.toARGB32() == 0xFF888888;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: grey ? Border.all(color: const Color(0xFFBDBDBA), width: size / 40) : null,
      ),
      alignment: Alignment.center,
      child: icon == 'moneyBag'
          ? MoneyBagIcon(size: iconSize ?? size * 0.6, color: const Color(0xFFFAFAF5))
          : CatGlyph(
              name: icon,
              size: iconSize == null ? size * (art ? 0.84 : 0.64) : iconSize! * (art ? 1.18 : 1),
              color: const Color(0xFFFAFAF5),
            ),
    );
  }
}

/// Нарисованные вручную иконки стандартных категорий (толстые линии, блики, разрывы — как в оригинале)
const kCatArt = {
  'heartbeat': 'c_health',
  'wallet': 'c_wallet',
  'house': 'c_house',
  'forkKnife': 'c_cafe',
  'graduationCap': 'c_edu',
  'gift': 'c_gift',
  'basket': 'c_food',
  'users': 'c_family',
  'barbell': 'c_sport',
  'bus': 'c_bus',
  'question': 'c_other',
  'handCoins': 'c_salary',
  'bank': 'c_bank',
};

class CatGlyph extends StatelessWidget {
  final String name;
  final double size;
  final Color color;
  const CatGlyph({super.key, required this.name, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    final art = kCatArt[name];
    if (art == null) return Icon(iconFor(name), size: size, color: color);
    return Image.asset('assets/cat/$art.png', width: size, height: size, color: color, filterQuality: FilterQuality.medium);
  }
}

/// Ячейка категории в сетке
class CategoryCell extends StatefulWidget {
  final Widget circle;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  const CategoryCell({super.key, required this.circle, required this.label, this.onTap, this.onLongPress, this.selected = false});

  @override
  State<CategoryCell> createState() => _CategoryCellState();
}

class _CategoryCellState extends State<CategoryCell> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Column(
        children: [
          AnimatedScale(
            scale: _down ? 0.9 : (widget.selected ? 1.06 : 1),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            // Кольцо выделения рисуется поверх и не влияет на размеры ячейки
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                widget.circle,
                Positioned(
                  left: -5,
                  top: -5,
                  right: -5,
                  bottom: -5,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.selected ? p.text : Colors.transparent, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ShaderMask(
            shaderCallback: (r) =>
                const LinearGradient(colors: [Colors.white, Colors.white, Colors.transparent], stops: [0, 0.86, 1]).createShader(r),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                textAlign: TextAlign.center,
                widget.label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: TextStyle(color: p.text, fontSize: 15.2, letterSpacing: 0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Маленький переключатель в стиле Material 2, как в оригинале
class SmallSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const SmallSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onChanged!(!value);
            },
      child: SizedBox(
        width: 50,
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34,
              height: 15,
              decoration: BoxDecoration(
                color: value ? p.accent.withValues(alpha: 0.45) : p.switchTrackOff,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: value ? const Alignment(0.95, 0) : const Alignment(-0.95, 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  color: value ? p.accent : p.switchThumbOff,
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Строка настроек: иконка, заголовок, зелёное значение, справа — что угодно
class SettingTile extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final double vPad;
  final GestureTapDownCallback? onTapDown;
  const SettingTile({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.vPad = 9,
    this.onTapDown,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      onTapDown: onTapDown,
      splashColor: p.text.withValues(alpha: 0.06),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, vPad, 8, vPad),
        child: Row(
          children: [
            SizedBox(width: 24, child: leading ?? (icon == null ? null : Icon(icon, size: 27, color: p.text))),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: titleColor ?? p.text, fontSize: 15.8, letterSpacing: 0.15)),
                  if (value != null) ...[
                    const SizedBox(height: 2),
                    Text(value!, style: TextStyle(color: p.accent, fontSize: 15.8, letterSpacing: 0.15)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsets padding;
  const SectionLabel(this.text, {super.key, this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 2)});

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Text(tr(text), style: TextStyle(color: context.pal.secondary, fontSize: 13.8, letterSpacing: 0.2)),
  );
}

/// Подпись + зелёное значение (поля формы «Счет», «Дата»…)
class LabeledValue extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color? valueColor;
  const LabeledValue({super.key, required this.label, required this.value, this.onTap, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: p.secondary, fontSize: 13.8, letterSpacing: 0.2)),
            const SizedBox(height: 3),
            Text(value, style: TextStyle(color: valueColor ?? p.accent, fontSize: 16, letterSpacing: 0.15)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  Диалоги
// ---------------------------------------------------------------------
Future<T?> showAppDialog<T>(BuildContext context, WidgetBuilder builder, {bool dismissible = true}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: dismissible,
  barrierLabel: 'dialog',
  barrierColor: Colors.black.withValues(alpha: 0.55),
  transitionDuration: const Duration(milliseconds: 220),
  pageBuilder: (c, _, _) => builder(c),
  transitionBuilder: (c, a, _, child) {
    final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(curved), child: child),
    );
  },
);

class AppDialog extends StatelessWidget {
  final String? title;
  final Widget? content;
  final List<Widget> actions;
  final EdgeInsets padding;
  final double? width;
  const AppDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(24, 22, 24, 8),
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Material(
          color: p.dialog,
          elevation: 3,
          shadowColor: Colors.black54,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: width,
            child: Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(title!, style: TextStyle(color: p.text, fontSize: 23, letterSpacing: 0.2)),
                    const SizedBox(height: 14),
                  ],
                  if (content != null) Flexible(child: content!),
                  if (actions.isNotEmpty) ...[const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.end, children: actions)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DialogButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color? color;
  const DialogButton(this.text, {super.key, this.onTap, this.color});

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: color ?? context.pal.accent,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4, fontFamily: 'Roboto'),
    ),
    child: Text(text),
  );
}

Future<bool> confirm(BuildContext context, String text, {String yes = 'ДА', String? subtitle, bool danger = false}) async {
  final r = await showAppDialog<bool>(
    context,
    (c) => AppDialog(
      padding: const EdgeInsets.fromLTRB(24, 26, 16, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: TextStyle(color: c.pal.text, fontSize: 18, letterSpacing: 0.2, height: 1.3)),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(subtitle, style: TextStyle(color: c.pal.secondary, fontSize: 15, height: 1.3)),
          ],
          const SizedBox(height: 20),
        ],
      ),
      actions: [
        DialogButton(tr('ОТМЕНА'), onTap: () => Navigator.pop(c, false)),
        DialogButton(tr(yes), onTap: () => Navigator.pop(c, true), color: danger ? c.pal.danger : null),
      ],
    ),
  );
  return r ?? false;
}

/// Всплывающее сообщение по центру («Баланс пересчитан»)
Future<void> showToast(BuildContext context, String text) async {
  final nav = Navigator.of(context);
  var open = true;
  showAppDialog(
    context,
    (c) => Center(
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(color: c.pal.dialog, borderRadius: BorderRadius.circular(8)),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: c.pal.text,
            fontSize: 17,
            letterSpacing: 0.2,
            decoration: TextDecoration.none,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    ),
  ).then((_) => open = false);
  await Future.delayed(const Duration(milliseconds: 1400));
  if (open) nav.pop();
}

void showError(BuildContext context, Object e) {
  final msg = e.toString().replaceFirst('Exception: ', '');
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg.isEmpty ? tr('Что-то пошло не так') : msg)));
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
}

/// Выпадающее меню у элемента (как «Выбор темы»)
Future<T?> showAnchoredMenu<T>(BuildContext context, Offset globalPos, List<(T, String, String?)> items) {
  final p = context.pal;
  final size = MediaQuery.sizeOf(context);
  return showMenu<T>(
    context: context,
    color: p.popup,
    position: RelativeRect.fromLTRB(globalPos.dx, globalPos.dy, size.width - globalPos.dx, 0),
    items: [
      for (final it in items)
        PopupMenuItem<T>(
          value: it.$1,
          height: 52,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(it.$2, style: TextStyle(color: p.text, fontSize: 17, letterSpacing: 0.2)),
              if (it.$3 != null) ...[const SizedBox(width: 36), Text(it.$3!, style: TextStyle(color: p.secondary, fontSize: 17))],
            ],
          ),
        ),
    ],
  );
}

/// Пустое состояние с иконкой
class EmptyState extends StatelessWidget {
  final String text;
  final IconData icon;
  final IconData? inner;
  const EmptyState({super.key, required this.text, required this.icon, this.inner});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text, fontSize: 17, height: 1.3),
          ),
          const SizedBox(height: 18),
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 72, color: p.text.withValues(alpha: 0.75)),
              if (inner != null) Icon(inner, size: 30, color: p.text.withValues(alpha: 0.75)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Плавное появление снизу (каскад для списков)
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 350 + index * 45),
    curve: Curves.easeOutCubic,
    builder: (_, v, c) => Opacity(
      opacity: v,
      child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c),
    ),
    child: child,
  );
}

Route<T> pageRoute<T>(Widget page) => MaterialPageRoute<T>(builder: (_) => page);
