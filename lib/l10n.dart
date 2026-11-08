import 'package:intl/intl.dart';

/// Русская строка — сама является ключом. Для английского ищем перевод.
class L10n {
  static String lang = 'ru';
  static String get locale => lang == 'en' ? 'en' : 'ru';
}

String tr(String ru, [Map<String, Object>? args]) {
  var s = L10n.lang == 'en' ? (_en[ru] ?? ru) : ru;
  args?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

DateFormat df(String pattern) => DateFormat(pattern, L10n.locale);

/// Склонение для русского: 1 операция, 2 операции, 5 операций
String plural(int n, String one, String few, String many) {
  if (L10n.lang == 'en') return n == 1 ? one : few;
  final m10 = n % 10, m100 = n % 100;
  if (m10 == 1 && m100 != 11) return one;
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
  return many;
}

const _en = <String, String>{
  // Общие
  'Отмена': 'Cancel', 'ОТМЕНА': 'CANCEL', 'ВЫБРАТЬ': 'SELECT', 'ДА': 'YES', 'НЕТ': 'NO', 'OK': 'OK',
  'СОХРАНИТЬ': 'SAVE', 'УДАЛИТЬ': 'DELETE', 'Сохранить': 'Save', 'Удалить': 'Delete', 'Создать': 'Create',
  'Далее': 'Next', 'Добавить': 'Add', 'Готово': 'Done', 'Поиск': 'Search', 'Изменить': 'Edit',
  'РАСХОДЫ': 'EXPENSES', 'ДОХОДЫ': 'INCOME', 'ОБЩИЙ': 'OVERVIEW', 'Итого': 'Total', 'Итого:': 'Total:',
  'Расходы': 'Expenses', 'Доходы': 'Income', 'Все': 'All',
  'Обязательное поле для заполнения': 'Required field', 'Не задано': 'Not set', 'Не задан': 'Not set',
  'Не выбран': 'Not selected', 'По умолчанию': 'Default', 'Отключено': 'Disabled',
  'Нет соединения с сервером': 'No connection to server', 'Что-то пошло не так': 'Something went wrong',
  'сегодня': 'today', 'вчера': 'yesterday', 'позавчера': 'day before',
  'Сегодня': 'Today', 'Вчера': 'Yesterday',
  // Меню
  'Главная': 'Home', 'Счета': 'Accounts', 'Графики': 'Charts', 'Категории': 'Categories',
  'Регулярные платежи': 'Recurring payments', 'Напоминания': 'Reminders', 'Настройки': 'Settings',
  'Поделиться с друзьями': 'Share with friends', 'Оценить приложение': 'Rate the app',
  'Связь с разработчиком': 'Contact developer', 'Остаток: {v}': 'Balance: {v}',
  // Главная
  'День': 'Day', 'Неделя': 'Week', 'Месяц': 'Month', 'Год': 'Year', 'Период': 'Period',
  'Сегодня расходов не было': 'No expenses today', 'Сегодня доходов не было': 'No income today',
  'В этот день расходов не было': 'No expenses this day', 'В этот день доходов не было': 'No income this day',
  'На этой неделе расходов не было': 'No expenses this week', 'На этой неделе доходов не было': 'No income this week',
  'В эту неделю расходов не было': 'No expenses this week', 'В эту неделю доходов не было': 'No income this week',
  'В этом месяце расходов не было': 'No expenses this month', 'В этом месяце доходов не было': 'No income this month',
  'В этом году расходов не было': 'No expenses this year', 'В этом году доходов не было': 'No income this year',
  'За этот период расходов не было': 'No expenses for this period', 'За этот период доходов не было': 'No income for this period',
  'Выберите счет': 'Select account', 'Выберите счета': 'Select accounts', 'Скрыть баланс на главной': 'Hide balance on home',
  'Выбор периода': 'Select period', 'За все время': 'All time', 'Малые траты': 'Small expenses',
  // Операции
  'Добавление операции': 'New transaction', 'Редактирование': 'Edit transaction', 'Счет': 'Account',
  'Теги': 'Tags', 'Добавить тег': 'Add tag', 'Комментарий': 'Comment', 'Фото': 'Photo', 'Еще': 'More',
  'Введите сумму': 'Enter amount', 'Выберите категорию': 'Choose a category', 'Операции': 'Transactions',
  'Нет операций': 'No transactions', 'Удалить операцию?': 'Delete transaction?', 'Новый тег': 'New tag',
  'Сделать фото': 'Take photo', 'Выбрать из галереи': 'Choose from gallery', 'Калькулятор': 'Calculator',
  'Поиск по тегам': 'Search tags', 'Операция добавлена': 'Transaction added', 'Операция удалена': 'Transaction deleted',
  // Счета
  'История переводов': 'Transfer history', 'Создать перевод': 'New transfer', 'Новый счет': 'New account',
  'Редактировать счет': 'Edit account', 'Название счета': 'Account name', 'Текущий баланс': 'Current balance',
  'Валюта': 'Currency', 'Иконка': 'Icon', 'Цвет': 'Color', 'Учитывать в итоговом балансе': 'Include in total',
  'Удалить счет?': 'Delete account?', 'Все операции этого счета будут удалены': 'All transactions of this account will be deleted',
  'Перевод': 'Transfer', 'Со счета': 'From account', 'На счет': 'To account', 'Сумма': 'Amount',
  'Сумма зачисления': 'Amount received', 'Дата': 'Date', 'Перевести': 'Transfer', 'Переводов пока нет': 'No transfers yet',
  'Нужно минимум два счета': 'You need at least two accounts', 'Основной': 'Main',
  // Графики
  'по годам': 'by years', 'по месяцам': 'by months', 'по неделям': 'by weeks', 'по дням': 'by days',
  '- доходы': '- income', '- расходы': '- expenses', '- прибыль': '- profit', '- убыток': '- loss',
  // Категории
  'Новая категория': 'New category', 'Редактировать категорию': 'Edit category', 'Название': 'Name',
  'Удалить категорию?': 'Delete category?', 'Операции останутся без категории': 'Transactions will stay without a category',
  'Перемещение категорий': 'Reorder categories', 'Перетащите категории, чтобы изменить порядок': 'Drag categories to reorder',
  'Здоровье': 'Health', 'Досуг': 'Leisure', 'Дом': 'Home', 'Кафе': 'Cafe', 'Образование': 'Education',
  'Подарки': 'Gifts', 'Продукты': 'Groceries', 'Семья': 'Family', 'Спорт': 'Sport', 'Транспорт': 'Transport',
  'Другое': 'Other', 'Зарплата': 'Salary', 'Подарок': 'Gift', 'Проценты по вкладам': 'Deposit interest',
  // Регулярные
  'Добавьте регулярный платеж': 'Add a recurring payment', 'Создать напоминание': 'Create reminder',
  'Регулярный платеж': 'Recurring payment', 'Наименование платежа': 'Payment name', 'Имя': 'Name',
  'Периодичность напоминания': 'Repeat', 'Добавлять автоматически': 'Add automatically',
  'Дата начала напоминания': 'Start date', 'Время': 'Time', 'Дата окончания напоминания': 'End date',
  'Категория': 'Category', 'Выбрать категорию': 'Choose category', 'Следующий платеж: {d}': 'Next payment: {d}',
  'Каждый день': 'Every day', 'Каждую неделю': 'Every week', 'Каждый месяц': 'Every month',
  'Каждый квартал': 'Every quarter', 'Каждый год': 'Every year', 'Один раз': 'Once',
  'Удалить платеж?': 'Delete payment?', 'Удалить напоминание?': 'Delete reminder?',
  'Имя напоминания': 'Reminder name', 'Напоминаний пока нет': 'No reminders yet', 'Внести платеж': 'Pay now',
  'Платеж внесен': 'Payment added', 'Автоматически': 'Automatic',
  // Настройки
  'Код-пароль': 'Passcode', 'Персонализация': 'Personalization', 'Внешний вид': 'Appearance',
  'Расширенные настройки': 'Advanced settings', 'Данные': 'Data', 'Дополнительно': 'Additional',
  'Восстановить покупки': 'Restore purchases', 'Версия {v}': 'Version {v}', 'Покупки не найдены': 'No purchases found',
  'Вы можете установить код-пароль из 4х цифр на вход в приложение.': 'You can set a 4-digit passcode to open the app.',
  'Установить код-пароль': 'Set passcode', 'Изменить код-пароль': 'Change passcode', 'Отключить код-пароль': 'Disable passcode',
  'Установка код-пароля': 'Set passcode', 'Придумайте код-пароль': 'Create a passcode', 'Повторите код-пароль': 'Repeat the passcode',
  'Коды не совпадают': 'Codes do not match', 'Введите код-пароль': 'Enter passcode', 'Неверный код-пароль': 'Wrong passcode',
  'Код-пароль установлен': 'Passcode set', 'Код-пароль отключен': 'Passcode disabled',
  'Показывать по умолчанию': 'Show by default', 'Объединить малые траты': 'Merge small expenses',
  'Периоды': 'Periods', 'Период по умолчанию': 'Default period', 'Свой месяц': 'Custom month',
  'Добавление операции ': 'Adding transactions', 'Счет по умолчанию': 'Default account', 'Дополнительные поля': 'Extra fields',
  'При добавлении расходов и доходов будут отображаться только отмеченные блоки дополнительной информации.':
      'Only checked blocks of extra information will be shown when adding expenses and income.',
  'Выбор языка': 'Language', 'Выбор темы': 'Theme', 'Иконка приложения': 'App icon', 'Светлая тема': 'Light theme',
  'Темная тема': 'Dark theme', 'Русский': 'Русский', 'Первый день недели': 'First day of week',
  'Десятичный разделитель': 'Decimal separator', 'Точка': 'Point', 'Запятая': 'Comma',
  'Показывать копейки': 'Show cents', 'Валюта операции из счета': 'Use account currency',
  'Компактный вид списка операций': 'Compact transaction list', 'Доходы в приоритете': 'Income first',
  'Понедельник': 'Monday', 'Воскресенье': 'Sunday', 'Суббота': 'Saturday',
  'Пересчитать баланс': 'Recalculate balance', 'Резервное копирование': 'Backup', 'Удалить все данные': 'Delete all data',
  'Баланс пересчитан': 'Balance recalculated', 'Создать резервную копию': 'Create backup',
  'Сохранение полной копии ваших данных в файл. Храните полученный файл в надежном месте':
      'Save a full copy of your data to a file. Keep the file in a safe place',
  'Восстановить резервную копию': 'Restore backup',
  'Загрузка ранее созданной резервной копии данных приложения. Текущие данные будут заменены':
      'Load a previously created backup. Current data will be replaced',
  'Создать резервную копию?': 'Create a backup?',
  'Резервная копия создана успешно! Сохраните файл в надежном месте.': 'Backup created successfully! Save the file in a safe place.',
  'Восстановить данные из файла? Текущие данные будут заменены.': 'Restore data from file? Current data will be replaced.',
  'Данные восстановлены': 'Data restored',
  'Удалить все данные? Это действие нельзя отменить.': 'Delete all data? This cannot be undone.',
  'Все данные удалены': 'All data deleted',
  'Дополнительные настройки': 'Additional settings', 'Политика конфиденциальности': 'Privacy policy',
  'Пользовательское соглашение (EULA)': 'End user license agreement (EULA)',
  // Профиль
  'Профиль': 'Profile', 'Почта': 'Email', 'Выйти': 'Log out', 'Выход со всех устройств': 'Log out of all devices',
  'Выйти из аккаунта?': 'Log out?', 'Удалить аккаунт?': 'Delete account?',
  'Аккаунт и все данные будут удалены без возможности восстановления.': 'The account and all data will be permanently deleted.',
  'Изменить имя': 'Change name',
  // Связь
  'Связаться с разработчиком': 'Contact developer', 'Тема сообщения': 'Subject', 'Текст сообщения': 'Message',
  'На эту почту будет выслан ответ': 'The reply will be sent to this email', 'Отправить': 'Send',
  'Сообщение отправлено. Спасибо!': 'Message sent. Thank you!',
  // Оценка
  'Мы очень сильно стараемся для Вас и каждый день улучшаем наше приложение!': 'We work hard for you and improve our app every day!',
  'Пожалуйста, поставьте нам 5 звезд на странице приложения в App Store!': 'Please rate us 5 stars on the App Store!',
  'Спасибо Вам большое!': 'Thank you very much!', '5 ЗВЁЗДОЧЕК': '5 STARS',
  // Онбординг / вход
  'Выберите валюту\nпо умолчанию': 'Choose default\ncurrency',
  'Введите текущий баланс\nосновного счета': 'Enter the current balance\nof your main account',
  'Вы сможете добавить дополнительные счета в разделе "Счета"': 'You can add more accounts in the "Accounts" section',
  'Пользователи, которые используют напоминания, в два раза чаще достигают своих целей':
      'Users who use reminders reach their goals twice as often',
  'Приложение Финансы помогает выработать полезные привычки, которые останутся с вами надолго':
      'Finansy helps you build good habits that stay with you for a long time',
  'Включить уведомления': 'Enable notifications', 'Пропустить': 'Skip',
  'Финансы': 'Finansy', 'Учёт расходов и доходов': 'Expense & income tracker',
  'Войти через Google': 'Sign in with Google', 'Войти через Apple': 'Sign in with Apple',
  'Войти по почте': 'Sign in with email', 'Пароль': 'Password', 'Войти': 'Sign in',
  'Зарегистрироваться': 'Sign up', 'Регистрация': 'Sign up', 'Вход': 'Sign in',
  'Нет аккаунта? Зарегистрироваться': "No account? Sign up", 'Уже есть аккаунт? Войти': 'Have an account? Sign in',
  'Минимум 6 символов': 'At least 6 characters', 'Неверная почта': 'Invalid email', 'Забыли пароль?': 'Forgot password?',
  'Письмо для сброса пароля отправлено': 'Password reset email sent', 'Ваше имя': 'Your name',
  'Неверная почта или пароль': 'Wrong email or password',
  'Подтвердите почту по ссылке из письма': 'Confirm your email via the link we sent',
  'Продолжая, вы принимаете условия использования': 'By continuing you accept the terms of use',
  'Резервная копия': 'Backup', 'Экспортировать данные в формат:': 'Export data as:', 'ВЫГРУЗИТЬ': 'EXPORT', 'Всего': 'Total',
  'Сначала новые': 'Newest first',
  'Сначала старые': 'Oldest first',
  'Сначала крупные': 'Largest first',
  'Сначала мелкие': 'Smallest first',
  'Не найдено почтовое приложение': 'No email app found',
  'Сбросить код-пароль?': 'Reset passcode?',
  'Для защиты все данные на этом устройстве будут удалены. Восстановить их можно из резервной копии.':
      'For security, all data on this device will be deleted. You can restore it from a backup.',
  'Повторить': 'Retry',
  'Удалить перевод?': 'Delete transfer?',
  'Выберите разные счета': 'Choose different accounts', 'Завершен': 'Finished',
  'Не забудьте внести платеж': "Don't forget to make the payment", 'Менее {p}%': 'Less than {p}%', 'С {d} числа': 'From day {d}',
  'Какой счет будет выбран на главном экране при запуске приложения.': 'Which account is selected on the home screen at launch.',
  'Категории, доля которых меньше выбранного процента, на диаграмме объединяются в одну — «Малые траты».':
      'Categories below the chosen share are merged into "Small expenses" on the chart.',
  'Период, который открывается на главном экране.': 'The period opened on the home screen.',
  'Если зарплата приходит, например, 10 числа — месяц на главном экране будет считаться с 10 по 9 число.':
      'If your salary comes on the 10th, the month will be counted from the 10th to the 9th.',
  'Этот счет будет подставляться при добавлении новой операции.': 'This account is preselected for new transactions.',
  'Пример': 'Example', 'Неверный формат файла': 'Invalid file format', 'Код-пароль будет сброшен': 'The passcode will be reset',
  'Забыли код-пароль?': 'Forgot passcode?',
  'Файл содержит все счета, категории, операции, переводы, регулярные платежи и напоминания. Его можно сохранить в «Файлы», отправить себе в мессенджер или на почту.':
      'The file contains all accounts, categories, transactions, transfers, recurring payments and reminders.',
  'Выберите файл .fbackup, созданный ранее. Все текущие данные аккаунта будут заменены данными из файла.':
      'Choose a previously created .fbackup file. All current data will be replaced.',
};
