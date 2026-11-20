import '../models/tube.dart';

/// One pour, kept so it can be undone.
class Move {
  final int from;
  final int to;
  final int amount;
  final int color;

  const Move({
    required this.from,
    required this.to,
    required this.amount,
    required this.color,
  });
}

/// The rules of the game. Pure logic, no Flutter — so it can be unit tested
/// and reused by the hint solver.
class GameEngine {
  /// A pour is legal when:
  ///  - source and destination differ,
  ///  - the source has liquid and is not already a finished single-colour tube,
  ///  - the destination has room,
  ///  - the destination is empty or its top colour matches the source's.
  static bool canPour(List<Tube> tubes, int from, int to) {
    if (from == to) return false;
    if (from < 0 || to < 0 || from >= tubes.length || to >= tubes.length) {
      return false;
    }

    final source = tubes[from];
    final destination = tubes[to];

    if (source.isEmpty) return false;
    if (destination.isFull) return false;
    // Pouring a finished tube into an empty one is legal but pointless; it is
    // blocked so hints and the solver never loop on it.
    if (source.isSolvedStack && destination.isEmpty) return false;
    if (destination.isEmpty) return true;
    return destination.topColor == source.topColor;
  }

  /// How much actually moves: the whole top group, capped by the free space.
  static int pourAmount(List<Tube> tubes, int from, int to) {
    if (!canPour(tubes, from, to)) return 0;
    final group = tubes[from].topGroupSize;
    final space = tubes[to].freeSpace;
    return group < space ? group : space;
  }

  /// Applies a pour and returns it, or null when the move is rejected.
  static Move? pour(List<Tube> tubes, int from, int to) {
    final amount = pourAmount(tubes, from, to);
    if (amount == 0) return null;

    final color = tubes[from].topColor!;
    for (var i = 0; i < amount; i++) {
      tubes[from].layers.removeLast();
      tubes[to].layers.add(color);
    }
    return Move(from: from, to: to, amount: amount, color: color);
  }

  /// Puts the liquid back where it came from.
  static void undo(List<Tube> tubes, Move move) {
    for (var i = 0; i < move.amount; i++) {
      tubes[move.to].layers.removeLast();
      tubes[move.from].layers.add(move.color);
    }
  }

  /// Solved when every tube is either empty or full of one colour.
  static bool isSolved(List<Tube> tubes) =>
      tubes.every((tube) => tube.isComplete);

  /// Every legal pour available right now.
  static List<Move> legalMoves(List<Tube> tubes) {
    final moves = <Move>[];
    for (var from = 0; from < tubes.length; from++) {
      for (var to = 0; to < tubes.length; to++) {
        final amount = pourAmount(tubes, from, to);
        if (amount > 0) {
          moves.add(Move(
            from: from,
            to: to,
            amount: amount,
            color: tubes[from].topColor!,
          ));
        }
      }
    }
    return moves;
  }

  /// A canonical string for a position. Tube order does not matter, so the
  /// contents are sorted before joining — that collapses a large number of
  /// equivalent states and keeps the search small.
  static String signature(List<Tube> tubes) {
    final parts = tubes.map((t) => t.layers.join('.')).toList()..sort();
    return parts.join('|');
  }

  /// Depth-first search for a full solution.
  ///
  /// Returns the sequence of moves that solves [tubes], or null if none was
  /// found within [maxStates]. The cap keeps generation and hints responsive;
  /// the generator treats "not found" as "regenerate".
  static List<Move>? solve(List<Tube> tubes, {int maxStates = 120000}) {
    final working = tubes.map((t) => t.copy()).toList();
    final visited = <String>{};
    final path = <Move>[];
    var examined = 0;

    bool search() {
      if (isSolved(working)) return true;
      if (examined++ > maxStates) return false;

      final key = signature(working);
      if (!visited.add(key)) return false;

      final moves = legalMoves(working);
      // Try the moves that finish or empty a tube first; it finds a solution
      // far sooner than plain ordering.
      moves.sort((a, b) => _moveScore(working, b).compareTo(_moveScore(working, a)));

      for (final move in moves) {
        final applied = pour(working, move.from, move.to);
        if (applied == null) continue;
        path.add(applied);
        if (search()) return true;
        path.removeLast();
        undo(working, applied);
      }
      return false;
    }

    return search() ? List<Move>.from(path) : null;
  }

  /// Heuristic used to order candidate moves during the search.
  static int _moveScore(List<Tube> tubes, Move move) {
    var score = 0;
    final source = tubes[move.from];
    final destination = tubes[move.to];

    // Emptying a tube completely is usually progress.
    if (source.topGroupSize == source.layers.length) score += 3;
    // Filling a tube to a finished single colour is progress.
    if (destination.layers.isNotEmpty &&
        destination.freeSpace == move.amount &&
        destination.layers.every((c) => c == move.color)) {
      score += 4;
    }
    // Prefer pouring onto matching liquid over using up an empty tube.
    if (!destination.isEmpty) score += 2;
    return score;
  }

  /// The first move of a winning line from the current position.
  static Move? hint(List<Tube> tubes) {
    final solution = solve(tubes, maxStates: 60000);
    if (solution == null || solution.isEmpty) return null;
    return solution.first;
  }
}
