import 'dart:math';

import '../models/level.dart';
import '../models/tube.dart';
import 'game_engine.dart';

/// Builds puzzles that are guaranteed solvable.
///
/// The deck of colours is shuffled into the tubes, then the solver checks the
/// arrangement. Anything it cannot solve is thrown away and regenerated, so a
/// player never receives an impossible board.
class LevelGenerator {
  static const capacity = 4;

  /// Deterministic per level: the same level number always produces the same
  /// puzzle, which is what makes "best moves" and "restart" meaningful.
  static Level generate(int levelNumber) {
    final recipe = LevelRecipe.forLevel(levelNumber);
    final random = Random(levelNumber * 7919);

    for (var attempt = 0; attempt < 200; attempt++) {
      final layout = _shuffleDeck(recipe, random);
      final tubes = layout
          .map((layers) => Tube(layers: layers, capacity: capacity))
          .toList();

      // Reject a board that is already solved or needs no thought.
      if (GameEngine.isSolved(tubes)) continue;

      if (GameEngine.solve(tubes) != null) {
        return Level(
          number: levelNumber,
          colorCount: recipe.colorCount,
          emptyTubes: recipe.emptyTubes,
          capacity: capacity,
          startLayout: layout,
        );
      }
    }

    // Fallback: give the board one more empty tube, which makes it far easier
    // to solve and to search. A solved board is never returned, so the player
    // always gets something to play.
    final easier =
        LevelRecipe(recipe.colorCount, recipe.emptyTubes + 1);
    for (var attempt = 0; attempt < 200; attempt++) {
      final layout = _shuffleDeck(easier, random);
      final tubes = layout
          .map((layers) => Tube(layers: layers, capacity: capacity))
          .toList();
      if (GameEngine.isSolved(tubes)) continue;
      if (GameEngine.solve(tubes) != null) {
        return Level(
          number: levelNumber,
          colorCount: easier.colorCount,
          emptyTubes: easier.emptyTubes,
          capacity: capacity,
          startLayout: layout,
        );
      }
    }

    // Last resort: an unshuffled-but-playable board built by swapping the top
    // units of adjacent single-colour tubes. Solvable by construction.
    return Level(
      number: levelNumber,
      colorCount: recipe.colorCount,
      emptyTubes: recipe.emptyTubes,
      capacity: capacity,
      startLayout: _nearlySolvedLayout(recipe),
    );
  }

  /// Four units of every colour, dealt out into the filled tubes.
  static List<List<int>> _shuffleDeck(LevelRecipe recipe, Random random) {
    final deck = <int>[
      for (var color = 0; color < recipe.colorCount; color++)
        ...List.filled(capacity, color),
    ]..shuffle(random);

    final layout = <List<int>>[];
    for (var i = 0; i < recipe.colorCount; i++) {
      layout.add(deck.sublist(i * capacity, (i + 1) * capacity));
    }
    for (var i = 0; i < recipe.emptyTubes; i++) {
      layout.add(<int>[]);
    }
    return layout;
  }

  /// A solved board with the top unit of each neighbouring pair swapped, so
  /// it always needs real moves but is trivially solvable.
  static List<List<int>> _nearlySolvedLayout(LevelRecipe recipe) {
    final layout = <List<int>>[
      for (var color = 0; color < recipe.colorCount; color++)
        List.filled(capacity, color),
    ];
    for (var i = 0; i + 1 < layout.length; i += 2) {
      final top = layout[i].last;
      layout[i][capacity - 1] = layout[i + 1].last;
      layout[i + 1][capacity - 1] = top;
    }
    return [
      ...layout,
      for (var i = 0; i < recipe.emptyTubes; i++) <int>[],
    ];
  }

  /// Stars awarded for finishing [level] in [moves].
  ///
  /// The par is the number of moves in the solver's own solution; matching or
  /// beating it is worth three stars.
  static int starsFor(Level level, int moves) {
    final par = _par(level);
    if (moves <= par) return 3;
    if (moves <= (par * 1.5).ceil()) return 2;
    return 1;
  }

  static final _parCache = <int, int>{};

  static int _par(Level level) {
    return _parCache.putIfAbsent(level.number, () {
      final solution = GameEngine.solve(level.buildTubes());
      // Without a solution length, fall back to a generous estimate.
      return solution?.length ?? level.colorCount * 3;
    });
  }
}
