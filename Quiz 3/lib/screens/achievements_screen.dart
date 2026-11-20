import 'package:flutter/material.dart';

import '../models/level.dart';
import '../state/progress_repository.dart';
import '../widgets/game_background.dart';

/// Completed levels, stars earned and overall progress.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _repository = ProgressRepository.instance;

  Map<int, int> stars = {};
  Map<int, int?> bestMoves = {};
  int unlocked = 1;
  bool loading = true;

  static const _total = LevelRecipe.totalLevels;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final allStars = await _repository.allStars(_total);
    final unlockedLevel = await _repository.unlockedLevel();
    final moves = <int, int?>{};
    for (var level = 1; level <= _total; level++) {
      moves[level] = await _repository.bestMovesFor(level);
    }
    if (!mounted) return;
    setState(() {
      stars = allStars;
      bestMoves = moves;
      unlocked = unlockedLevel;
      loading = false;
    });
  }

  int get completed => stars.values.where((s) => s > 0).length;
  int get earnedStars => stars.values.fold(0, (a, b) => a + b);
  int get perfectLevels => stars.values.where((s) => s == 3).length;

  /// Badges unlocked by progress so far.
  List<(IconData, String, String, bool)> get _badges => [
        (
          Icons.flag_rounded,
          'First Steps',
          'Complete level 1',
          completed >= 1,
        ),
        (
          Icons.local_fire_department_rounded,
          'Getting Warm',
          'Complete 5 levels',
          completed >= 5,
        ),
        (
          Icons.auto_awesome_rounded,
          'Perfectionist',
          'Earn 3 stars on 3 levels',
          perfectLevels >= 3,
        ),
        (
          Icons.workspace_premium_rounded,
          'Halfway There',
          'Complete 10 levels',
          completed >= 10,
        ),
        (
          Icons.emoji_events_rounded,
          'Master Sorter',
          'Complete all $_total levels',
          completed >= _total,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Achievements',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                        children: [
                          _summary(),
                          const SizedBox(height: 18),
                          const Text(
                            'Badges',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final (icon, title, goal, unlockedBadge)
                              in _badges)
                            _badgeTile(icon, title, goal, unlockedBadge),
                          const SizedBox(height: 18),
                          const Text(
                            'Level results',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (var level = 1; level <= _total; level++)
                            if ((stars[level] ?? 0) > 0) _resultTile(level),
                          if (completed == 0)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'No levels completed yet — play one to start '
                                'filling this list.',
                                style: TextStyle(color: Colors.white54),
                              ),
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

  Widget _summary() {
    final progress = completed / _total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF7B2FF7), Color(0xFFF107A3)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('$completed/$_total', 'Levels'),
              _stat('$earnedStars/${_total * 3}', 'Stars'),
              _stat('$perfectLevels', '3-star'),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFFFFD54F)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).round()}% complete',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      );

  Widget _badgeTile(IconData icon, String title, String goal, bool unlockedBadge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: unlockedBadge ? 0.14 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlockedBadge ? const Color(0xFFFFD54F) : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: unlockedBadge ? const Color(0xFFFFD54F) : Colors.white24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: unlockedBadge ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  goal,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          if (unlockedBadge)
            const Icon(Icons.check_circle_rounded, color: Color(0xFF38EF7D)),
        ],
      ),
    );
  }

  Widget _resultTile(int level) {
    final best = bestMoves[level];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              'Level $level',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          StarRow(stars: stars[level] ?? 0, size: 15),
          const Spacer(),
          Text(
            best == null ? '' : 'best $best moves',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
