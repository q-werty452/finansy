import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';

import '../l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _subject = TextEditingController();
  late final _email = TextEditingController(text: context.read<AppState>().profile?.email ?? '');
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_subject, _email, _text]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _subject.dispose();
    _email.dispose();
    _text.dispose();
    super.dispose();
  }

  bool get _valid =>
      _subject.text.trim().isNotEmpty && _text.text.trim().isNotEmpty && RegExp(r'^\S+@\S+\.\S+$').hasMatch(_email.text.trim());

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final uri = Uri(
        scheme: 'mailto',
        path: AppConfig.supportEmail,
        query:
            'subject=${Uri.encodeComponent(_subject.text.trim())}&body=${Uri.encodeComponent('${_text.text.trim()}\n\n— ${_email.text.trim()}')}',
      );
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!ok) throw Exception(tr('Не найдено почтовое приложение'));
      _subject.clear();
      _text.clear();
      FocusScope.of(context).unfocus();
      await showToast(context, tr('Сообщение отправлено. Спасибо!'));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(title: tr('Связаться с разработчиком')),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 30),
              children: [
                TextField(
                  controller: _subject,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: p.text, fontSize: 16),
                  decoration: InputDecoration(hintText: tr('Тема сообщения')),
                ),
                const SizedBox(height: 56),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: p.text, fontSize: 16),
                  decoration: InputDecoration(
                    helperText: tr('На эту почту будет выслан ответ'),
                    helperStyle: TextStyle(color: p.secondary, fontSize: 13.5),
                  ),
                ),
                const SizedBox(height: 50),
                TextField(
                  controller: _text,
                  maxLines: null,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: p.text, fontSize: 16),
                  decoration: InputDecoration(hintText: tr('Текст сообщения')),
                ),
                const SizedBox(height: 70),
                Center(
                  child: YellowButton(text: tr('Отправить'), loading: _sending, onTap: _valid ? _send : null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
