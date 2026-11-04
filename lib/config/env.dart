/// Build-time settings, from `--dart-define-from-file=env/<name>.json`.
abstract final class Env {
  static const name = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const apiBase = String.fromEnvironment('API_BASE');
  static const appVersion = String.fromEnvironment('APP_VERSION');

  /// Sessions from this build are demo data, never a child's real work.
  static const isDemo = bool.fromEnvironment('DEMO');

  /// The iOS OAuth client id for Google sign-in. Empty until the Google
  /// project exists; the Google button then explains it isn't set up.
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  /// `server`: problems come from `problems/next` at the child's level.
  /// `bundled` (the default): the sample pack's fixed chain, for a server
  /// without that route (a local backend older than spec v0.4.1).
  static const serverProblems =
      String.fromEnvironment('PROBLEMS', defaultValue: 'bundled') == 'server';

  static bool get isDev => name == 'dev';
}
