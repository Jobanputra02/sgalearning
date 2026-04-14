import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class AudioService {
  static AudioPlayer? _playerA;
  static AudioPlayer? _playerB;
  static AudioPlayer? _playerFeedback;

  static bool _sessionInitialized = false;

  // Each play session gets a unique ID
  // If ID changes mid-playback, that play is cancelled
  static int _currentPlayId = 0;

  static Future<void> initSession() async {
    if (_sessionInitialized) return;
    final session = await AudioSession.instance;
    await session.configure(
        const AudioSessionConfiguration.music());
    _playerA        = AudioPlayer();
    _playerB        = AudioPlayer();
    _playerFeedback = AudioPlayer();
    _sessionInitialized = true;
  }

  static Future<void> preloadQuestion(
      String assetA, String assetB) async {
    await initSession();
    try {
      await Future.wait([
        _playerA!.setAsset(assetA),
        _playerB!.setAsset(assetB),
      ]);
      await Future.wait([
        _playerA!.seek(Duration.zero),
        _playerB!.seek(Duration.zero),
      ]);
    } catch (e) {
      // ignore
    }
  }

  // Melodic — sequential, cancellable via play ID
  static Future<void> playMelodic() async {
    // Increment ID — any previous playMelodic will see ID mismatch
    final myId = ++_currentPlayId;

    try {
      // Stop anything currently playing
      try { await _playerA?.stop(); } catch (_) {}
      try { await _playerB?.stop(); } catch (_) {}

      await Future.wait([
        _playerA!.seek(Duration.zero),
        _playerB!.seek(Duration.zero),
      ]);

      if (_currentPlayId != myId) return; // cancelled

      final durationA =
          _playerA!.duration ?? const Duration(milliseconds: 800);

      _playerA!.play();

      await Future.delayed(
          durationA + const Duration(milliseconds: 150));

      if (_currentPlayId != myId) return; // cancelled before B

      await _playerA!.stop();

      if (_currentPlayId != myId) return; // double check

      _playerB!.play();

      final durationB =
          _playerB!.duration ?? const Duration(milliseconds: 800);
      await Future.delayed(durationB);

    } catch (e) {
      // ignore
    }
  }

  // Harmonic — simultaneous
  static Future<void> playHarmonic() async {
    final myId = ++_currentPlayId;

    try {
      try { await _playerA?.stop(); } catch (_) {}
      try { await _playerB?.stop(); } catch (_) {}

      await Future.wait([
        _playerA!.seek(Duration.zero),
        _playerB!.seek(Duration.zero),
      ]);

      if (_currentPlayId != myId) return;

      _playerA!.play();
      _playerB!.play();

      final durationA =
          _playerA!.duration ?? const Duration(milliseconds: 800);
      await Future.delayed(durationA);
    } catch (e) {
      // ignore
    }
  }

  // Feedback — completely independent, never cancelled
  static Future<void> playFeedback(bool isCorrect) async {
    try {
      _playerFeedback ??= AudioPlayer();
      final path = isCorrect
          ? 'assets/audio/right.mp3'
          : 'assets/audio/wrong.mp3';
      await _playerFeedback!.setAsset(path);
      await _playerFeedback!.seek(Duration.zero);
      _playerFeedback!.play();
    } catch (e) {
      // ignore
    }
  }

  // Stop notes — increments ID so any active playMelodic exits
  static Future<void> stopNotes() async {
    _currentPlayId++; // invalidate any running play session
    try { await _playerA?.stop(); } catch (_) {}
    try { await _playerB?.stop(); } catch (_) {}
  }

  static Future<void> stop() async {
    _currentPlayId++;
    try { await _playerA?.stop();        } catch (_) {}
    try { await _playerB?.stop();        } catch (_) {}
    try { await _playerFeedback?.stop(); } catch (_) {}
  }

  static Future<void> releaseAll() async {
    _currentPlayId++;
    try { await _playerA?.dispose();        } catch (_) {}
    try { await _playerB?.dispose();        } catch (_) {}
    try { await _playerFeedback?.dispose(); } catch (_) {}
    _playerA        = null;
    _playerB        = null;
    _playerFeedback = null;
    _sessionInitialized = false;
  }

  // Single note for note identification
  static Future<void> playNote(String assetPath) async {
    try {
      await _playerA?.seek(Duration.zero);
      _playerA?.play();
      final duration = _playerA?.duration ?? const Duration(milliseconds: 800);
      await Future.delayed(duration);
    } catch (e) {}
  }
}