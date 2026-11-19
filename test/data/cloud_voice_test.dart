import 'dart:async';

import 'package:auramath/data/services/api.dart';
import 'package:auramath/data/services/voice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _Phone implements Voice {
  final said = <String>[];

  @override
  final ValueNotifier<bool> resting = ValueNotifier(false);

  @override
  final ValueNotifier<bool> speaking = ValueNotifier(false);

  @override
  Future<void> say(String text) async => said.add(text);

  @override
  Future<void> sayIn(String text, String? voiceId) => say(text);

  @override
  Future<void> stop() async {}

  @override
  Future<void> warm(List<String> lines) async {}
}

class _Clips implements ClipPlayer {
  final played = <Uint8List>[];

  @override
  Future<void> play(Uint8List mp3) async => played.add(mp3);

  @override
  Future<void> stop() async {}
}

void main() {
  late _Phone phone;
  late _Clips clips;
  late List<String> asked;
  late List<List<String>> warmed;

  CloudVoice voice(
    Future<Uint8List> Function(String text) answer, {
    Future<void> Function(List<String> lines)? warmer,
  }) => CloudVoice(
    fetch: (text, _) {
      asked.add(text);
      return answer(text);
    },
    warmer: (lines, _) async {
      warmed.add(lines);
      await warmer?.call(lines);
    },
    player: clips,
    fallback: phone,
    wait: const Duration(milliseconds: 50),
    lockedWait: const Duration(milliseconds: 300),
    retryEvery: const Duration(milliseconds: 20),
  );

  setUp(() {
    phone = _Phone();
    clips = _Clips();
    asked = [];
    warmed = [];
  });

  test('a line plays in the case partner voice', () async {
    final v = voice((t) async => Uint8List.fromList([1, 2, 3]));
    await v.say('How tall is the fig tree?');
    expect(clips.played, hasLength(1));
    expect(phone.said, isEmpty);
  });

  test('the same line again plays without asking the server', () async {
    final v = voice((t) async => Uint8List.fromList([1]));
    await v.say('Can you draw the story out?');
    await v.say('Can you draw the story out?');
    expect(asked, hasLength(1));
    expect(clips.played, hasLength(2));
  });

  test('a line with the child name is read by the phone', () async {
    final v = voice(
      (t) async => throw const ApiException('names someone', status: 422),
    );
    await v.say('Well spotted, Aarav!');
    expect(phone.said, ['Well spotted, Aarav!']);
    expect(clips.played, isEmpty);
  });

  group('one voice for a whole lesson', () {
    test("the first line's clip in time: every line in the case partner's "
        'voice, even one that is slow to make', () async {
      var n = 0;
      final v = voice((t) async {
        // the second line takes longer than the first line's 50 ms wait
        if (n++ == 1) {
          await Future<void>.delayed(const Duration(milliseconds: 120));
        }
        return Uint8List.fromList([n]);
      });
      v.beginLesson();
      await v.say('First line');
      expect(v.lock, VoiceLock.cloud);
      await v.say('Second line');
      await v.say('Third line');
      expect(phone.said, isEmpty);
      expect(clips.played, hasLength(3));
    });

    test('the first line too slow: the whole lesson in the phone voice, '
        'even when the server is ready later', () async {
      var n = 0;
      final v = voice((t) async {
        if (n++ == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        return Uint8List.fromList([1]);
      });
      v.beginLesson();
      await v.say('First line');
      await v.say('Second line');
      expect(v.lock, VoiceLock.phone);
      expect(phone.said, ['First line', 'Second line']);
      expect(clips.played, isEmpty);
      expect(asked, ['First line']); // the server isn't asked again
    });

    test('a line still being made (503) is asked again, not read by the '
        'phone', () async {
      var tries = 0;
      final v = voice((t) async {
        if (t == 'Second line' && tries++ < 3) {
          throw const ApiException('making it', status: 503);
        }
        return Uint8List.fromList([1]);
      });
      v.beginLesson();
      await v.say('First line');
      await v.say('Second line');
      expect(tries, 4);
      expect(phone.said, isEmpty);
      expect(clips.played, hasLength(2));
    });

    test("the case partner's voice failing mid-lesson: the phone to the "
        'end, never back', () async {
      var down = false;
      final v = voice((t) async {
        if (down) throw const ApiException('down', status: 500);
        return Uint8List.fromList([1]);
      });
      v.beginLesson();
      await v.say('One');
      down = true;
      await v.say('Two');
      down = false;
      await v.say('Three');
      expect(clips.played, hasLength(1));
      expect(phone.said, ['Two', 'Three']);
    });

    test('a new lesson chooses again', () async {
      var slow = true;
      final v = voice((t) async {
        if (slow) await Future<void>.delayed(const Duration(milliseconds: 200));
        return Uint8List.fromList([1]);
      });
      v.beginLesson();
      await v.say('Lesson one');
      expect(v.lock, VoiceLock.phone);
      slow = false;
      v.beginLesson();
      await v.say('Lesson two');
      await v.say('Lesson two again');
      expect(v.lock, VoiceLock.cloud);
      expect(phone.said, ['Lesson one']);
      expect(clips.played, hasLength(2));
    });

    test('a line naming the child, in a case-partner lesson, stays in the '
        'bubble rather than switch voice', () async {
      final v = voice(
        (t) async => t.contains('Aarav')
            ? throw const ApiException('names someone', status: 422)
            : Uint8List.fromList([1]),
      );
      v.beginLesson();
      await v.say('Hello');
      await v.say('Well spotted, Aarav!');
      await v.say('Next one');
      expect(phone.said, isEmpty);
      expect(clips.played, hasLength(2));
      expect(v.lock, VoiceLock.cloud);
    });

    test(
      "a picker's hello in another voice leaves the lesson's voice",
      () async {
        final v = voice((t) async => Uint8List.fromList([1]));
        v.beginLesson();
        await v.say('One');
        await v.sayIn('Hi, I sound like this', 'voice_b');
        expect(v.lock, VoiceLock.cloud);
        expect(v.voiceId, isNull);
      },
    );
  });

  test('read-aloud off on the server: the phone reads from then on', () async {
    final v = voice((t) async => throw const ApiException('off', status: 404));
    await v.say('One');
    await v.say('Two');
    expect(asked, ['One']);
    expect(phone.said, ['One', 'Two']);
  });

  test('a stop before the clip arrives drops it', () async {
    final gate = Completer<Uint8List>();
    final v = voice((t) => gate.future);
    final saying = v.say('Late line');
    await v.stop();
    gate.complete(Uint8List.fromList([1]));
    await saying;
    expect(clips.played, isEmpty);
    expect(phone.said, isEmpty);
  });

  test('warm asks for the lines ahead, a dozen at a time, once each', () async {
    final v = voice((t) async => Uint8List.fromList([1]));
    await v.say('Already heard');
    final lines = [
      'Already heard',
      for (var i = 0; i < 14; i++) 'Line $i',
      'Line 0',
      '  ',
    ];
    await v.warm(lines);
    expect(warmed.map((b) => b.length), [12, 2]);
    expect(warmed.expand((b) => b), isNot(contains('Already heard')));
  });

  test('a failed warm is quiet; read-aloud off stops it for good', () async {
    final v = voice(
      (t) async => Uint8List.fromList([1]),
      warmer: (lines) async => throw const ApiException('off', status: 404),
    );
    await v.warm(['One']);
    await v.say('Two');
    expect(asked, isEmpty);
    expect(phone.said, ['Two']);
  });

  test('TTR-02: a voice with no service voice yet (404) is read by the '
      'phone; the other voices still play', () async {
    final v = CloudVoice(
      fetch: (text, id) async => id == 'voice_b'
          ? throw const ApiException('no voice', status: 404)
          : Uint8List.fromList([1]),
      warmer: (_, _) async {},
      player: clips,
      fallback: phone,
      wait: const Duration(milliseconds: 50),
    )..voiceId = 'voice_b';
    await v.say('Hi!');
    await v.say('Again');
    expect(phone.said, ['Hi!', 'Again']);
    v.voiceId = 'voice_a';
    await v.say('Hello');
    expect(clips.played, hasLength(1));
  });

  group('NoVoice: no voice on the phone (19 Nov)', () {
    test(
      'a line it is given is not read: the voice rests, words big',
      () async {
        final none = NoVoice();
        await none.say('  ');
        expect(none.resting.value, isFalse);
        await none.say('How tall is the fig tree?');
        expect(none.resting.value, isTrue);
        expect(none.speaking.value, isFalse);
      },
    );

    test("the server's voice failing: the lesson rests; the next lesson "
        'wakes it and asks the server again', () async {
      final none = NoVoice();
      var down = true;
      final v = CloudVoice(
        fetch: (text, _) async {
          asked.add(text);
          if (down) throw const ApiException('down', status: 503);
          return Uint8List.fromList([1]);
        },
        warmer: (_, _) async {},
        player: clips,
        fallback: none,
        wait: const Duration(milliseconds: 50),
      );
      v.beginLesson();
      await v.say('First line');
      expect(v.lock, VoiceLock.phone);
      expect(v.resting.value, isTrue);
      expect(clips.played, isEmpty);

      down = false;
      v.beginLesson();
      expect(v.resting.value, isFalse);
      await v.say('First line');
      expect(v.lock, VoiceLock.cloud);
      expect(clips.played, hasLength(1));
      expect(v.resting.value, isFalse);
    });
  });
}
