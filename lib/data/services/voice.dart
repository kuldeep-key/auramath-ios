import 'package:flutter_tts/flutter_tts.dart';

/// Reads a line aloud. Recorded clips from packs come later; until then, and
/// as their fallback, the phone's own voice reads the text.
abstract interface class Voice {
  Future<void> say(String text);
  Future<void> stop();
}

/// The device's built-in voice: on the phone, no network, no child data out.
class DeviceVoice implements Voice {
  DeviceVoice() {
    _tts.setLanguage('en-AU');
    _tts.setSpeechRate(0.45);
  }

  final _tts = FlutterTts();

  @override
  Future<void> say(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}
