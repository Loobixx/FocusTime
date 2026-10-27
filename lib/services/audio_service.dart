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
  bool _isStarting = false;

  /// Initialise l'état du son depuis le stockage local et lance la musique si non muet
  Future<void> initAndPlay() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMute = prefs.getBool(_prefMuteKey) ?? false;
    isMutedNotifier.value = savedMute;

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(savedMute ? 0.0 : 0.4);

    // 🔇 Sur le Web, on ne lance pas la musique tant que l'utilisateur n'a pas interagi
    if (kIsWeb) return;

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
    await setMuted(!isMutedNotifier.value);
  }

  /// Définit explicitement l'état de la musique et l'enregistre en local.
  Future<void> setMuted(bool muted) async {
    final changed = isMutedNotifier.value != muted;
    if (changed) {
      isMutedNotifier.value = muted;
    }

    try {
      // Demarre play immédiatement, avant les accès asynchrones aux préférences,
      // pour respecter l'activation utilisateur exigée par les navigateurs.
      final playback = muted ? null : _startPlaybackIfNeeded();
      final volumeChange = _player.setVolume(muted ? 0.0 : 0.4);

      if (changed) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefMuteKey, muted);
      }

      await volumeChange;
      if (playback != null) await playback;
    } catch (error) {
      debugPrint('Impossible de modifier la musique : $error');
    }
  }

  /// Démarre la musique après une interaction utilisateur si elle est activée.
  Future<void> ensurePlaying() async {
    if (isMutedNotifier.value) return;
    try {
      final playback = _startPlaybackIfNeeded();
      final volumeChange = _player.setVolume(0.4);
      await volumeChange;
      await playback;
    } catch (error) {
      debugPrint('Impossible de démarrer la musique : $error');
    }
  }

  Future<void> _startPlaybackIfNeeded() async {
    if (_isPlaying || _isStarting) return;
    _isStarting = true;
    try {
      final playback = _player.play(AssetSource('audio/ambiance_focus.mp3'));
      await playback;
      _isPlaying = true;
    } catch (error) {
      _isPlaying = false;
      debugPrint('Impossible de démarrer la musique : $error');
    } finally {
      _isStarting = false;
    }
  }
}
