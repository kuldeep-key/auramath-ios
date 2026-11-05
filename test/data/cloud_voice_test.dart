import 'dart:async';
import 'dart:typed_data';

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
      (t) async => throw ApiException('names someone', status: 422),
    );
    await v.say('Well spotted, Aarav!');
    expect(phone.said, ['Well spotted, Aarav!']);
    expect(clips.played, isEmpty);
  });

  test('a slow or failed voice falls back for that line only', () async {
    var n = 0;
    final v = voice((t) async {
      if (n++ == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      return Uint8List.fromList([1]);
    });
    await v.say('First line');
    await v.say('Second line');
    expect(phone.said, ['First line']);
    expect(clips.played, hasLength(1));
  });

  test('read-aloud off on the server: the phone reads from then on', () async {
    final v = voice((t) async => throw ApiException('off', status: 404));
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
      warmer: (lines) async => throw ApiException('off', status: 404),
    );
    await v.warm(['One']);
    await v.say('Two');
    expect(asked, isEmpty);
    expect(phone.said, ['Two']);
  });
}
