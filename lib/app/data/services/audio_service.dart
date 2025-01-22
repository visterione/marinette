import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundMusicHandler {
  static BackgroundMusicHandler? _instance;
  static const String _isMutedKey = 'is_music_muted';

  late AudioPlayer _player;
  bool _isMuted = false;
  bool _isInitialized = false;

  // Приватний конструктор для singleton
  BackgroundMusicHandler._() {
    _init();
  }

  // Фабричний метод для отримання instance
  static BackgroundMusicHandler get instance {
    _instance ??= BackgroundMusicHandler._();
    return _instance!;
  }

  // Ініціалізація
  Future<void> _init() async {
    try {
      _player = AudioPlayer();
      await _player.setAsset('assets/audio/nana.mp3');
      await _player.setLoopMode(LoopMode.all);

      // Відновлюємо стан звуку
      final prefs = await SharedPreferences.getInstance();
      _isMuted = prefs.getBool(_isMutedKey) ?? false;

      if (_isMuted) {
        await _player.setVolume(0);
      } else {
        await _player.setVolume(0.3);
      }

      _isInitialized = true;
      debugPrint('BackgroundMusicHandler initialized successfully');
    } catch (e) {
      debugPrint('Error initializing BackgroundMusicHandler: $e');
      _isInitialized = false;
    }
  }

  bool get isMuted => _isMuted;
  bool get isInitialized => _isInitialized;

  Future<void> play() async {
    if (!_isInitialized) return;
    try {
      await _player.play();
    } catch (e) {
      debugPrint('Error playing music: $e');
    }
  }

  Future<void> stop() async {
    if (!_isInitialized) return;
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('Error stopping music: $e');
    }
  }

  Future<void> toggleMute() async {
    if (!_isInitialized) return;
    try {
      _isMuted = !_isMuted;
      await _player.setVolume(_isMuted ? 0 : 0.3);

      // Зберігаємо стан
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isMutedKey, _isMuted);
    } catch (e) {
      debugPrint('Error toggling mute: $e');
    }
  }

  // Очищення ресурсів
  Future<void> dispose() async {
    if (_isInitialized) {
      await stop();
      await _player.dispose();
      _isInitialized = false;
    }
  }
}
