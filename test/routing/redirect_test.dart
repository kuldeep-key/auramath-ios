import 'package:auramath/data/repositories/account_repository.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/routing/redirect.dart';
import 'package:flutter_test/flutter_test.dart';

String? go(
  String loc, {
  Role role = Role.none,
  bool removed = false,
  bool unlocked = false,
  String? childId,
}) => redirectFor(
  uri: Uri.parse(loc),
  role: role,
  removed: removed,
  grownUpsUnlocked: unlocked,
  childId: childId,
);

void main() {
  group('a fresh phone', () {
    test('starts on Who\'s here?', () => expect(go('/'), Paths.open));

    test('may run setup and sign-in, nothing else', () {
      for (final loc in [
        Paths.welcome,
        Paths.setupName,
        Paths.setupSave,
        Paths.signIn,
        Paths.pair,
        Paths.pairWrong,
        '${Paths.verify}?m=abc',
      ]) {
        expect(go(loc), isNull, reason: loc);
      }
      for (final loc in [
        Paths.home,
        Paths.lesson('lemon'),
        Paths.grownUps,
        Paths.setupReady,
        Paths.kids,
      ]) {
        expect(go(loc), Paths.open, reason: loc);
      }
    });
  });

  group("a child's own phone", () {
    test('goes to its home, or asks whose phone it is', () {
      expect(go('/', role: Role.device, childId: 'c'), Paths.home);
      expect(go('/', role: Role.device), Paths.pairWhichChild);
      expect(go(Paths.home, role: Role.device), Paths.pairWhichChild);
      expect(go(Paths.pair, role: Role.device, childId: 'c'), Paths.home);
    });

    test('needs a grown-up to sign in before the grown-up area', () {
      expect(go(Paths.grownUps, role: Role.device, childId: 'c'), Paths.signIn);
      expect(go(Paths.grownUpsPass, role: Role.device), Paths.signIn);
      expect(go(Paths.setupJoinCode, role: Role.device), Paths.signIn);
    });

    test('a removed phone shows only "This phone was removed"', () {
      expect(
        go(Paths.home, role: Role.device, childId: 'c', removed: true),
        Paths.removed,
      );
      expect(go(Paths.removed, role: Role.device, removed: true), isNull);
    });
  });

  group("a grown-up's phone", () {
    test('lands on Who\'s learning and skips sign-in screens', () {
      for (final loc in ['/', Paths.open, Paths.signIn, Paths.pair]) {
        expect(go(loc, role: Role.parent), Paths.kids, reason: loc);
      }
    });

    test('the grown-up area asks for the passcode, then comes back', () {
      final to = go(Paths.settings, role: Role.parent);
      expect(Uri.parse(to!).path, Paths.grownUpsPass);
      expect(Uri.parse(to).queryParameters['to'], Paths.settings);
      expect(go(Paths.settings, role: Role.parent, unlocked: true), isNull);
      expect(go(Paths.grownUpsPass, role: Role.parent), isNull);
      expect(go(Paths.forgotPasscode, role: Role.parent), isNull);
    });

    test("the child's screens need a child chosen", () {
      expect(go(Paths.home, role: Role.parent), Paths.kids);
      expect(go(Paths.home, role: Role.parent, childId: 'c'), isNull);
    });

    test('setup after sign-in is open', () {
      expect(go(Paths.setupReady, role: Role.parent), isNull);
      expect(go(Paths.setupJoinCode, role: Role.parent), isNull);
    });
  });
}
