import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

/// Sound effect names, matching the files in assets/audio.
enum Sfx { click, select, pour, invalid, complete, victory }

/// Background music and sound effects.
///
/// Every call is guarded: on a device or emulator without working audio the
/// game must keep playing rather than throw.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final _music = AudioPlayer();
  final _effects = AudioPlayer();

  bool musicOn = true;
  bool soundOn = true;
  bool vibrationOn = true;

  bool _musicPlaying = false;
  bool? _hasVibrator;

  static const _files = <Sfx, String>{
    Sfx.click: 'audio/click.wav',
    Sfx.select: 'audio/select.wav',
    Sfx.pour: 'audio/pour.wav',
    Sfx.invalid: 'audio/invalid.wav',
    Sfx.complete: 'audio/complete.wav',
    Sfx.victory: 'audio/victory.wav',
  };

  Future<void> init() async {
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(0.35);
      await _effects.setVolume(0.9);
    } catch (error) {
      debugPrint('Audio unavailable: $error');
    }
  }

  Future<void> startMusic() async {
    if (!musicOn || _musicPlaying) return;
    try {
      await _music.play(AssetSource('audio/music.wav'));
      _musicPlaying = true;
    } catch (error) {
      debugPrint('Music could not start: $error');
    }
  }

  Future<void> stopMusic() async {
    try {
      await _music.stop();
    } catch (error) {
      debugPrint('Music could not stop: $error');
    }
    _musicPlaying = false;
  }

  Future<void> setMusicEnabled(bool value) async {
    musicOn = value;
    if (value) {
      await startMusic();
    } else {
      await stopMusic();
    }
  }

  Future<void> play(Sfx effect) async {
    if (!soundOn) return;
    try {
      await _effects.stop();
      await _effects.play(AssetSource(_files[effect]!));
    } catch (error) {
      debugPrint('Sound effect failed: $error');
    }
  }

  /// Short haptic tick. [strong] is used for invalid moves and wins.
  Future<void> buzz({bool strong = false}) async {
    if (!vibrationOn) return;
    try {
      _hasVibrator ??= await Vibration.hasVibrator();
      if (_hasVibrator != true) return;
      await Vibration.vibrate(duration: strong ? 120 : 25);
    } catch (error) {
      debugPrint('Vibration unavailable: $error');
    }
  }

  Future<void> dispose() async {
    await _music.dispose();
    await _effects.dispose();
  }
}
