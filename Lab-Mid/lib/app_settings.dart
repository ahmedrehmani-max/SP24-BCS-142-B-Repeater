import 'package:flutter/material.dart';

import 'db/database_helper.dart';

/// User preferences, persisted in the SQLite `settings` table.
///
/// The app listens to this object, so changing a value repaints the UI
/// immediately and writes the new value to the database.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  final _db = DatabaseHelper.instance;

  ThemeMode themeMode = ThemeMode.system;
  Color readingBackground = const Color(0xFFBDBDBD);
  String notificationSound = 'Default';
  bool reminderEnabled = false;
  TimeOfDay reminderTime = const TimeOfDay(hour: 20, minute: 0);

  static const readingBackgrounds = <String, Color>{
    'Grey': Color(0xFFBDBDBD),
    'White': Color(0xFFFFFFFF),
    'Sepia': Color(0xFFE8D9B5),
    'Dark': Color(0xFF2B2B2B),
  };

  static const notificationSounds = <String>['Default', 'Alarm', 'Silent'];

  Future<void> load() async {
    final values = await _db.getSettings();

    themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == values['theme_mode'],
      orElse: () => ThemeMode.system,
    );
    final background = int.tryParse(values['reading_background'] ?? '');
    if (background != null) readingBackground = Color(background);
    notificationSound = values['notification_sound'] ?? 'Default';
    reminderEnabled = values['reminder_enabled'] == '1';

    final parts = (values['reminder_time'] ?? '20:00').split(':');
    reminderTime = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 20,
      minute: int.tryParse(parts.last) ?? 0,
    );

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await _db.setSetting('theme_mode', mode.name);
  }

  Future<void> setReadingBackground(Color color) async {
    readingBackground = color;
    notifyListeners();
    await _db.setSetting('reading_background', '${color.toARGB32()}');
  }

  Future<void> setNotificationSound(String sound) async {
    notificationSound = sound;
    notifyListeners();
    await _db.setSetting('notification_sound', sound);
  }

  Future<void> setReminder({required bool enabled, TimeOfDay? time}) async {
    reminderEnabled = enabled;
    if (time != null) reminderTime = time;
    notifyListeners();
    await _db.setSetting('reminder_enabled', enabled ? '1' : '0');
    await _db.setSetting(
      'reminder_time',
      '${reminderTime.hour}:${reminderTime.minute}',
    );
  }
}
