import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// The prototype's sound effects (its `tone()` engine, the "Bubbly" pack and
/// `CONFIRM`), rendered once to WAV by `tool/proto_sfx.py`:
/// `assets/proto/sfx/<name>.wav`.
enum Sfx {
  /// A main (filled) button: two soft high blips (`CONFIRM`, 210 ms).
  tap,

  /// A piece snaps into place (`snap`, 300 ms).
  snap,

  /// A right answer or a right piece (`right`, 750 ms).
  right,

  /// A wrong answer: a soft falling note, never a buzzer (`soft`, 350 ms).
  soft,

  /// A piece dropped in the wrong place (`boing`, 420 ms).
  boing,

  /// A case solved, a celebration (`win`, 1.3 s).
  win,

  /// A badge (`badge`, 1.5 s).
  badge;

  String get asset => 'assets/proto/sfx/$name.wav';
}

/// Plays one effect. The app's is [AssetSfxPlayer]; tests use none, or a
/// recorder.
abstract interface class SfxPlayer {
  Future<void> play(Sfx sfx);
}

/// Plays nothing: the default until the app installs [AssetSfxPlayer], so a
/// widget test never reaches the audio plugin.
class SilentSfxPlayer implements SfxPlayer {
  const SilentSfxPlayer();

  @override
  Future<void> play(Sfx sfx) async {}
}

/// Remembers what was played, for tests.
class RecordingSfxPlayer implements SfxPlayer {
  final played = <Sfx>[];

  @override
  Future<void> play(Sfx sfx) async => played.add(sfx);
}

/// [SfxPlayer] over just_audio: one player per effect, loaded the first
/// time it plays, rewound and played again after that.
class AssetSfxPlayer implements SfxPlayer {
  final _players = <Sfx, AudioPlayer>{};
  final _loading = <Sfx, Future<void>>{};

  @override
  Future<void> play(Sfx sfx) async {
    final p = _players.putIfAbsent(sfx, AudioPlayer.new);
    await (_loading[sfx] ??= p.setAsset(sfx.asset).then((_) {}));
    await p.seek(Duration.zero);
    await p.play();
  }
}

/// The app's sound effects, for every area: taps, right, wrong and the big
/// moments. They follow the app's sound setting ([soundOn]): with the sound
/// off (the grown-up's read-aloud off, or the child answering "I'll read"
/// on the Sound screen) nothing plays, as the prototype's
/// `if(!S.sound) return`. They never wait and never throw.
///
/// ```dart
/// AuraSound.tap();        // a main button
/// AuraSound.right();      // a right answer
/// AuraSound.wrong();      // a wrong answer (soft, never a buzzer)
/// AuraSound.celebrate();  // a case solved
/// ```
abstract final class AuraSound {
  /// What plays the effects. `main.dart` sets [AssetSfxPlayer].
  static SfxPlayer player = const SilentSfxPlayer();

  /// The app's sound setting: false while the child has the sound off.
  /// The lesson and the grown-up's settings keep it up to date.
  static final ValueNotifier<bool> soundOn = ValueNotifier(true);

  /// Plays [sfx] if the sound is on.
  static void play(Sfx sfx) {
    if (!soundOn.value) return;
    try {
      unawaited(player.play(sfx).catchError((Object _) {}));
    } on Object {
      // no audio on this phone: the effect is only ever extra
    }
  }

  /// A main button (the prototype's `confirmTap`: filled buttons only).
  static void tap() => play(Sfx.tap);

  /// A piece snaps into place.
  static void snap() => play(Sfx.snap);

  /// A right answer.
  static void right() => play(Sfx.right);

  /// A wrong answer: soft.
  static void wrong() => play(Sfx.soft);

  /// A piece dropped in the wrong place.
  static void wrongMove() => play(Sfx.boing);

  /// A case solved, a celebration.
  static void celebrate() => play(Sfx.win);

  /// A badge.
  static void badge() => play(Sfx.badge);
}
