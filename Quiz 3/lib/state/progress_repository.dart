import 'package:shared_preferences/shared_preferences.dart';

/// Everything the game remembers between runs, stored in SharedPreferences.
///
/// Keeps current level, which levels are unlocked, stars earned and the best
/// move count per level, plus the audio and vibration preferences.
class ProgressRepository {
  ProgressRepository._();
  static final ProgressRepository instance = ProgressRepository._();

  static const _kCurrentLevel = 'current_level';
  static const _kUnlocked = 'unlocked_levels';
  static const _kStars = 'stars_level_';
  static const _kBestMoves = 'best_moves_level_';
  static const _kMusic = 'music_on';
  static const _kSound = 'sound_on';
  static const _kVibration = 'vibration_on';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ------------------------------------------------------------- progress

  Future<int> currentLevel() async => (await _store).getInt(_kCurrentLevel) ?? 1;

  Future<void> setCurrentLevel(int level) async =>
      (await _store).setInt(_kCurrentLevel, level);

  /// Highest level the player may open. Level 1 is always available.
  Future<int> unlockedLevel() async => (await _store).getInt(_kUnlocked) ?? 1;

  Future<void> unlockLevel(int level) async {
    final store = await _store;
    if (level > (store.getInt(_kUnlocked) ?? 1)) {
      await store.setInt(_kUnlocked, level);
    }
  }

  Future<int> starsFor(int level) async =>
      (await _store).getInt('$_kStars$level') ?? 0;

  /// Stars only ever go up, so replaying a level cannot lose a rating.
  Future<void> recordStars(int level, int stars) async {
    final store = await _store;
    final key = '$_kStars$level';
    if (stars > (store.getInt(key) ?? 0)) await store.setInt(key, stars);
  }

  Future<int?> bestMovesFor(int level) async =>
      (await _store).getInt('$_kBestMoves$level');

  Future<void> recordMoves(int level, int moves) async {
    final store = await _store;
    final key = '$_kBestMoves$level';
    final best = store.getInt(key);
    if (best == null || moves < best) await store.setInt(key, moves);
  }

  Future<Map<int, int>> allStars(int totalLevels) async {
    final store = await _store;
    return {
      for (var level = 1; level <= totalLevels; level++)
        level: store.getInt('$_kStars$level') ?? 0,
    };
  }

  Future<void> resetProgress(int totalLevels) async {
    final store = await _store;
    for (var level = 1; level <= totalLevels; level++) {
      await store.remove('$_kStars$level');
      await store.remove('$_kBestMoves$level');
    }
    await store.setInt(_kCurrentLevel, 1);
    await store.setInt(_kUnlocked, 1);
  }

  // ------------------------------------------------------------- settings

  Future<bool> musicOn() async => (await _store).getBool(_kMusic) ?? true;
  Future<bool> soundOn() async => (await _store).getBool(_kSound) ?? true;
  Future<bool> vibrationOn() async =>
      (await _store).getBool(_kVibration) ?? true;

  Future<void> setMusic(bool value) async =>
      (await _store).setBool(_kMusic, value);
  Future<void> setSound(bool value) async =>
      (await _store).setBool(_kSound, value);
  Future<void> setVibration(bool value) async =>
      (await _store).setBool(_kVibration, value);
}
