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

  /// A GET that sends the [etag] held: null when the server says it is
  /// unchanged (304), else the new JSON and its ETag.
  Future<({Object? json, String? etag})?> getIfChanged(
    String path, {
    String? etag,
  }) async {
    String? fresh;
    try {
      final json = await _send(
        'GET',
        path,
        headers: {'If-None-Match': ?etag},
        onResponse: (r) => fresh = r.headers['etag'],
      );
      return (json: json, etag: fresh);
    } on ApiException catch (e) {
      if (e.status == 304) return null;
      rethrow;
    }
  }

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
    void Function(http.Response)? onResponse,
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
      ...?headers,
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
    onResponse?.call(response);

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
  Future<StartedSession> startSession({
    String? childId,
    required bool isDemo,
  }) async {
    final json =
        await _client.post('/api/sessions', {
              'childId': ?childId,
              'isDemo': isDemo,
            })
            as Map<String, Object?>;
    final check = json['spacedCheckDue'] as Map<String, Object?>?;
    return (
      sessionId: json['id']! as String,
      childRef: json['childRef']! as String,
      checkLevel: check?['level'] as String?,
      leftProblem: json['leftProblem'] as Map<String, Object?>?,
    );
  }

  @override
  Future<Map<String, Object?>> nextProblem(
    String sessionId, {
    String? level,
  }) async {
    final json =
        await _client.post('/api/sessions/$sessionId/problems/next', {
              'level': ?level,
            })
            as Map<String, Object?>;
    return json['problem']! as Map<String, Object?>;
  }

  @override
  Future<Map<String, Object?>> decide(
    String sessionId,
    Map<String, Object?> body,
  ) async =>
      await _client.post('/api/sessions/$sessionId/decisions', body)
          as Map<String, Object?>;

  @override
  Future<OpenCase?> resumable({String? childId}) async {
    final json =
        await _client.get(
              '/api/sessions/resumable',
              query: {'childId': ?childId},
            )
            as Map<String, Object?>;
    final session = json['session'] as Map<String, Object?>?;
    if (session == null) return null;
    // The record serves stored events in camelCase and without their
    // session id; only spec events (with an event id) can be replayed.
    final events = [
      for (final e in (json['events']! as List).cast<Map<String, Object?>>())
        if (e['eventId'] != null)
          LessonEvent(
            eventId: e['eventId']! as String,
            sessionId: session['id']! as String,
            seq: e['seq']! as int,
            at: e['at']! as int,
            name: e['name']! as String,
            childRef: e['childRef']! as String,
            deviceId: e['deviceId']! as String,
            appVersion: e['appVersion']! as String,
            payload: e['payload']! as Map<String, Object?>,
          ),
    ];
    if (events.isEmpty) return null;
    final offer = json['resume'] as Map<String, Object?>?;
    final on = offer?['startedOn'] as Map<String, Object?>?;
    return (
      events: events,
      sameDevice: offer?['sameDevice'] == true,
      startedOn: on?['label'] as String?,
      closed: offer?['closed'] != null,
    );
  }

  @override
  Future<EventsReply> sendEvents(
    String sessionId,
    List<LessonEvent> events,
  ) async {
    final Map<String, Object?> json;
    try {
      json =
          await _client.post('/api/sessions/$sessionId/events', {
                'events': [for (final e in events) e.toJson()],
              })
              as Map<String, Object?>;
    } on ApiException catch (e) {
      // the lesson's log is full: nothing more is stored for it
      if (e.status == 413) return (rejected: const <String>[], ended: 'full');
      rethrow;
    }
    final ended = json['sessionEnded'] as Map<String, Object?>?;
    return (
      rejected: [
        for (final r in (json['rejected'] as List? ?? []).cast<Map>())
          '${r['name']}: ${r['reasons']}',
      ],
      ended: ended == null ? null : '${ended['reason']}',
    );
  }
}
