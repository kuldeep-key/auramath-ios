import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'api.dart';

/// Reads a line aloud: the case partner's voice from the server
/// ([CloudVoice]); whenever that is off, slow or refuses a line, nothing
/// is read and the words show big ([NoVoice]). No voice on the phone reads
/// a line: no AI voice anywhere (19 Nov).
abstract interface class Voice {
  Future<void> say(String text);

  /// Says [text] in [voiceId] this once (a tutor's or voice's hello on the
  /// pickers, TTR-01, TTR-06); the child's own voice stays as it is.
  Future<void> sayIn(String text, String? voiceId);
  Future<void> stop();

  /// Lines the child is about to hear: a voice that takes time to make a
  /// line starts them now. Never throws.
  Future<void> warm(List<String> lines);

  /// True once the voice couldn't read a line: the lesson says so
  /// (NoVoice 659:39) and shows its words big instead.
  ValueListenable<bool> get resting;

  /// True while a line is being read: the speak button glows.
  ValueListenable<bool> get speaking;
}

/// No voice: a line it is given is not read, and the voice is resting, so
/// the lesson shows its words big (NoVoice 659:39). A new lesson wakes it,
/// and the server's voice is tried again.
class NoVoice implements Voice, LessonVoice {
  @override
  final ValueNotifier<bool> resting = ValueNotifier(false);

  @override
  final ValueNotifier<bool> speaking = ValueNotifier(false);

  @override
  void beginLesson() => resting.value = false;

  @override
  Future<void> say(String text) async {
    if (text.trim().isNotEmpty) resting.value = true;
  }

  @override
  Future<void> sayIn(String text, String? voiceId) => say(text);

  @override
  Future<void> stop() async {}

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

/// A voice that keeps one voice for a whole lesson: the lesson tells it
/// when a new one begins.
abstract interface class LessonVoice {
  /// A new lesson: its first line chooses the voice again.
  void beginLesson();
}

/// Which voice this lesson speaks in.
enum VoiceLock {
  /// Not chosen yet: the lesson's first line chooses.
  open,

  /// The case partner's voice from the server, for every line.
  cloud,

  /// The fallback for every line: no voice ([NoVoice]), the words big.
  phone,
}

/// The case partner's voice (NFR-06, NFR-08): the server reads the line
/// in the tutor's voice and sends MP3.
///
/// A new line takes the server a few seconds, so [warm] asks for the
/// problem's lines when it opens (POST /api/voice/warm); by the time one is
/// said it is usually ready.
///
/// **One voice for a whole lesson** (tutors.yaml `one_voice_at_a_time`, as
/// the prototype keeps one voice: it picks the phone's voice once and
/// reuses it, and a voice that fails is dropped for good, never tried line
/// by line). The rule:
///
/// 1. The lesson's first line chooses ([beginLesson] opens the choice; so
///    does a new [voiceId]). If its clip comes within [wait] (3 s), the
///    lesson is in the case partner's voice ([VoiceLock.cloud]); if not
///    (too slow, an error, a line the server won't read), that line and
///    the whole lesson are in the phone's voice ([VoiceLock.phone]).
/// 2. In the case partner's voice, a line waits up to [lockedWait] for its
///    clip (a line not made yet, the server's 503, is asked again every
///    [retryEvery]), rather than being read by the phone in between. The
///    child never waits on it: the words are on screen, nothing blocks,
///    and a tap stops it.
/// 3. If the case partner's voice still fails (no clip by [lockedWait],
///    the server down, the clip won't play), the phone reads the rest of
///    the lesson: one change at most, and never back.
/// 4. A line the server refuses because it names the child (its 422, which
///    the tutor's lines never should, NFR-08) is not read in another
///    voice: in a case-partner lesson it stays in the speech bubble.
///
/// So within a lesson every line is in the same voice, except after a
/// failure of the server's voice, after which it is the phone's to the end.
/// [sayIn] (a tutor's or voice's hello on the pickers) is outside the rule
/// and never changes it.
///
/// A 404 for a chosen voice means it has no service voice yet: the phone
/// reads that voice's lines. A 404 with no voice chosen means the server
/// reads nothing aloud; the phone's voice reads every line after it.
///
/// "The phone's voice" here is [fallback], which the app makes [NoVoice]
/// (19 Nov: no voice on the phone reads a line): the line is not read and
/// its words show big. [beginLesson] wakes it too.
class CloudVoice implements Voice, LessonVoice {
  CloudVoice({
    required this.fetch,
    required this.warmer,
    required this.player,
    required this.fallback,
    this._voiceId,
    this.wait = const Duration(seconds: 3),
    this.lockedWait = const Duration(seconds: 10),
    this.retryEvery = const Duration(milliseconds: 600),
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

  /// The longest the lesson's first line waits for the server's clip.
  final Duration wait;

  /// The longest a later line waits in a case-partner lesson.
  final Duration lockedWait;

  /// How often a line the server is still making is asked for again.
  final Duration retryEvery;

  /// The case partner's voice id from GET /api/voice; null is the default.
  /// A new one chooses the lesson's voice again.
  String? get voiceId => _voiceId;
  String? _voiceId;
  set voiceId(String? id) {
    if (id == _voiceId) return;
    _voiceId = id;
    _lock = VoiceLock.open;
  }

  /// The voice this lesson speaks in.
  VoiceLock get lock => _lock;
  var _lock = VoiceLock.open;

  @override
  void beginLesson() {
    _lock = VoiceLock.open;
    if (fallback case final LessonVoice f) f.beginLesson();
  }

  /// Lines already fetched this run: "say it again" plays at once.
  final _clips = <String, Uint8List>{};
  static const _keep = 40;

  /// Bumped by every say and stop: a line that comes back late is dropped.
  int _turn = 0;
  bool _off = false;

  /// Voices the server has no service voice for yet (its 404 for that
  /// voiceId): the phone reads their lines; the others still play.
  final _unvoiced = <String>{};
  bool _phoneOnly(String? id) => _off || _unvoiced.contains(id);
  void _notFound(String? id) => id == null ? _off = true : _unvoiced.add(id);

  @override
  ValueListenable<bool> get resting => fallback.resting;

  @override
  final ValueNotifier<bool> speaking = ValueNotifier(false);

  void _mirror() => speaking.value = fallback.speaking.value;

  @override
  Future<void> say(String text) async {
    // take the turn before any await: a stop tapped meanwhile wins
    final turn = ++_turn;
    await _hush();
    if (turn != _turn) return;
    if (_phoneOnly(_voiceId)) _lock = VoiceLock.phone;
    if (_lock == VoiceLock.phone) return fallback.say(text);

    final locked = _lock == VoiceLock.cloud;
    final (clip, named) = await _clipFor(
      text,
      _voiceId,
      turn,
      locked ? lockedWait : wait,
      retry: locked,
    );
    if (turn != _turn) return; // a newer line, or a stop, came first
    if (clip == null) {
      // rule 4: a line naming the child stays in the bubble
      if (named && locked) return;
      // rules 1 and 3: the phone, for the rest of the lesson
      _lock = VoiceLock.phone;
      return fallback.say(text);
    }
    _lock = VoiceLock.cloud;
    if (!await _play(clip, turn)) {
      _lock = VoiceLock.phone;
      return fallback.say(text);
    }
  }

  /// The clip for [text] in [voiceId], from this run's or the server's,
  /// within [within]; with [retry], a line still being made (503) is asked
  /// again until then. Null when there is none in time; `named` when the
  /// server refused it for naming the child (422).
  Future<(Uint8List?, bool)> _clipFor(
    String text,
    String? voiceId,
    int turn,
    Duration within, {
    required bool retry,
  }) async {
    final key = '$voiceId|$text';
    final kept = _clips[key];
    if (kept != null) return (kept, false);
    final end = DateTime.now().add(within);
    while (true) {
      final left = end.difference(DateTime.now());
      if (left <= Duration.zero || turn != _turn) return (null, false);
      try {
        final clip = await fetch(text, voiceId).timeout(left);
        _clips[key] = clip;
        if (_clips.length > _keep) _clips.remove(_clips.keys.first);
        return (clip, false);
      } on ApiException catch (e) {
        if (e.status == 404) _notFound(voiceId);
        if (e.status == 422) return (null, true);
        if (!retry || e.status != 503) return (null, false);
      } on TimeoutException {
        return (null, false);
      } on Exception {
        return (null, false);
      }
      final pause = end.difference(DateTime.now());
      await Future<void>.delayed(pause < retryEvery ? pause : retryEvery);
    }
  }

  /// Plays [clip]; false when it wouldn't play (and it is still [turn]).
  Future<bool> _play(Uint8List clip, int turn) async {
    speaking.value = true;
    try {
      await player.play(clip);
      return true;
    } on Exception {
      return turn != _turn;
    } finally {
      if (turn == _turn) speaking.value = false;
    }
  }

  /// A one-off line in [voiceId] (the pickers): its own clip within
  /// [wait], else the phone; the lesson's voice is left as it is.
  @override
  Future<void> sayIn(String text, String? voiceId) async {
    final turn = ++_turn;
    await _hush();
    if (turn != _turn) return;
    if (_phoneOnly(voiceId)) return fallback.say(text);
    final (clip, _) = await _clipFor(text, voiceId, turn, wait, retry: false);
    if (turn != _turn) return;
    if (clip == null || !await _play(clip, turn)) return fallback.say(text);
  }

  @override
  Future<void> warm(List<String> lines) async {
    final todo = [
      for (final l in {...lines})
        if (l.trim().isNotEmpty && !_clips.containsKey('$voiceId|$l')) l,
    ];
    for (var i = 0; i < todo.length && !_phoneOnly(voiceId); i += warmBatch) {
      final batch = todo.sublist(i, (i + warmBatch).clamp(0, todo.length));
      try {
        await warmer(batch, voiceId);
      } on ApiException catch (e) {
        if (e.status == 404) _notFound(voiceId);
        return; // throttled or offline: the lines are made when said
      } on Exception {
        return;
      }
    }
  }

  @override
  Future<void> stop() async {
    _turn++;
    await _hush();
  }

  Future<void> _hush() async {
    speaking.value = false;
    await player.stop();
    await fallback.stop();
  }
}
