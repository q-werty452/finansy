import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../util/icons.dart';
import 'common.dart';

class TagsBlock extends StatelessWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  const TagsBlock({super.key, required this.tags, required this.onChanged});

  Future<void> _add(BuildContext context) async {
    final t = await showTagDialog(context, tags);
    if (t != null) onChanged(t);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tr('Теги'), style: TextStyle(color: p.secondary, fontSize: 15, letterSpacing: 0.2)),
              const Spacer(),
              InkResponse(
                onTap: () => _add(context),
                radius: 24,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(PI.magnifyingGlass, color: p.accent, size: 30),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in tags)
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 7, 6, 7),
                  decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('#$t', style: TextStyle(color: p.accent, fontSize: 16)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => onChanged([...tags]..remove(t)),
                        child: Icon(Icons.close, size: 18, color: p.accent),
                      ),
                    ],
                  ),
                ),
              InkWell(
                onTap: () => _add(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 3, 11, 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: p.accent, width: 1.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PI.plus, color: p.accent, size: 22),
                      const SizedBox(width: 6),
                      Text(tr('Добавить тег'), style: TextStyle(color: p.accent, fontSize: 15.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<List<String>?> showTagDialog(BuildContext context, List<String> current) {
  final all = context.read<AppState>().tags;
  final sel = {...current};
  final ctl = TextEditingController();
  return showAppDialog<List<String>>(
    context,
    (c) => StatefulBuilder(
      builder: (c, set) {
        final p = c.pal;
        final q = ctl.text.trim().toLowerCase();
        final list = all.where((t) => t.toLowerCase().contains(q)).toList();
        final canCreate = q.isNotEmpty && !all.any((t) => t.toLowerCase() == q);
        return AppDialog(
          title: tr('Теги'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctl,
                autofocus: true,
                style: TextStyle(color: p.text, fontSize: 17),
                decoration: InputDecoration(
                  hintText: tr('Новый тег'),
                  suffixIcon: Icon(PI.magnifyingGlass, color: p.hint),
                ),
                onChanged: (_) => set(() {}),
                onSubmitted: (v) {
                  final t = v.trim();
                  if (t.isNotEmpty) Navigator.pop(c, [...sel, if (!sel.contains(t)) t]);
                },
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (canCreate)
                        ActionChip(
                          backgroundColor: p.accent,
                          side: BorderSide.none,
                          label: Text('+ ${ctl.text.trim()}', style: const TextStyle(color: Colors.white)),
                          onPressed: () => Navigator.pop(c, [...sel, ctl.text.trim()]),
                        ),
                      for (final t in list)
                        FilterChip(
                          selected: sel.contains(t),
                          showCheckmark: false,
                          backgroundColor: p.card,
                          selectedColor: p.accent.withValues(alpha: 0.35),
                          side: BorderSide.none,
                          label: Text('#$t', style: TextStyle(color: p.text)),
                          onSelected: (v) => set(() => v ? sel.add(t) : sel.remove(t)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            DialogButton(tr('ОТМЕНА'), onTap: () => Navigator.pop(c)),
            DialogButton(tr('ВЫБРАТЬ'), onTap: () => Navigator.pop(c, sel.toList())),
          ],
        );
      },
    ),
  );
}
