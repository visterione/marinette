import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marinette/app/data/services/user_preferences_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AudioService extends GetxService {
  AudioPlayer? _player;
  final _isPlaying = false.obs;
  final _isMuted = false.obs;
  final _isInitialized = false.obs;
  final UserPreferencesService _prefs = Get.find<UserPreferencesService>();

  static const String _bgMusicPath = 'assets/audio/nana.mp3';
  static const String _isMusicEnabledKey = 'is_music_enabled';
  static const double _defaultVolume =
      0.3; // Зменшили гучність за замовчуванням

  Future<AudioService> init() async {
    try {
      _player = AudioPlayer();

      // Налаштовуємо аудіо з обробкою помилок
      try {
        await _player?.setAsset(_bgMusicPath);
        await _player?.setLoopMode(LoopMode.all);
        await _player?.setVolume(_defaultVolume);
        _isInitialized.value = true;

        // Відновлюємо останній стан музики
        final isMusicEnabled = await _prefs.getBool(_isMusicEnabledKey) ?? true;
        if (isMusicEnabled) {
          await play();
        }
      } catch (e) {
        debugPrint('Error configuring audio player: $e');
        _isInitialized.value = false;
      }
    } catch (e) {
      debugPrint('Error creating audio player: $e');
      _isInitialized.value = false;
    }
    return this;
  }

  bool get isPlaying => _isPlaying.value;
  bool get isMuted => _isMuted.value;
  bool get isInitialized => _isInitialized.value;

  Future<void> play() async {
    if (!_isInitialized.value || _player == null) return;

    try {
      await _player?.play();
      _isPlaying.value = true;
      await _prefs.setBool(_isMusicEnabledKey, true);
    } catch (e) {
      debugPrint('Error playing music: $e');
    }
  }

  Future<void> pause() async {
    if (!_isInitialized.value || _player == null) return;

    try {
      await _player?.pause();
      _isPlaying.value = false;
      await _prefs.setBool(_isMusicEnabledKey, false);
    } catch (e) {
      debugPrint('Error pausing music: $e');
    }
  }

  Future<void> toggle() async {
    if (!_isInitialized.value) return;

    if (_isPlaying.value) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> mute() async {
    if (!_isInitialized.value || _player == null) return;

    try {
      await _player?.setVolume(0);
      _isMuted.value = true;
    } catch (e) {
      debugPrint('Error muting music: $e');
    }
  }

  Future<void> unmute() async {
    if (!_isInitialized.value || _player == null) return;

    try {
      await _player?.setVolume(_defaultVolume);
      _isMuted.value = false;
    } catch (e) {
      debugPrint('Error unmuting music: $e');
    }
  }

  Future<void> toggleMute() async {
    if (!_isInitialized.value) return;

    if (_isMuted.value) {
      await unmute();
    } else {
      await mute();
    }
  }

  Future<void> setVolume(double volume) async {
    if (!_isInitialized.value || _player == null) return;

    try {
      await _player?.setVolume(volume);
      _isMuted.value = volume == 0;
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  @override
  void onClose() {
    _player?.dispose();
    super.onClose();
  }
}
