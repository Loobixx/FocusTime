import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();
  static const String _prefMuteKey = 'is_audio_muted';

  final ValueNotifier<bool> isMutedNotifier = ValueNotifier<bool>(false);

  bool get isMuted => isMutedNotifier.value;
  bool _isPlaying = false;

  /// Initialise l'état du son depuis le stockage local et lance la musique si non muet
  Future<void> initAndPlay() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMute = prefs.getBool(_prefMuteKey) ?? false;
    isMutedNotifier.value = savedMute;

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(savedMute ? 0.0 : 0.4);

    if (!savedMute) {
      try {
        await _player.play(AssetSource('audio/ambiance_focus.mp3'));
        _isPlaying = true;
      } catch (_) {
        _isPlaying = false;
      }
    }
  }

  /// Bascule l'état muet et l'enregistre définitivement en local
  Future<void> toggleMute() async {
    final newMuteState = !isMutedNotifier.value;
    isMutedNotifier.value = newMuteState;

    // Sauvegarde sur le téléphone
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefMuteKey, newMuteState);

    if (newMuteState) {
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