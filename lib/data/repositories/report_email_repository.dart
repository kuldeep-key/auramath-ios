import '../services/api.dart';
import '../services/api_client.dart';

/// How often the report email goes (PAR-05, PAR-06). There is no push
/// service: this is the only note a grown-up gets.
enum ReportFrequency {
  each,
  weekly,
  off;

  bool get on => this != off;

  /// What the server says, read loosely: `each_session` today, `each` in
  /// the newer wording; a plain on/off answer counts too. Null when it
  /// is something this build doesn't know.
  static ReportFrequency? parse(Object? json) {
    if (json is Map) {
      final f = json['frequency'] ?? json['reportFrequency'];
      if (f != null) return parse(f);
      final on = json['enabled'] ?? json['emailOn'];
      if (on is bool) return on ? each : off;
      return null;
    }
    return switch ('$json'.toLowerCase()) {
      'each' || 'each_session' || 'after_each_session' => each,
      'weekly' || 'week' => weekly,
      'off' || 'none' || 'never' => off,
      _ => null,
    };
  }
}

/// The family's report email settings: `GET` and `PUT
/// /api/family/settings/reports` with `{"frequency": ...}`. Every call the
/// grown-up area makes about the email is here, so a change of the
/// server's wording is one file.
class ReportEmailRepository {
  ReportEmailRepository(this._client);

  final ApiClient _client;
  static const _path = '/api/family/settings/reports';

  /// Null when the server's answer isn't one this build knows.
  Future<ReportFrequency?> frequency() async =>
      ReportFrequency.parse(await _client.get(_path));

  /// Sends `each_session`, `weekly` or `off`. A server that refuses
  /// `each_session` as a bad value (400/422) gets the newer `each`.
  Future<void> setFrequency(ReportFrequency f) async {
    final wire = switch (f) {
      ReportFrequency.each => 'each_session',
      ReportFrequency.weekly => 'weekly',
      ReportFrequency.off => 'off',
    };
    try {
      await _client.put(_path, {'frequency': wire});
    } on ApiException catch (e) {
      if (f != ReportFrequency.each || (e.status != 400 && e.status != 422)) {
        rethrow;
      }
      await _client.put(_path, {'frequency': 'each'});
    }
  }
}
