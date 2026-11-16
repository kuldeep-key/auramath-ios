import 'dart:io';

import 'package:auramath/data/services/sound_effects.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RecordingSfxPlayer rec;

  setUp(() {
    rec = RecordingSfxPlayer();
    AuraSound.player = rec;
    AuraSound.soundOn.value = true;
  });

  tearDown(() {
    AuraSound.player = const SilentSfxPlayer();
    AuraSound.soundOn.value = true;
  });

  test('each call plays its prototype sound', () {
    AuraSound.tap();
    AuraSound.snap();
    AuraSound.right();
    AuraSound.wrong();
    AuraSound.wrongMove();
    AuraSound.celebrate();
    AuraSound.badge();
    expect(rec.played, [
      Sfx.tap,
      Sfx.snap,
      Sfx.right,
      Sfx.soft,
      Sfx.boing,
      Sfx.win,
      Sfx.badge,
    ]);
  });

  test('nothing plays while the sound is off', () {
    AuraSound.soundOn.value = false;
    AuraSound.tap();
    AuraSound.right();
    AuraSound.celebrate();
    expect(rec.played, isEmpty);
    AuraSound.soundOn.value = true;
    AuraSound.right();
    expect(rec.played, [Sfx.right]);
  });

  test('a player that fails never reaches the caller', () {
    AuraSound.player = _Broken();
    expect(AuraSound.tap, returnsNormally);
  });

  test('every effect has its file in the build', () {
    for (final s in Sfx.values) {
      expect(File(s.asset).existsSync(), isTrue, reason: s.asset);
    }
  });
}

class _Broken implements SfxPlayer {
  @override
  Future<void> play(Sfx sfx) => Future.error(StateError('no audio'));
}
