import 'package:flutter/material.dart';

import '../widgets/confetti.dart';
import '../widgets/game_background.dart';

/// What the player chose on the level-complete screen.
enum WinAction { next, replay, home }

/// Level-complete celebration: stars, move count and what to do next.
class WinScreen extends StatelessWidget {
  final int level;
  final int moves;
  final int stars;
  final int? bestMoves;
  final bool hasNextLevel;

  const WinScreen({
    super.key,
    required this.level,
    required this.moves,
    required this.stars,
    required this.bestMoves,
    required this.hasNextLevel,
  });

  String get headline => switch (stars) {
        3 => 'Excellent!',
        2 => 'Well done!',
        _ => 'Level Completed!',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.72),
      body: Stack(
        children: [
          const Positioned.fill(child: Confetti()),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 320,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF3B1361), Color(0xFF1B1035)],
                  ),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.6, end: 1),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Text(
                        headline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Level $level',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 18),
                    // Stars pop in one after another.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < 3; i++)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 320 + i * 220),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) => Transform.scale(
                              scale: i < stars ? value : 1,
                              child: child,
                            ),
                            child: Icon(
                              i < stars
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 54,
                              color: i < stars
                                  ? const Color(0xFFFFD54F)
                                  : Colors.white24,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _Stat(label: 'Moves', value: '$moves'),
                        _Stat(
                          label: 'Best',
                          value: bestMoves == null ? '—' : '$bestMoves',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (hasNextLevel)
                      MenuButton(
                        icon: Icons.skip_next_rounded,
                        label: 'Next Level',
                        onPressed: () =>
                            Navigator.pop(context, WinAction.next),
                      ),
                    MenuButton(
                      icon: Icons.replay_rounded,
                      label: 'Replay',
                      colors: const [Color(0xFF00B4DB), Color(0xFF0083B0)],
                      onPressed: () =>
                          Navigator.pop(context, WinAction.replay),
                    ),
                    MenuButton(
                      icon: Icons.home_rounded,
                      label: 'Main Menu',
                      colors: const [Color(0xFFEE0979), Color(0xFFFF6A00)],
                      onPressed: () => Navigator.pop(context, WinAction.home),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }
}
