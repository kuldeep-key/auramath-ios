import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lesson_event.dart';
import 'api.dart';

/// JSON over HTTPS to the record service. Every failure is an
/// [ApiException]: no answer gives `status: null`, a non-2xx answer gives
/// its status and the server's `{"error": ...}` message.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.bearer,
    http.Client? client,
    this.onUnauthorized,
    this.timeout = const Duration(seconds: 15),
  }) : _http = client ?? http.Client();

  final String baseUrl;

  /// The token to send, read on every call: it changes on sign-in.
  final String? Function() bearer;

  /// A 401: the token was revoked (a removed phone) or has expired.
  final void Function()? onUnauthorized;
  final Duration timeout;
  final http.Client _http;

  Future<Object?> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<Object?> post(String path, [Object? body]) =>
      _send('POST', path, body: body);

  Future<Object?> put(String path, [Object? body]) =>
      _send('PUT', path, body: body);

  Future<Object?> delete(String path) => _send('DELETE', path);

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final request = http.Request(
      method,
      Uri.parse('$baseUrl$path').replace(queryParameters: query),
    );
    final token = bearer();
    request.headers.addAll({
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(timeout),
      );
    } on Exception catch (e) {
      // socket, TLS, timeout: the server never answered
      throw ApiException("Can't reach the server ($e)");
    }

    final text = response.body;
    final Object? json;
    try {
      json = text.isEmpty ? null : jsonDecode(text);
    } on FormatException {
      throw ApiException(
        'The server sent something that is not JSON',
        status: response.statusCode,
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return json;

    if (response.statusCode == 401) onUnauthorized?.call();
    final message = json is Map && json['error'] is String
        ? json['error']! as String
        : 'HTTP ${response.statusCode}';
    throw ApiException(message, status: response.statusCode);
  }

  void close() => _http.close();
}

/// The lesson's calls, over [ApiClient].
class HttpApi implements Api {
  HttpApi(this._client);

  final ApiClient _client;

  @override
  Future<({String sessionId, String childRef})> startSession({
    String? childId,
    required bool isDemo,
  }) async {
    final json =
        await _client.post('/api/sessions', {
              'childId': ?childId,
              'isDemo': isDemo,
            })
            as Map<String, Object?>;
    return (
      sessionId: json['id']! as String,
      childRef: json['childRef']! as String,
    );
  }

  @override
  Future<({List<LessonEvent> events, bool sameDevice, String? startedOn})?>
  resumable({String? childId}) async {
    final json =
        await _client.get(
              '/api/sessions/resumable',
              query: {'childId': ?childId},
            )
            as Map<String, Object?>;
    final events = [
      for (final e in json['events']! as List)
        // spec events only: the old web client's events can't be replayed
        if ((e as Map<String, Object?>)['event_id'] != null)
          LessonEvent.fromJson(e),
    ];
    if (json['session'] == null || events.isEmpty) return null;
    final offer = json['resume'] as Map<String, Object?>?;
    final on = offer?['startedOn'] as Map<String, Object?>?;
    return (
      events: events,
      sameDevice: offer?['sameDevice'] == true,
      startedOn: on?['label'] as String?,
    );
  }

  @override
  Future<void> sendEvents(String sessionId, List<LessonEvent> events) async {
    final json =
        await _client.post('/api/sessions/$sessionId/events', {
              'events': [for (final e in events) e.toJson()],
            })
            as Map<String, Object?>;
    final rejected = json['rejected'];
    // A refused event is a bug in the app or a contract change: retrying
    // can't fix it, so it surfaces instead of being dropped.
    if (rejected is List && rejected.isNotEmpty) {
      throw ApiException(
        'The server refused ${rejected.length} event(s): '
        '${rejected.map((r) => '${(r as Map)['name']}: ${r['reasons']}').join('; ')}',
        status: 422,
      );
    }
  }
}
