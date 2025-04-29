// lib/app/data/services/background_music_handler.dart

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class BackgroundMusicHandler {
  static BackgroundMusicHandler? _instance;
  static const String _isMutedKey = 'is_music_muted';
  static const String _volumeKey = 'music_volume';
  static const double _defaultVolume = 0.3;

  static bool isTestMode = false;

  late AudioPlayer _player;
  bool _isMuted = false;
  bool _isInitialized = false;
  double _volume = _defaultVolume;
  bool _isLoading = false;

  // Private constructor for singleton
  BackgroundMusicHandler._();

  // Factory method to get instance
  static BackgroundMusicHandler get instance {
    _instance ??= BackgroundMusicHandler._();
    return _instance!;
  }

  // Initialization
  Future<void> init() async {
    // Якщо це тестове середовище, просто позначаємо як ініційоване
    if (isTestMode || Platform.environment.containsKey('FLUTTER_TEST')) {
      _isInitialized = true;
      return;
    }

    if (_isInitialized || _isLoading) return;

    _isLoading = true;
    try {
      _player = AudioPlayer();

      // Load saved preferences
      final prefs = await SharedPreferences.getInstance();
      _isMuted = prefs.getBool(_isMutedKey) ?? false;
      _volume = prefs.getDouble(_volumeKey) ?? _defaultVolume;

      // Setup audio
      await _player.setAsset('assets/audio/nana.mp3');
      await _player.setLoopMode(LoopMode.all);
      await _player.setVolume(_isMuted ? 0 : _volume);

      // Add error handling
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _player.seek(Duration.zero);
          _player.play();
        }
      }, onError: (error) {
        debugPrint('Audio player error: $error');
        _handlePlaybackError();
      });

      _isInitialized = true;
      debugPrint('BackgroundMusicHandler initialized successfully');
    } catch (e) {
      debugPrint('Error initializing BackgroundMusicHandler: $e');
      _isInitialized = false;
      await _handleInitializationError();
    } finally {
      _isLoading = false;
    }
  }

  bool get isMuted => _isMuted;
  bool get isInitialized => _isInitialized;
  double get volume => _volume;

  Future<void> play() async {
    // Для тестового середовища - порожня реалізація
    if (isTestMode || Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    if (!_isInitialized) {
      await init();
    }

    try {
      if (!_player.playing) {
        await _player.play();
        debugPrint('Background music started playing');
      }
    } catch (e) {
      debugPrint('Error playing music: $e');
      await _handlePlaybackError();
    }
  }

  Future<void> stop() async {
    // Для тестового середовища - порожня реалізація
    if (isTestMode || Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    if (!_isInitialized) return;

    try {
      await _player.stop();
      debugPrint('Background music stopped');
    } catch (e) {
      debugPrint('Error stopping music: $e');
    }
  }

  Future<void> pause() async {
    // Для тестового середовища - порожня реалізація
    if (isTestMode || Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    if (!_isInitialized) return;

    try {
      await _player.pause();
      debugPrint('Background music paused');
    } catch (e) {
      debugPrint('Error pausing music: $e');
    }
  }

  Future<void> toggleMute() async {
    // Для тестового середовища - порожня реалізація
    if (isTestMode || Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    if (!_isInitialized) {
      await init();
    }

    try {
      _isMuted = !_isMuted;
      await _player.setVolume(_isMuted ? 0 : _volume);

      // Save state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isMutedKey, _isMuted);

      debugPrint('Music ${_isMuted ? 'muted' : 'unmuted'}');
    } catch (e) {
      debugPrint('Error toggling mute: $e');
    }
  }

  Future<void> setVolume(double value) async {
    // Для тестового середовища - порожня реалізація
    if (isTestMode || Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    if (!_isInitialized) {
      await init();
    }

    try {
      _volume = value.clamp(0.0, 1.0);
      if (!_isMuted) {
        await _player.setVolume(_volume);
      }

      // Save volume setting
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_volumeKey, _volume);

      debugPrint('Music volume set to: $_volume');
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  Future<void> _handlePlaybackError() async {
    // Для тестового середовища - порожня реалізація
    if (isTestMode || Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    try {
      await _player.stop();
      await _player.dispose();
      _player = AudioPlayer();
      await init();
    } catch (e) {
      debugPrint('Error handling playback error: $e');
    }
  }

  Future<void> _handleInitializationError() async {
    // Для тестового середовища - порожня реалізація
    if (isTestMode || Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    try {
      _player = AudioPlayer();
      await Future.delayed(const Duration(seconds: 2));
      await init();
    } catch (e) {
      debugPrint('Error handling initialization error: $e');
    }
  }

  Future<void> dispose() async {
    // Для тестового середовища - мінімальна реалізація
    if (isTestMode || Platform.environment.containsKey('FLUTTER_TEST')) {
      _isInitialized = false;
      return;
    }

    if (_isInitialized) {
      try {
        await stop();
        await _player.dispose();
        _isInitialized = false;
        debugPrint('BackgroundMusicHandler disposed');
      } catch (e) {
        debugPrint('Error disposing BackgroundMusicHandler: $e');
      }
    }
  }
}