import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Local notifications: instant reminders when a document is added and a
/// daily reading reminder at the time chosen in Settings.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId = 'pdf_reader_reminders';
  static const _reminderId = 1001;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _ready = true; // Only try the platform setup once.

    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // Falls back to UTC if the platform cannot report a timezone.
    }

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          linux: LinuxInitializationSettings(defaultActionName: 'Open'),
        ),
      );

      if (!kIsWeb && Platform.isAndroid) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
    } catch (error) {
      debugPrint('Notifications unavailable: $error');
    }
  }

  NotificationDetails _details(String sound) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Reading reminders',
        channelDescription: 'Reminders about reading goals and new documents',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: sound != 'Silent',
        sound: sound == 'Alarm'
            ? const UriAndroidNotificationSound(
                'content://settings/system/alarm_alert')
            : null,
      ),
      linux: const LinuxNotificationDetails(),
    );
  }

  /// Fired when a document is imported or scanned.
  ///
  /// Notifications are a nice-to-have: if the platform has no notification
  /// service, or the user denied the permission, the app must keep working.
  Future<void> showDocumentAdded(String title, String sound) async {
    try {
      await init();
      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'Document added',
        body: '"$title" is now in your library.',
        notificationDetails: _details(sound),
      );
    } catch (error) {
      debugPrint('Notification not shown: $error');
    }
  }

  /// Schedules (or cancels) the daily reading reminder.
  Future<void> setDailyReminder({
    required bool enabled,
    required TimeOfDay time,
    required String sound,
  }) async {
    try {
      await init();
      await _plugin.cancel(id: _reminderId);
      if (!enabled) return;

      final now = tz.TZDateTime.now(tz.local);
      var when = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, time.hour, time.minute);
      if (!when.isAfter(now)) when = when.add(const Duration(days: 1));

      await _plugin.zonedSchedule(
        id: _reminderId,
        scheduledDate: when,
        title: 'Time to read',
        body: 'Pick up where you left off in your PDF library.',
        notificationDetails: _details(sound),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (error) {
      debugPrint('Reminder not scheduled: $error');
    }
  }
}
