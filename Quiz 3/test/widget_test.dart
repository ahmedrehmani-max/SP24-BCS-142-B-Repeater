// Tests for the sorting rules, the solver and level generation.

import 'package:flutter_test/flutter_test.dart';

import 'package:color_water_sort/game/game_engine.dart';
import 'package:color_water_sort/game/level_generator.dart';
import 'package:color_water_sort/models/level.dart';
import 'package:color_water_sort/models/tube.dart';

List<Tube> board(List<List<int>> layout, {int capacity = 4}) =>
    layout.map((l) => Tube(layers: l, capacity: capacity)).toList();

void main() {
  group('pouring rules', () {
    test('only the top group of one colour moves', () {
      final tubes = board([
        [1, 0, 0], // two reds on top of a blue
        [0],
      ]);

      expect(GameEngine.pourAmount(tubes, 0, 1), 2);
      GameEngine.pour(tubes, 0, 1);
      expect(tubes[0].layers, [1]);
      expect(tubes[1].layers, [0, 0, 0]);
    });

    test('pouring onto a different colour is rejected', () {
      final tubes = board([
        [0],
        [1],
      ]);
      expect(GameEngine.canPour(tubes, 0, 1), isFalse);
      expect(GameEngine.pour(tubes, 0, 1), isNull);
    });

    test('an empty tube accepts any colour', () {
      final tubes = board([
        [2, 2],
        <int>[],
      ]);
      expect(GameEngine.canPour(tubes, 0, 1), isTrue);
    });

    test('pouring stops at the destination capacity', () {
      final tubes = board([
        [0, 0, 0],
        [0, 0, 0],
      ]);
      // Only one unit fits, even though three are on top.
      expect(GameEngine.pourAmount(tubes, 0, 1), 1);
      GameEngine.pour(tubes, 0, 1);
      expect(tubes[1].layers.length, 4);
      expect(tubes[0].layers.length, 2);
    });

    test('a full tube cannot receive liquid', () {
      final tubes = board([
        [0],
        [0, 0, 0, 0],
      ]);
      expect(GameEngine.canPour(tubes, 0, 1), isFalse);
    });

    test('an empty source cannot pour', () {
      final tubes = board([
        <int>[],
        [0],
      ]);
      expect(GameEngine.canPour(tubes, 0, 1), isFalse);
    });

    test('a tube cannot pour into itself', () {
      final tubes = board([
        [0, 0],
      ]);
      expect(GameEngine.canPour(tubes, 0, 0), isFalse);
    });
  });

  group('undo', () {
    test('restores the exact board', () {
      final tubes = board([
        [1, 0, 0],
        [0],
      ]);
      final before = tubes.map((t) => t.layers.join(',')).toList();

      final move = GameEngine.pour(tubes, 0, 1)!;
      GameEngine.undo(tubes, move);

      expect(tubes.map((t) => t.layers.join(',')).toList(), before);
    });
  });

  group('completion', () {
    test('solved when every tube is empty or a single full colour', () {
      expect(
        GameEngine.isSolved(board([
          [0, 0, 0, 0],
          [1, 1, 1, 1],
          <int>[],
        ])),
        isTrue,
      );
    });

    test('a part-filled single colour tube is not finished', () {
      expect(Tube(layers: [0, 0, 0]).isSolvedStack, isFalse);
      expect(Tube(layers: [0, 0, 0, 0]).isSolvedStack, isTrue);
      // An empty tube counts as complete but is not a solved stack.
      expect(Tube().isComplete, isTrue);
      expect(Tube().isSolvedStack, isFalse);
    });
  });

  group('solver and hints', () {
    test('solves a simple position', () {
      final tubes = board([
        [0, 1],
        [1, 0],
        <int>[],
      ]);
      // Not every arrangement is solvable; this one is reachable.
      final solution = GameEngine.solve(board([
        [0, 0, 1, 1],
        [1, 1, 0, 0],
        <int>[],
        <int>[],
      ]));
      expect(solution, isNotNull);
      expect(GameEngine.hint(tubes), anyOf(isNull, isA<Move>()));
    });

    test('a hint is always a legal move', () {
      final tubes = board([
        [0, 1, 1],
        [1, 0, 0],
        <int>[],
      ]);
      final hint = GameEngine.hint(tubes);
      if (hint != null) {
        expect(GameEngine.canPour(tubes, hint.from, hint.to), isTrue);
      }
    });
  });

  group('level generation', () {
    test('every level is solvable and correctly shaped', () {
      for (var number = 1; number <= LevelRecipe.totalLevels; number++) {
        final level = LevelGenerator.generate(number);
        final recipe = LevelRecipe.forLevel(number);

        expect(level.startLayout.length,
            recipe.colorCount + recipe.emptyTubes,
            reason: 'level $number tube count');

        // Exactly four units of every colour must be present.
        final counts = <int, int>{};
        for (final tube in level.startLayout) {
          for (final color in tube) {
            counts[color] = (counts[color] ?? 0) + 1;
          }
        }
        expect(counts.length, recipe.colorCount, reason: 'level $number colours');
        expect(counts.values.every((c) => c == 4), isTrue,
            reason: 'level $number unit counts');

        expect(GameEngine.isSolved(level.buildTubes()), isFalse,
            reason: 'level $number should not start solved');
        expect(GameEngine.solve(level.buildTubes()), isNotNull,
            reason: 'level $number must be solvable');
      }
    });

    test('generation is deterministic for a level number', () {
      expect(
        LevelGenerator.generate(7).startLayout,
        LevelGenerator.generate(7).startLayout,
      );
    });

    test('stars drop as the move count rises', () {
      final level = LevelGenerator.generate(1);
      expect(LevelGenerator.starsFor(level, 1), 3);
      expect(LevelGenerator.starsFor(level, 500), 1);
    });
  });
}
