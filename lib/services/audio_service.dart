import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();
  
  // Notifier pour mettre à jour l'interrupteur dans l'UI
  final ValueNotifier<bool> isMutedNotifier = ValueNotifier<bool>(false);

  bool get isMuted => isMutedNotifier.value;
  bool _isPlaying = false;

  Future<void> initAndPlay() async {
    if (_isPlaying) return;

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(isMutedNotifier.value ? 0.0 : 0.4);

    try {
      await _player.play(AssetSource('audio/ambiance_focus.mp3'));
      _isPlaying = true;
    } catch (_) {
      _isPlaying = false;
    }
  }

  Future<void> toggleMute() async {
    isMutedNotifier.value = !isMutedNotifier.value;
    if (isMutedNotifier.value) {
      await _player.setVolume(0.0);
    } else {
      await _player.setVolume(0.4);
      if (!_isPlaying) {
        await _player.resume();
        _isPlaying = true;
      }
    }
  }
}