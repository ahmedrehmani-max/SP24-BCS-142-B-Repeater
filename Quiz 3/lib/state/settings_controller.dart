import 'package:flutter/foundation.dart';

import '../services/audio_service.dart';
import 'progress_repository.dart';

/// Music / sound / vibration switches, persisted and applied to the audio
/// service as soon as they change.
class SettingsController extends ChangeNotifier {
  final _repository = ProgressRepository.instance;
  final _audio = AudioService.instance;

  bool musicOn = true;
  bool soundOn = true;
  bool vibrationOn = true;

  Future<void> load() async {
    musicOn = await _repository.musicOn();
    soundOn = await _repository.soundOn();
    vibrationOn = await _repository.vibrationOn();

    _audio.musicOn = musicOn;
    _audio.soundOn = soundOn;
    _audio.vibrationOn = vibrationOn;
    notifyListeners();
  }

  Future<void> setMusic(bool value) async {
    musicOn = value;
    notifyListeners();
    await _repository.setMusic(value);
    await _audio.setMusicEnabled(value);
  }

  Future<void> setSound(bool value) async {
    soundOn = value;
    _audio.soundOn = value;
    notifyListeners();
    await _repository.setSound(value);
  }

  Future<void> setVibration(bool value) async {
    vibrationOn = value;
    _audio.vibrationOn = value;
    notifyListeners();
    await _repository.setVibration(value);
  }
}
