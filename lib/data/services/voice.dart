import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Reads a line aloud. Recorded clips from packs come later; until then, and
/// as their fallback, the phone's own voice reads the text.
abstract interface class Voice {
  Future<void> say(String text);
  Future<void> stop();

  /// True once the phone's voice failed to speak: the lesson says so
  /// (NoVoice 659:39) and shows its words big instead.
  ValueListenable<bool> get resting;
}

/// The device's built-in voice: on the phone, no network, no child data out.
class DeviceVoice implements Voice {
  DeviceVoice() {
    _tts.setLanguage('en-AU');
    _tts.setSpeechRate(0.45);
    _tts.setErrorHandler((_) => resting.value = true);
  }

  final _tts = FlutterTts();

  @override
  final ValueNotifier<bool> resting = ValueNotifier(false);

  @override
  Future<void> say(String text) async {
    try {
      await _tts.stop();
      // 1 is success on both platforms
      if (await _tts.speak(text) != 1) resting.value = true;
    } on PlatformException {
      resting.value = true;
    }
  }

  @override
  Future<void> stop() => _tts.stop();
}
