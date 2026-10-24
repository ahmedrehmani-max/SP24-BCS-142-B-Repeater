import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../services/export_service.dart';
import '../services/notification_service.dart';

/// Theme and reading customisation, notification settings and data export.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final settings = AppSettings.instance;
  bool exporting = false;

  Future<void> applyReminder() async {
    await NotificationService.instance.setDailyReminder(
      enabled: settings.reminderEnabled,
      time: settings.reminderTime,
      sound: settings.notificationSound,
    );
  }

  Future<void> runExport(String kind) async {
    setState(() => exporting = true);
    String message;

    try {
      switch (kind) {
        case 'csv':
          final file = await ExportService.instance.exportCsv();
          final shared =
              await ExportService.instance.share(file, 'PDF library (CSV)');
          message = shared
              ? 'CSV exported and shared'
              : 'CSV saved to ${file.path}';
        case 'pdf':
          final file = await ExportService.instance.exportPdf();
          final shared =
              await ExportService.instance.share(file, 'PDF library report');
          message = shared
              ? 'PDF report exported and shared'
              : 'PDF report saved to ${file.path}';
        default:
          final opened = await ExportService.instance.emailSummary();
          message = opened ? 'Mail app opened' : 'No mail app available';
      }
    } catch (error) {
      message = 'Export failed: $error';
    }

    if (!mounted) return;
    setState(() => exporting = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
        animation: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const _Header('Appearance'),
            RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (mode) => settings.setThemeMode(mode!),
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    title: Text('Follow system'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    title: Text('Light mode'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    title: Text('Dark mode'),
                  ),
                ],
              ),
            ),
            const _Header('Reading background'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                children: [
                  for (final entry in AppSettings.readingBackgrounds.entries)
                    ChoiceChip(
                      label: Text(entry.key),
                      avatar: CircleAvatar(backgroundColor: entry.value),
                      selected: settings.readingBackground == entry.value,
                      onSelected: (_) =>
                          settings.setReadingBackground(entry.value),
                    ),
                ],
              ),
            ),
            const _Header('Notifications'),
            ListTile(
              leading: const Icon(Icons.music_note_outlined),
              title: const Text('Notification sound'),
              trailing: DropdownButton<String>(
                value: settings.notificationSound,
                items: [
                  for (final sound in AppSettings.notificationSounds)
                    DropdownMenuItem(value: sound, child: Text(sound)),
                ],
                onChanged: (value) async {
                  await settings.setNotificationSound(value!);
                  await applyReminder();
                },
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.alarm_outlined),
              title: const Text('Daily reading reminder'),
              subtitle: Text(
                'Every day at ${settings.reminderTime.format(context)}',
              ),
              value: settings.reminderEnabled,
              onChanged: (value) async {
                await settings.setReminder(enabled: value);
                await applyReminder();
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Reminder time'),
              subtitle: Text(settings.reminderTime.format(context)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: settings.reminderTime,
                );
                if (picked == null) return;
                await settings.setReminder(
                  enabled: settings.reminderEnabled,
                  time: picked,
                );
                await applyReminder();
              },
            ),
            const _Header('Export'),
            if (exporting) const LinearProgressIndicator(),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Export library to CSV'),
              subtitle: const Text('Documents, bookmarks and reading progress'),
              onTap: exporting ? null : () => runExport('csv'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Export library report as PDF'),
              onTap: exporting ? null : () => runExport('pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Email the library summary'),
              onTap: exporting ? null : () => runExport('email'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
}
