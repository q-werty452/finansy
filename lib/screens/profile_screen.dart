import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../util/icons.dart';
import '../widgets/avatar.dart';
import '../widgets/common.dart';
import 'settings/settings_pages.dart' show BackupScreen;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploading = false;

  Future<void> _avatar() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 85);
    if (x == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      await context.read<AppState>().uploadAvatar(await x.readAsBytes(), 'jpg');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _edit({required bool email}) async {
    final s = context.read<AppState>();
    final c = TextEditingController(text: email ? s.profile?.email : s.profile?.name);
    final r = await showAppDialog<String>(
      context,
      (ctx) => AppDialog(
        title: email ? tr('Почта') : tr('Изменить имя'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: email ? TextInputType.emailAddress : TextInputType.name,
          textCapitalization: email ? TextCapitalization.none : TextCapitalization.words,
          style: TextStyle(color: ctx.pal.text, fontSize: 18),
          decoration: InputDecoration(hintText: email ? 'name@mail.com' : tr('Ваше имя')),
        ),
        actions: [
          DialogButton(tr('ОТМЕНА'), onTap: () => Navigator.pop(ctx)),
          DialogButton(tr('СОХРАНИТЬ'), onTap: () => Navigator.pop(ctx, c.text.trim())),
        ],
      ),
    );
    if (r == null) return;
    if (email) {
      await s.updateProfileEmail(r);
    } else if (r.isNotEmpty) {
      await s.updateProfileName(r);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.watch<AppState>();
    final pr = s.profile;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            title: tr('Профиль'),
            centerTitle: false,
            actions: [HeaderIcon(icon: PI.cloudArrowUp, size: 32, onTap: () => Navigator.push(context, pageRoute(const BackupScreen())))],
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _avatar,
            child: Stack(
              children: [
                Avatar(url: pr?.avatarUrl, name: pr?.name ?? '', size: 140),
                if (_uploading)
                  const Positioned.fill(
                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                Positioned(
                  right: -2,
                  bottom: 0,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(color: Color(0xFFA4B7B1), shape: BoxShape.circle),
                    child: const Icon(PI.pencilSimple, color: Color(0xFFF4F4E8), size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _row(p, PI.user, tr('Имя'), pr?.name ?? '', () => _edit(email: false)),
          _row(
            p,
            PI.envelopeSimple,
            tr('Почта'),
            (pr?.email?.isNotEmpty ?? false) ? pr!.email! : tr('Не задано'),
            () => _edit(email: true),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(74, 16, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('ID: ${pr?.shortId ?? ''}', style: TextStyle(color: p.hint, fontSize: 17)),
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, MediaQuery.paddingOf(context).bottom + 24),
            child: Row(
              children: [
                IconButton(
                  onPressed: () async {
                    if (await confirm(context, tr('Удалить все данные? Это действие нельзя отменить.'), danger: true, yes: 'УДАЛИТЬ')) {
                      await s.deleteAllData();
                    }
                  },
                  icon: Icon(PI.trash, color: p.danger, size: 30),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(context, pageRoute(const BackupScreen())),
                  child: Row(
                    children: [
                      Text(tr('Резервная копия'), style: TextStyle(color: p.accent, fontSize: 18)),
                      const SizedBox(width: 12),
                      Icon(PI.uploadSimple, color: p.accent, size: 28),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(Pal p, IconData icon, String label, String value, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 34, child: Icon(icon, color: p.text, size: 28)),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: p.secondary, fontSize: 15)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: p.text, fontSize: 17.5)),
              ],
            ),
          ),
          Icon(PI.pencilSimple, color: p.secondary, size: 20),
        ],
      ),
    ),
  );
}
