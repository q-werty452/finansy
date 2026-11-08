import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String text;
  const LegalScreen({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(back: true, title: title),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, 20, 18, MediaQuery.paddingOf(context).bottom + 24),
              child: SelectableText(text, style: TextStyle(color: p.text, fontSize: 15.5, height: 1.45)),
            ),
          ),
        ],
      ),
    );
  }
}

String privacyText() => L10n.lang == 'en'
    ? '''Privacy policy

1. What we store. Your email, name, profile photo and the financial records you enter (accounts, categories, transactions, transfers, recurring payments, reminders, tags, comments and receipt photos).

2. Where it is stored. Data is stored in a protected cloud database. Every record is bound to your account; other users cannot read it (row-level security).

3. What we do not do. We do not sell or share your data with third parties and do not use it for advertising.

4. Your control. You can export a backup, delete all data or delete your account at any time in the app (Settings → Data, Profile).

5. Contacts. Use "Contact developer" in the app menu.'''
    : '''Политика конфиденциальности

1. Какие данные мы храним. Почта, имя, фото профиля и финансовые записи, которые вы вводите: счета, категории, операции, переводы, регулярные платежи, напоминания, теги, комментарии и фото чеков.

2. Где хранятся данные. В защищённой облачной базе данных. Каждая запись привязана к вашему аккаунту, другие пользователи не имеют к ней доступа (защита на уровне строк).

3. Чего мы не делаем. Мы не продаём и не передаём ваши данные третьим лицам и не используем их для рекламы.

4. Управление данными. В любой момент вы можете создать резервную копию, удалить все данные или удалить аккаунт (Настройки → Данные, Профиль).

5. Связь. Пункт «Связь с разработчиком» в меню приложения.''';

String eulaText() => L10n.lang == 'en'
    ? '''End user license agreement

By using the app you agree to these terms. The app is provided "as is" for personal finance tracking. The developer is not responsible for financial decisions made based on the data in the app. You are responsible for keeping your account credentials and backup files safe. The developer may update the app and these terms.'''
    : '''Пользовательское соглашение

Используя приложение, вы соглашаетесь с настоящими условиями. Приложение предоставляется «как есть» для личного учёта финансов. Разработчик не несёт ответственности за финансовые решения, принятые на основе данных в приложении. Вы отвечаете за сохранность данных для входа и файлов резервных копий. Разработчик вправе обновлять приложение и настоящие условия.''';
