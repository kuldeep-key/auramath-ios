import 'package:auramath/data/services/sound_effects.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// The sound effects play with read-aloud off (its default since 20 Nov);
/// the header's mute silences them, and "Sound is on now" or unmuting
/// brings them back (NFR-06).
void main() {
  late RecordingSfxPlayer rec;

  setUp(() => AuraSound.player = rec = RecordingSfxPlayer());
  tearDown(() {
    AuraSound.player = const SilentSfxPlayer();
    AuraSound.soundOn.value = true;
  });

  test('PAR-05 (20 Nov): read-aloud off, the lesson does not ask the child '
      'to turn the sound on; only a grown-up does', () async {
    final (sessions, _, _) = await memorySessions();
    final vm =
        LessonViewModel(
            pack: samplePack(),
            problemId: 'lemon',
            sessionId: 's1',
            sessions: sessions,
            voice: FakeVoice(),
            nowMs: () => 0,
            openSession: sessions.open,
            sitting: Sitting(capMs: 30 * 60 * 1000),
            tickEvery: null,
          )
          ..readAloud = false
          ..readAloudFlag = true;
    addTearDown(vm.dispose);
    await vm.start();
    expect(vm.offerSound, isFalse);
    vm.childTurnsSoundOn = true;
    expect(vm.offerSound, isTrue);
  });

  test('read-aloud off: effects still; muted: none; sound on again: '
      'effects', () async {
    final (sessions, _, _) = await memorySessions();
    final vm = LessonViewModel(
      pack: samplePack(),
      problemId: 'lemon',
      sessionId: 's1',
      sessions: sessions,
      voice: FakeVoice(),
      nowMs: () => 0,
      openSession: sessions.open,
      sitting: Sitting(capMs: 30 * 60 * 1000),
      tickEvery: null,
    )..readAloud = false;
    addTearDown(vm.dispose);
    await vm.start();
    AuraSound.right();
    expect(rec.played, [Sfx.right]);
    vm.sound(false);
    AuraSound.right();
    expect(rec.played, [Sfx.right]);
    await vm.soundAnswered('sound_on');
    AuraSound.right();
    expect(rec.played, [Sfx.right, Sfx.right]);
  });
}
