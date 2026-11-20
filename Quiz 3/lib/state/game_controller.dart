import 'package:flutter/foundation.dart';

import '../game/game_engine.dart';
import '../game/level_generator.dart';
import '../models/level.dart';
import '../models/tube.dart';
import '../services/audio_service.dart';
import 'progress_repository.dart';

/// A pour that has been accepted but is still animating.
///
/// The board is only mutated once the animation reports back, so what the
/// player sees and what the engine holds never drift apart.
class PendingPour {
  final int from;
  final int to;
  final int amount;
  final int color;

  const PendingPour({
    required this.from,
    required this.to,
    required this.amount,
    required this.color,
  });
}

/// Drives one playthrough of a level.
class GameController extends ChangeNotifier {
  final _repository = ProgressRepository.instance;
  final _audio = AudioService.instance;

  late Level level;
  late List<Tube> tubes;

  final _history = <Move>[];

  int? selectedTube;
  PendingPour? pendingPour;

  int moves = 0;
  bool won = false;
  int starsEarned = 0;
  int? bestMoves;

  /// Extra tubes the player added this attempt, capped so the board stays
  /// readable and the level cannot be trivialised.
  int addedTubes = 0;
  static const maxAddedTubes = 2;

  /// The move the hint button is pointing at, highlighted on the board.
  Move? hintMove;
  bool hintSearching = false;

  bool get canUndo => _history.isNotEmpty && !won;
  bool get canAddTube => addedTubes < maxAddedTubes && !won;
  bool get isBusy => pendingPour != null;

  // ------------------------------------------------------------ lifecycle

  Future<void> loadLevel(int levelNumber) async {
    level = LevelGenerator.generate(levelNumber);
    _resetBoard();
    bestMoves = await _repository.bestMovesFor(levelNumber);
    await _repository.setCurrentLevel(levelNumber);
    notifyListeners();
  }

  void _resetBoard() {
    tubes = level.buildTubes();
    _history.clear();
    selectedTube = null;
    pendingPour = null;
    hintMove = null;
    moves = 0;
    won = false;
    starsEarned = 0;
    addedTubes = 0;
  }

  /// Restart puts the original arrangement back, including removing any extra
  /// tubes the player added.
  void restart() {
    _audio.play(Sfx.click);
    _resetBoard();
    notifyListeners();
  }

  // ------------------------------------------------------------ gameplay

  /// Handles a tap on tube [index]: picks a source, swaps the source, pours,
  /// or deselects.
  void tapTube(int index) {
    if (won || isBusy) return;
    hintMove = null;

    final current = selectedTube;

    if (current == null) {
      if (tubes[index].isEmpty) {
        _audio.play(Sfx.invalid);
        return;
      }
      selectedTube = index;
      _audio.play(Sfx.select);
      _audio.buzz();
      notifyListeners();
      return;
    }

    // Tapping the selected tube again puts it back down.
    if (current == index) {
      selectedTube = null;
      _audio.play(Sfx.click);
      notifyListeners();
      return;
    }

    if (GameEngine.canPour(tubes, current, index)) {
      final amount = GameEngine.pourAmount(tubes, current, index);
      pendingPour = PendingPour(
        from: current,
        to: index,
        amount: amount,
        color: tubes[current].topColor!,
      );
      selectedTube = null;
      _audio.play(Sfx.pour);
      notifyListeners();
      return;
    }

    // Not a legal destination: treat a non-empty tube as a new selection,
    // otherwise reject the move.
    if (tubes[index].isNotEmptyTube) {
      selectedTube = index;
      _audio.play(Sfx.select);
    } else {
      selectedTube = null;
      _audio.play(Sfx.invalid);
      _audio.buzz(strong: true);
    }
    notifyListeners();
  }

  /// Called by the view when the pouring animation has finished.
  Future<void> finishPour() async {
    final pour = pendingPour;
    if (pour == null) return;

    final move = GameEngine.pour(tubes, pour.from, pour.to);
    pendingPour = null;

    if (move != null) {
      _history.add(move);
      moves++;

      if (tubes[pour.to].isSolvedStack) {
        _audio.play(Sfx.complete);
        _audio.buzz();
      }
    }

    if (GameEngine.isSolved(tubes)) {
      await _handleWin();
    }
    notifyListeners();
  }

  void undo() {
    if (!canUndo || isBusy) return;
    final move = _history.removeLast();
    GameEngine.undo(tubes, move);
    moves = moves > 0 ? moves - 1 : 0;
    selectedTube = null;
    hintMove = null;
    _audio.play(Sfx.click);
    notifyListeners();
  }

  /// Adds one empty tube as temporary storage.
  void addTube() {
    if (!canAddTube || isBusy) return;
    tubes.add(Tube(capacity: level.capacity));
    addedTubes++;
    _audio.play(Sfx.click);
    notifyListeners();
  }

  /// Asks the solver for a move worth making and highlights it.
  Future<void> requestHint() async {
    if (won || isBusy || hintSearching) return;
    hintSearching = true;
    notifyListeners();

    // The search is fast for these board sizes, but yielding first keeps the
    // button feedback immediate.
    await Future<void>.delayed(const Duration(milliseconds: 16));
    final move = GameEngine.hint(tubes);

    hintSearching = false;
    hintMove = move;
    selectedTube = null;
    _audio.play(move == null ? Sfx.invalid : Sfx.click);
    notifyListeners();
  }

  Future<void> _handleWin() async {
    won = true;
    selectedTube = null;
    hintMove = null;
    starsEarned = LevelGenerator.starsFor(level, moves);

    _audio.play(Sfx.victory);
    _audio.buzz(strong: true);

    await _repository.recordStars(level.number, starsEarned);
    await _repository.recordMoves(level.number, moves);
    bestMoves = await _repository.bestMovesFor(level.number);

    if (level.number < LevelRecipe.totalLevels) {
      await _repository.unlockLevel(level.number + 1);
      await _repository.setCurrentLevel(level.number + 1);
    }
  }
}

extension on Tube {
  bool get isNotEmptyTube => !isEmpty;
}
