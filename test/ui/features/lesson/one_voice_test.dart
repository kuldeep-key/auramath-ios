import 'package:auramath/data/services/voice.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

class _LessonVoice extends FakeVoice implements LessonVoice {
  int begun = 0;

  @override
  void beginLesson() => begun++;
}

/// Each lesson tells the voice it began, so its first line chooses the one
/// voice the whole lesson speaks in (CloudVoice).
void main() {
  test('a lesson opens the choice of voice once, as it starts', () async {
    final (sessions, _, _) = await memorySessions();
    final voice = _LessonVoice();
    final vm = LessonViewModel(
      pack: samplePack(),
      problemId: 'lemon',
      sessionId: 's1',
      sessions: sessions,
      voice: voice,
      nowMs: () => 0,
      openSession: sessions.open,
      sitting: Sitting(capMs: 30 * 60 * 1000),
      tickEvery: null,
    );
    addTearDown(vm.dispose);
    expect(voice.begun, 0);
    await vm.start();
    expect(voice.begun, 1);
  });
}
