import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/models.dart';
import '../l10n.dart';

class Notifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Напоминания',
      channelDescription: 'Напоминания о платежах',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF274E3E),
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('timezone: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
      ),
    );
    _ready = true;
  }

  static Future<bool> requestPermission() async {
    await init();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final a = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final ok = await a?.requestNotificationsPermission() ?? false;
      await a?.requestExactAlarmsPermission();
      return ok;
    }
    final i = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await i?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
  }

  static Future<void> schedule(Reminder r) async {
    await init();
    await cancel(r);
    if (!r.enabled) return;
    var when = tz.TZDateTime.from(r.remindAt, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (r.period == 'once' && when.isBefore(now)) return;
    DateTimeComponents? match;
    switch (r.period) {
      case 'day':
        match = DateTimeComponents.time;
      case 'week':
        match = DateTimeComponents.dayOfWeekAndTime;
      case 'month':
        match = DateTimeComponents.dayOfMonthAndTime;
      case 'year':
        match = DateTimeComponents.dateAndTime;
    }
    while (match != null && when.isBefore(now)) {
      when = switch (r.period) {
        'day' => when.add(const Duration(days: 1)),
        'week' => when.add(const Duration(days: 7)),
        'month' => tz.TZDateTime(tz.local, when.year, when.month + 1, when.day, when.hour, when.minute),
        _ => tz.TZDateTime(tz.local, when.year + 1, when.month, when.day, when.hour, when.minute),
      };
    }
    try {
      await _plugin.zonedSchedule(
        id: r.notificationId,
        title: r.name,
        body: r.comment.isEmpty ? tr('Финансы') : r.comment,
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: match,
      );
    } catch (e) {
      debugPrint('schedule: $e');
    }
  }

  static Future<void> cancel(Reminder r) async {
    await init();
    await _plugin.cancel(id: r.notificationId);
  }

  static Future<void> syncAll(List<Reminder> reminders, List<Recurring> recurring) async {
    try {
      await init();
      await _plugin.cancelAll();
      for (final r in reminders) {
        await schedule(r);
      }
      for (final r in recurring.where((r) => r.active)) {
        await schedule(
          Reminder(
            id: r.id,
            name: r.name,
            period: 'once',
            remindAt: r.nextRun,
            comment: r.autoAdd ? tr('Регулярный платеж') : tr('Не забудьте внести платеж'),
            enabled: true,
          ),
        );
      }
    } catch (e) {
      debugPrint('notifications: $e');
    }
  }
}
