import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Напоминания',
      channelDescription: 'Напоминания по заметкам',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    windows: WindowsNotificationDetails(),
  );

  Future<void> init() async {
    if (kIsWeb) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Остаётся UTC; время напоминаний тогда считается по UTC.
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        windows: WindowsInitializationSettings(
          appName: 'QuickNotes',
          appUserModelId: 'com.quicknotes.app',
          guid: '6f1c3a52-8f0e-4a43-9c63-1d2f5a7b9e10',
        ),
      ),
    );
    _ready = true;
  }

  /// Запрашивает разрешение на уведомления (iOS / Android 13+).
  Future<void> requestPermission() async {
    if (!_ready) return;
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    }
  }

  Future<void> schedule(Note note) async {
    if (!_ready) return;
    await cancel(note);
    final at = note.reminderAt;
    if (at == null) return;

    var when = tz.TZDateTime.from(at, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!when.isAfter(now)) {
      // Прошедшее одноразовое напоминание не планируем.
      if (note.repeat == Repeat.none) return;
      // Повторяющееся: переносим на ближайшее будущее вхождение.
      final step = note.repeat == Repeat.daily
          ? const Duration(days: 1)
          : const Duration(days: 7);
      while (!when.isAfter(now)) {
        when = when.add(step);
      }
    }

    final title = note.title.trim().isEmpty ? 'Напоминание' : note.title.trim();
    final body = note.body.trim();

    await _plugin.zonedSchedule(
      id: note.notificationId,
      title: title,
      body: body.isEmpty ? null : body,
      scheduledDate: when,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: switch (note.repeat) {
        Repeat.none => null,
        Repeat.daily => DateTimeComponents.time,
        Repeat.weekly => DateTimeComponents.dayOfWeekAndTime,
      },
    );
  }

  Future<void> cancel(Note note) async {
    if (!_ready) return;
    await _plugin.cancel(id: note.notificationId);
  }
}
