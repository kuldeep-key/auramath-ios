import 'package:auramath/data/repositories/grown_up_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("who may remove whom, as the server allows it (family.py)", () {
    const owner = Member(email: 'o@x', owner: true, you: false);
    const raj = Member(id: 'm1', email: 'r@x', owner: false, you: false);
    // invited by raj
    const nan = Member(
      id: 'm2',
      email: 'n@x',
      owner: false,
      you: false,
      invitedBy: 'm1',
    );

    Member you(Member m) => Member(
      id: m.id,
      email: m.email,
      owner: m.owner,
      you: true,
      invitedBy: m.invitedBy,
    );

    test('the owner removes any invited grown-up, never themselves', () {
      final rules = FamilyRules([you(owner), raj, nan]);
      expect(rules.canRemove(you(owner)), isFalse);
      expect(rules.canRemove(raj), isTrue);
      expect(rules.canRemove(nan), isTrue);
      expect(
        rules.canCancel(const Invite(email: 'a@x', invitedBy: 'm1')),
        isTrue,
      );
    });

    test('an invited grown-up only those they invited', () {
      final rules = FamilyRules([owner, you(raj), nan]);
      expect(rules.canRemove(owner), isFalse);
      expect(rules.canRemove(you(raj)), isFalse);
      expect(rules.canRemove(nan), isTrue);
      expect(
        rules.canCancel(const Invite(email: 'a@x', invitedBy: 'm1')),
        isTrue,
      );
      expect(rules.canCancel(const Invite(email: 'b@x')), isFalse);
    });
  });

  test('learning: levels and changes, and nothing else', () {
    final types = LearningType.fromJson({
      'questionTypes': {
        'cmp.comparison': {
          'level': 'L4',
          'cleanSolvesAtLevel': 2,
          'levelChanges': [
            {'from': 'L3', 'to': 'L4', 'reason': 'move_up'},
          ],
        },
      },
      'problems': 5,
    });
    expect(types.single.id, 'cmp.comparison');
    expect(types.single.level, 'L4');
    expect(types.single.changes.single, (
      from: 'L3',
      to: 'L4',
      reason: 'move_up',
    ));
    expect(LearningType.fromJson({'questionTypes': {}}), isEmpty);
  });

  test('browsers: this phone is marked', () {
    final b = Browser.fromJson({'id': 'c1', 'label': 'iPhone', 'you': true});
    expect(b.you, isTrue);
    expect(b.lastSeenAt, isNull);
  });
}
