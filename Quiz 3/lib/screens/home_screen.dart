import 'package:flutter/material.dart';

import '../models/level.dart';
import '../models/tube.dart';
import '../services/audio_service.dart';
import '../state/progress_repository.dart';
import '../widgets/game_background.dart';
import '../widgets/tube_widget.dart';
import 'achievements_screen.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';

/// Main menu.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repository = ProgressRepository.instance;
  int currentLevel = 1;

  @override
  void initState() {
    super.initState();
    _refresh();
    AudioService.instance.startMusic();
  }

  Future<void> _refresh() async {
    final level = await _repository.currentLevel();
    if (!mounted) return;
    setState(() => currentLevel = level);
  }

  Future<void> _open(Widget screen) async {
    AudioService.instance.play(Sfx.click);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    await _refresh();
  }

  Future<void> _confirmExit() async {
    AudioService.instance.play(Sfx.click);
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A0845),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit game', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Your progress is saved. Leave the game?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (leave == true) {
      await AudioService.instance.stopMusic();
      // Closes the app on Android; on desktop it pops the last route.
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 16, 26, 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Title with a soft glow behind it.
                const Text(
                  'COLOR',
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    height: 1,
                  ),
                ),
                const Text(
                  'WATER SORT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sort the liquids • One colour per tube',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 18),
                _decorativeTubes(),
                const SizedBox(height: 18),
                MenuButton(
                  icon: Icons.play_arrow_rounded,
                  label: currentLevel > 1
                      ? 'Continue — Level $currentLevel'
                      : 'Play Game',
                  onPressed: () =>
                      _open(GameScreen(levelNumber: currentLevel)),
                ),
                MenuButton(
                  icon: Icons.grid_view_rounded,
                  label: 'Level Selection',
                  colors: const [Color(0xFF00B4DB), Color(0xFF0083B0)],
                  onPressed: () => _open(const LevelSelectScreen()),
                ),
                MenuButton(
                  icon: Icons.emoji_events_rounded,
                  label: 'Achievements',
                  colors: const [Color(0xFFF7971E), Color(0xFFFFD200)],
                  onPressed: () => _open(const AchievementsScreen()),
                ),
                MenuButton(
                  icon: Icons.help_outline_rounded,
                  label: 'How to Play',
                  colors: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                  onPressed: () => _open(const HowToPlayScreen()),
                ),
                MenuButton(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  colors: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                  onPressed: () => _open(const SettingsScreen()),
                ),
                MenuButton(
                  icon: Icons.exit_to_app_rounded,
                  label: 'Exit',
                  colors: const [Color(0xFFEE0979), Color(0xFFFF6A00)],
                  onPressed: _confirmExit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Three sample tubes under the title, purely decorative.
  Widget _decorativeTubes() {
    const samples = [
      [0, 1, 0, 1],
      [2, 3, 2, 3],
      [4, 5, 4, 5],
    ];
    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < samples.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 500 + i * 180),
                curve: Curves.easeOutBack,
                builder: (context, value, child) => Transform.translate(
                  offset: Offset(0, (1 - value) * 40),
                  child: Opacity(opacity: value.clamp(0, 1), child: child),
                ),
                child: TubeWidget(
                  tube: Tube(layers: samples[i]),
                  width: 42,
                  height: 118,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Levels available in the game, re-exported so the menus agree on the count.
int get totalLevels => LevelRecipe.totalLevels;
