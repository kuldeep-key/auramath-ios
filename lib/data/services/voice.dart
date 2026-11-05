import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'api.dart';

/// Reads a line aloud: the case partner's voice from the server
/// ([CloudVoice]), and the phone's own voice ([DeviceVoice]) whenever that
/// is off, slow or refuses a line.
abstract interface class Voice {
  Future<void> say(String text);
  Future<void> stop();

  /// Lines the child is about to hear: a voice that takes time to make a
  /// line starts them now. Never throws.
  Future<void> warm(List<String> lines);

  /// True once the phone's voice failed to speak: the lesson says so
  /// (NoVoice 659:39) and shows its words big instead.
  ValueListenable<bool> get resting;

  /// True while a line is being read: the speak button glows.
  ValueListenable<bool> get speaking;
}

/// The device's built-in voice: on the phone, no network, no child data out.
class DeviceVoice implements Voice {
  DeviceVoice() {
    _tts.setLanguage('en-AU');
    _tts.setSpeechRate(0.45);
    // a touch brighter than the phone's default, for 6-10 year olds
    _tts.setPitch(1.1);
    _tts
      ..setErrorHandler((_) {
        speaking.value = false;
        resting.value = true;
      })
      ..setStartHandler(() => speaking.value = true)
      ..setCompletionHandler(() => speaking.value = false)
      ..setCancelHandler(() => speaking.value = false);
    _pickBestVoice();
  }

  final _tts = FlutterTts();

  @override
  final ValueNotifier<bool> resting = ValueNotifier(false);

  @override
  final ValueNotifier<bool> speaking = ValueNotifier(false);

  /// The best installed English voice: Australian first, and on iPhone a
  /// premium or enhanced one when the phone has it. Keeps the phone's
  /// default when it lists none.
  Future<void> _pickBestVoice() async {
    try {
      final listed = await _tts.getVoices;
      if (listed is! List) return;
      final voices = listed.whereType<Map>().toList();
      int rank(Map v) {
        final locale = '${v['locale']}'.replaceAll('_', '-');
        final quality = '${v['quality'] ?? ''}';
        final where = switch (locale) {
          'en-AU' => 0,
          'en-GB' => 1,
          'en-NZ' => 2,
          'en-US' => 3,
          _ => 9,
        };
        final how = switch (quality) {
          'premium' => 0,
          'enhanced' => 1,
          _ => 2,
        };
        return where * 10 + how;
      }

      voices.sort((a, b) => rank(a).compareTo(rank(b)));
      if (voices.isEmpty || rank(voices.first) >= 90) return;
      final best = voices.first;
      await _tts.setVoice({
        'name': '${best['name']}',
        'locale': '${best['locale']}',
      });
    } on PlatformException {
      // keep the default voice
    }
  }

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

  /// The phone's voice needs nothing made ahead.
  @override
  Future<void> warm(List<String> lines) async {}
}

/// Plays a clip's MP3 bytes; completes when it ends or is stopped.
abstract interface class ClipPlayer {
  Future<void> play(Uint8List mp3);
  Future<void> stop();
}

/// [ClipPlayer] over just_audio. A clip is written once to the cache folder,
/// named by its hash, and played from there.
class FileClipPlayer implements ClipPlayer {
  final _player = AudioPlayer();

  @override
  Future<void> play(Uint8List mp3) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/voice-${sha1.convert(mp3)}.mp3');
    if (!await file.exists()) await file.writeAsBytes(mp3, flush: true);
    await _player.setFilePath(file.path);
    await _player.play();
  }

  @override
  Future<void> stop() => _player.stop();
}

/// The case partner's voice (NFR-06, NFR-08): the server reads the line
/// in Zephyr's detective-sidekick voice and sends MP3.
///
/// A new line takes the server a few seconds, so [warm] asks for the
/// problem's lines when it opens (POST /api/voice/warm); by the time one is
/// said it is usually ready. One that is not (a 503) is read by the phone
/// this time and is ready the next.
///
/// Any refusal falls back to [fallback] for that line, so a lesson never
/// waits on it: no answer within [wait], an error, or a 422 because the line
/// names the child (those always use the phone's voice). A 404 means the
/// server reads nothing aloud; the phone's voice reads every line after it.
class CloudVoice implements Voice {
  CloudVoice({
    required this.fetch,
    required this.warmer,
    required this.player,
    required this.fallback,
    this.voiceId,
    this.wait = const Duration(seconds: 3),
  }) {
    fallback.speaking.addListener(_mirror);
  }

  /// POST /api/voice/speak: the MP3 for a line in a voice (null: default).
  final Future<Uint8List> Function(String text, String? voiceId) fetch;

  /// POST /api/voice/warm: start these lines (at most [warmBatch] a call).
  final Future<void> Function(List<String> lines, String? voiceId) warmer;
  static const warmBatch = 12;
  final ClipPlayer player;
  final Voice fallback;

  /// The case partner's voice id from GET /api/voice; null is the default.
  String? voiceId;
  final Duration wait;

  /// Lines already fetched this run: "say it again" plays at once.
  final _clips = <String, Uint8List>{};
  static const _keep = 40;

  /// Bumped by every say and stop: a line that comes back late is dropped.
  int _turn = 0;
  bool _off = false;

  @override
  ValueListenable<bool> get resting => fallback.resting;

  @override
  final ValueNotifier<bool> speaking = ValueNotifier(false);

  void _mirror() => speaking.value = fallback.speaking.value;

  @override
  Future<void> say(String text) async {
    await stop();
    final turn = _turn;
    if (_off) return fallback.say(text);

    var clip = _clips['$voiceId|$text'];
    if (clip == null) {
      try {
        clip = await fetch(text, voiceId).timeout(wait);
        _clips['$voiceId|$text'] = clip;
        if (_clips.length > _keep) _clips.remove(_clips.keys.first);
      } on ApiException catch (e) {
        if (e.status == 404) _off = true;
      } on TimeoutException {
        // too slow this time: the phone reads it
      }
    }
    if (turn != _turn) return; // a newer line, or a stop, came first
    if (clip == null) return fallback.say(text);

    speaking.value = true;
    try {
      await player.play(clip);
    } on Exception {
      if (turn == _turn) {
        speaking.value = false;
        return fallback.say(text);
      }
    } finally {
      if (turn == _turn) speaking.value = false;
    }
  }

  @override
  Future<void> warm(List<String> lines) async {
    final todo = [
      for (final l in {...lines})
        if (l.trim().isNotEmpty && !_clips.containsKey('$voiceId|$l')) l,
    ];
    for (var i = 0; i < todo.length && !_off; i += warmBatch) {
      final batch = todo.sublist(i, (i + warmBatch).clamp(0, todo.length));
      try {
        await warmer(batch, voiceId);
      } on ApiException catch (e) {
        if (e.status == 404) _off = true;
        return; // throttled or offline: the lines are made when said
      } on Exception {
        return;
      }
    }
  }

  @override
  Future<void> stop() async {
    _turn++;
    speaking.value = false;
    await player.stop();
    await fallback.stop();
  }
}
