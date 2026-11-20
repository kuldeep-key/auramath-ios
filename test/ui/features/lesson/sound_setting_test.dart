import 'package:auramath/data/services/sound_effects.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// The sound effects follow the lesson's read-aloud: a child with the sound
/// off hears none, and "Sound is on now" brings them back (NFR-06).
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

  test('read-aloud off: no effects; sound on again: effects', () async {
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
    expect(rec.played, isEmpty);
    await vm.soundAnswered('sound_on');
    AuraSound.right();
    expect(rec.played, [Sfx.right]);
  });
}
