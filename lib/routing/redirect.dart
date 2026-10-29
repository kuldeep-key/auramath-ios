import '../data/repositories/account_repository.dart';
import 'paths.dart';

/// Where a phone may be, given who is using it. The router asks this on
/// every navigation and whenever the account changes, so a sign-in, a
/// removed phone or a locked grown-up area moves the screen by itself.
/// Null means "stay".
String? redirectFor({
  required Uri uri,
  required Role role,
  required bool removed,
  required bool grownUpsUnlocked,
  required String? childId,
}) {
  final loc = uri.path;
  // `auramath://auth/verify?m=…`: the platform reads "auth" as the host,
  // so the app sees `/verify`
  if (loc == '/verify') {
    return Uri(
      path: Paths.verify,
      queryParameters: uri.queryParameters,
    ).toString();
  }
  if (removed) return loc == Paths.removed ? null : Paths.removed;
  if (loc == '/') return _start(role, childId);

  switch (role) {
    case Role.none:
      return Paths.isPublic(loc) ? null : Paths.open;

    case Role.device:
      // the child's own phone: a grown-up must sign in here first
      if (Paths.isGrownUp(loc) ||
          loc == Paths.grownUpsPass ||
          Paths.isSignedInSetup(loc)) {
        return Paths.signIn;
      }
      if (loc == Paths.open || loc == Paths.welcome) {
        return _start(role, childId);
      }
      // just paired: GetCode itself picks Is-this-you or Which-child
      if (loc == Paths.pair) return childId == null ? null : Paths.home;
      if (childId == null && _needsChild(loc)) return Paths.pairWhichChild;
      return null;

    case Role.parent:
      if (loc == Paths.open ||
          loc == Paths.welcome ||
          loc == Paths.signIn ||
          loc == Paths.signInCheckEmail ||
          loc == Paths.verify ||
          loc.startsWith(Paths.pair)) {
        return Paths.kids;
      }
      if (Paths.isGrownUp(loc) && !grownUpsUnlocked) {
        return Uri(
          path: Paths.grownUpsPass,
          queryParameters: {'to': uri.toString()},
        ).toString();
      }
      if (childId == null && _needsChild(loc)) return Paths.kids;
      return null;
  }
}

String _start(Role role, String? childId) => switch (role) {
  Role.none => Paths.open,
  Role.device => childId == null ? Paths.pairWhichChild : Paths.home,
  Role.parent => Paths.kids,
};

/// The child's screens: they need to know which child is learning.
bool _needsChild(String loc) =>
    loc == Paths.home ||
    loc == Paths.welcomeBack ||
    loc == Paths.carryOn ||
    loc.startsWith('/lesson/') ||
    loc.startsWith(Paths.badges) ||
    loc.startsWith(Paths.trail) ||
    loc == Paths.check ||
    loc == Paths.afterCase;
