import 'package:flutter/material.dart';

import '../game/level_generator.dart';
import '../models/level.dart';
import '../services/audio_service.dart';
import '../state/progress_repository.dart';
import '../widgets/game_background.dart';
import 'game_screen.dart';

/// Grid of levels showing which are unlocked, completed and how many stars
/// each earned.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  final _repository = ProgressRepository.instance;

  int unlocked = 1;
  Map<int, int> stars = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final unlockedLevel = await _repository.unlockedLevel();
    final allStars = await _repository.allStars(LevelRecipe.totalLevels);
    if (!mounted) return;
    setState(() {
      unlocked = unlockedLevel;
      stars = allStars;
      loading = false;
    });
  }

  Future<void> _play(int level) async {
    AudioService.instance.play(Sfx.click);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(levelNumber: level)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              _title(context),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(18),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.88,
                        ),
                        itemCount: LevelRecipe.totalLevels,
                        itemBuilder: (context, index) {
                          final level = index + 1;
                          return _LevelTile(
                            level: level,
                            stars: stars[level] ?? 0,
                            locked: level > unlocked,
                            difficulty:
                                LevelGenerator.generate(level).difficulty,
                            onTap: () => _play(level),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 18, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Select Level',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '${stars.values.fold(0, (a, b) => a + b)} / '
            '${LevelRecipe.totalLevels * 3}  ',
            style: const TextStyle(color: Colors.white70),
          ),
          const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 20),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final int level;
  final int stars;
  final bool locked;
  final String difficulty;
  final VoidCallback onTap;

  const _LevelTile({
    required this.level,
    required this.stars,
    required this.locked,
    required this.difficulty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completed = stars > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: locked ? null : onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: locked
                  ? [Colors.white10, Colors.white10]
                  : completed
                      ? const [Color(0xFF11998E), Color(0xFF38EF7D)]
                      : const [Color(0xFF7B2FF7), Color(0xFFF107A3)],
            ),
            border: Border.all(
              color: locked ? Colors.white12 : Colors.white24,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (locked)
                const Icon(Icons.lock_rounded, color: Colors.white38, size: 26)
              else
                Text(
                  '$level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(height: 2),
              if (!locked) ...[
                StarRow(stars: stars, size: 13),
                Text(
                  difficulty,
                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
