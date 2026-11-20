import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/level.dart';
import '../services/audio_service.dart';
import '../state/progress_repository.dart';
import '../state/settings_controller.dart';
import '../widgets/game_background.dart';

/// Music, sound effects, vibration and a progress reset.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  children: [
                    _SettingTile(
                      icon: Icons.music_note_rounded,
                      title: 'Background music',
                      subtitle: 'Plays on the menu and during a level',
                      value: settings.musicOn,
                      onChanged: settings.setMusic,
                    ),
                    _SettingTile(
                      icon: Icons.volume_up_rounded,
                      title: 'Sound effects',
                      subtitle: 'Pouring, taps, invalid moves and wins',
                      value: settings.soundOn,
                      onChanged: (value) {
                        settings.setSound(value);
                        if (value) AudioService.instance.play(Sfx.click);
                      },
                    ),
                    _SettingTile(
                      icon: Icons.vibration_rounded,
                      title: 'Vibration',
                      subtitle: 'Haptic feedback when you tap and pour',
                      value: settings.vibrationOn,
                      onChanged: (value) {
                        settings.setVibration(value);
                        if (value) AudioService.instance.buzz();
                      },
                    ),
                    const SizedBox(height: 22),
                    MenuButton(
                      icon: Icons.restart_alt_rounded,
                      label: 'Reset progress',
                      colors: const [Color(0xFFEE0979), Color(0xFFFF6A00)],
                      onPressed: () => _confirmReset(context),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Progress, stars and these settings are saved on this '
                      'device and restored the next time you open the game. '
                      'The game works fully offline.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    AudioService.instance.play(Sfx.click);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A0845),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset progress',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This clears every unlocked level, star and best score.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ProgressRepository.instance.resetProgress(LevelRecipe.totalLevels);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progress reset')),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFFFFD54F),
        secondary: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ),
    );
  }
}
