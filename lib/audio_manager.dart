import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  AudioPlayer? _bgmPlayer;
  AudioPlayer? _sfxPlayer;
  bool _bgmStarted = false;
  bool _disabled = false;
  bool _bgmEnabled = true;
  bool _sfxEnabled = true;

  bool get bgmEnabled => _bgmEnabled;
  bool get sfxEnabled => _sfxEnabled;

  Future<void> setBgmEnabled(bool enabled) async {
    _bgmEnabled = enabled;
    if (!enabled) {
      await stopBgm();
    }
  }

  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
  }

  bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      default:
        return false;
    }
  }

  Future<AudioPlayer?> _ensureBgmPlayer() async {
    if (_disabled || !_isSupportedPlatform) return null;
    if (_bgmPlayer != null) return _bgmPlayer;
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      _bgmPlayer = player;
      return player;
    } on MissingPluginException {
      _disabled = true;
      return null;
    }
  }

  Future<AudioPlayer?> _ensureSfxPlayer() async {
    if (_disabled || !_isSupportedPlatform) return null;
    if (_sfxPlayer != null) return _sfxPlayer;
    try {
      _sfxPlayer = AudioPlayer();
      return _sfxPlayer;
    } on MissingPluginException {
      _disabled = true;
      return null;
    }
  }

  Future<void> startBgm() async {
    if (!_bgmEnabled) return;
    if (_bgmStarted) return;
    final player = await _ensureBgmPlayer();
    if (player == null) return;
    _bgmStarted = true;
    try {
      await player.play(
        AssetSource('background music.mp3'),
        volume: 0.4,
      );
    } on MissingPluginException {
      _disabled = true;
    } on Exception {
      // Ignore missing/invalid asset errors.
    }
  }

  Future<void> stopBgm() async {
    if (!_bgmStarted) return;
    _bgmStarted = false;
    final player = await _ensureBgmPlayer();
    if (player == null) return;
    try {
      await player.stop();
    } on MissingPluginException {
      _disabled = true;
    }
  }

  Future<void> playTap() async {
    if (!_sfxEnabled) return;
    final player = await _ensureSfxPlayer();
    if (player == null) return;
    try {
      await player.play(
        AssetSource('tap.mp3'),
        volume: 1.0,
      );
    } on MissingPluginException {
      _disabled = true;
    } on Exception {
      // Ignore missing/invalid asset errors.
    }
  }

  Future<void> playVictory() async {
    if (!_sfxEnabled) return;
    final player = await _ensureSfxPlayer();
    if (player == null) return;
    try {
      await player.play(
        AssetSource('victory.mp3'),
        volume: 1.0,
      );
    } on MissingPluginException {
      _disabled = true;
    } on Exception {
      // Ignore missing/invalid asset errors.
    }
  }
}
