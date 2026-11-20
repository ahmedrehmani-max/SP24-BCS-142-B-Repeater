import 'tube.dart';

/// A puzzle definition: the starting arrangement of tubes.
class Level {
  final int number;
  final int colorCount;
  final int emptyTubes;
  final int capacity;
  final List<List<int>> startLayout;

  const Level({
    required this.number,
    required this.colorCount,
    required this.emptyTubes,
    required this.capacity,
    required this.startLayout,
  });

  List<Tube> buildTubes() =>
      startLayout.map((layers) => Tube(layers: layers, capacity: capacity)).toList();

  /// Difficulty shown on the level-select screen.
  String get difficulty {
    if (colorCount <= 4) return 'Easy';
    if (colorCount <= 7) return 'Medium';
    return 'Hard';
  }
}

/// How many colours / spare tubes each level uses.
///
/// The puzzle itself is generated from this recipe, so the difficulty curve
/// lives in one place.
class LevelRecipe {
  final int colorCount;
  final int emptyTubes;

  const LevelRecipe(this.colorCount, this.emptyTubes);

  static const totalLevels = 20;

  /// Levels start small and gradually add colours. Two spare tubes are kept
  /// throughout: with only one, a large share of random shuffles are provably
  /// unsolvable, so difficulty comes from the colour count instead.
  static LevelRecipe forLevel(int level) {
    const recipes = <LevelRecipe>[
      LevelRecipe(3, 2), // 1
      LevelRecipe(3, 2), // 2
      LevelRecipe(4, 2), // 3
      LevelRecipe(4, 2), // 4
      LevelRecipe(5, 2), // 5
      LevelRecipe(5, 2), // 6
      LevelRecipe(6, 2), // 7
      LevelRecipe(6, 2), // 8
      LevelRecipe(7, 2), // 9
      LevelRecipe(7, 2), // 10
      LevelRecipe(8, 2), // 11
      LevelRecipe(8, 2), // 12
      LevelRecipe(9, 2), // 13
      LevelRecipe(9, 2), // 14
      LevelRecipe(10, 2), // 15
      LevelRecipe(10, 2), // 16
      LevelRecipe(11, 2), // 17
      LevelRecipe(11, 2), // 18
      LevelRecipe(12, 2), // 19
      LevelRecipe(12, 2), // 20
    ];
    final index = (level - 1).clamp(0, recipes.length - 1);
    return recipes[index];
  }
}
