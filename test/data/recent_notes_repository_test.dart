import 'package:auramath/data/repositories/recent_notes_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a note is read loosely', () {
    final a = SessionNote.fromJson({
      'session_id': 's1',
      'at': '2026-11-10T09:00:00Z',
      'sentences': [
        'One.',
        {'text': 'Two.'},
        '',
      ],
    })!;
    expect(a.sessionId, 's1');
    expect(a.sentences, ['One.', 'Two.']);
    expect(a.at, isNotNull);
    expect(
      SessionNote.fromJson({'id': 's2', 'summary': 'All of it.'})!.sentences,
      ['All of it.'],
    );
    expect(SessionNote.fromJson({'id': 's3', 'sentences': <Object>[]}), isNull);
    expect(SessionNote.fromJson({'text': 'no id'}), isNull);
  });
}
