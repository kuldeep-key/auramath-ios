/// Build-time settings, from `--dart-define-from-file=env/<name>.json`.
abstract final class Env {
  static const name = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const apiBase = String.fromEnvironment('API_BASE');
  static const appVersion = String.fromEnvironment('APP_VERSION');

  /// Sessions from this build are demo data, never a child's real work.
  static const isDemo = bool.fromEnvironment('DEMO');

  // ponytail: dev placeholders until setup and pairing hand out the real
  // child ref and device id; prod leaves them empty on purpose.
  static const childRef = String.fromEnvironment('CHILD_REF');
  static const deviceId = String.fromEnvironment('DEVICE_ID');
}
