/// Build-time settings, from `--dart-define-from-file=env/<name>.json`.
abstract final class Env {
  static const name = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const apiBase = String.fromEnvironment('API_BASE');
}
