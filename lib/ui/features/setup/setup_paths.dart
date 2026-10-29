/// Setup's own sub-step, and the addresses that carry setup's data in the
/// query (the new child's id and name; the emailed sign-in token).
abstract final class SetupPaths {
  /// Choose a passcode: after Lock (644:20). Not in Figma; GPass's look.
  static const passcode = '/setup/passcode';

  /// Ready, Lock, Choose a passcode and JoinCode carry the new child.
  static String withChild(
    String path, {
    required String id,
    required String name,
  }) =>
      Uri(path: path, queryParameters: {'child': id, 'name': name}).toString();

  /// Check your email: [email] it went to; [dev] the token of a dev
  /// server's link; [token] a link to follow now.
  static String checkEmail(
    String path, {
    String? email,
    String? dev,
    String? token,
  }) => Uri(
    path: path,
    queryParameters: {'email': ?email, 'dev': ?dev, 'm': ?token},
  ).toString();
}

/// The `m=` token of a sign-in link: `…/parent#m=<token>` from the server,
/// `auramath://auth/verify?m=<token>` once it opens the app.
String? linkToken(String link) =>
    RegExp(r'[#?&]m=([^&#]+)').firstMatch(link)?.group(1);
