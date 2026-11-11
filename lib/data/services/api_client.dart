import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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

  /// Changes only the fields in [body] (`PATCH /api/children/{id}`).
  Future<Object?> patch(String path, Object? body) =>
      _send('PATCH', path, body: body);

  Future<Object?> delete(String path) => _send('DELETE', path);

  /// A POST whose answer is bytes, not JSON (read-aloud audio). Failures are
  /// [ApiException]s as for JSON calls.
  Future<Uint8List> postBytes(
    String path,
    Object body, {
    Duration? timeout,
  }) async {
    final request = http.Request('POST', Uri.parse('$baseUrl$path'));
    final token = bearer();
    request.headers.addAll({
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.body = jsonEncode(body);

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(timeout ?? this.timeout),
      );
    } on Exception catch (e) {
      throw ApiException("Can't reach the server ($e)");
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    if (response.statusCode == 401) onUnauthorized?.call();
    String message = 'HTTP ${response.statusCode}';
    try {
      final json = jsonDecode(response.body);
      if (json is Map && json['error'] is String) {
        message = json['error'] as String;
      }
    } on FormatException {
      // not JSON: keep the status line
    }
    throw ApiException(message, status: response.statusCode);
  }

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
    final retest = json['retestDue'] as Map<String, Object?>?;
    return (
      sessionId: json['id']! as String,
      childRef: json['childRef']! as String,
      checkLevel: check?['level'] as String?,
      retestDueAt: retest?['dueAt'] as int?,
      startingCheckDue: json['startingCheckDue'] == true,
      leftProblem: json['leftProblem'] as Map<String, Object?>?,
      reviewDue: [
        for (final r in json['reviewDue'] as List? ?? const [])
          if (r is Map) r.cast<String, Object?>(),
      ],
      sittingId: json['sittingId'] as String?,
      todaySuggestion: todaySuggestionFromJson(json['todaySuggestion']),
    );
  }

  @override
  Future<Map<String, Object?>> nextProblem(
    String sessionId, {
    String? level,
    bool easier = false,
    String? templateId,
  }) async {
    final json =
        await _client.post('/api/sessions/$sessionId/problems/next', {
              'level': ?level,
              if (easier) 'easier': true,
              'templateId': ?templateId,
            })
            as Map<String, Object?>;
    final problem = json['problem']! as Map<String, Object?>;
    // SKL-05: the selector rule that chose it, kept with it for the record
    final selector = json['selector'];
    return selector is Map ? {...problem, 'selector': selector} : problem;
  }

  @override
  Future<Map<String, Object?>> decide(
    String sessionId,
    Map<String, Object?> body,
  ) async =>
      await _client.post('/api/sessions/$sessionId/decisions', body)
          as Map<String, Object?>;

  @override
  Future<List<Map<String, Object?>>> arithmetic(
    String childId, {
    required String purpose,
    String? level,
  }) async {
    final json = await _client.post('/api/children/$childId/arithmetic', {
      'purpose': purpose,
      'level': ?level,
    });
    final items = (json as Map<String, Object?>)['items']! as List;
    return [for (final i in items) (i as Map).cast<String, Object?>()];
  }

  @override
  Future<String> startingCheck(String childId, {required int correct}) async {
    final json =
        await _client.post('/api/children/$childId/starting-check', {
              'correct': correct,
            })
            as Map<String, Object?>;
    return json['level']! as String;
  }

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
    final events = _specEvents(session['id']! as String, json['events']);
    if (events.isEmpty) return null;
    final offer = json['resume'] as Map<String, Object?>?;
    final on = offer?['startedOn'] as Map<String, Object?>?;
    final closed = offer?['closed'] as Map<String, Object?>?;
    return (
      events: events,
      sameDevice: offer?['sameDevice'] == true,
      startedOn: on?['label'] as String?,
      closed: closed != null,
      closedReason: closed?['reason'] as String?,
      carried: [
        for (final c in offer?['carried'] as List? ?? const [])
          if (c is Map && c['sessionId'] is String)
            _specEvents(c['sessionId'] as String, c['events']),
      ],
    );
  }

  /// The record serves stored events in camelCase and without their
  /// session id; only spec events (with an event id) can be replayed.
  static List<LessonEvent> _specEvents(String sessionId, Object? raw) => [
    for (final e in (raw as List? ?? const []).cast<Map<String, Object?>>())
      if (e['eventId'] != null)
        LessonEvent(
          eventId: e['eventId']! as String,
          sessionId: sessionId,
          seq: e['seq']! as int,
          at: e['at']! as int,
          name: e['name']! as String,
          childRef: e['childRef']! as String,
          deviceId: e['deviceId']! as String,
          appVersion: e['appVersion']! as String,
          payload: e['payload']! as Map<String, Object?>,
        ),
  ];

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
      if (e.status == 413) {
        return (
          rejected: const <String>[],
          ended: 'full',
          continuedIn: null,
          badge: null,
        );
      }
      // consent withdrawn (the events route's only 403): nothing more may
      // be stored, so lessons are paused, not offline
      if (e.status == 403) {
        return (
          rejected: const <String>[],
          ended: 'consent',
          continuedIn: null,
          badge: null,
        );
      }
      rethrow;
    }
    final ended = json['sessionEnded'] as Map<String, Object?>?;
    final continued = json['continuedIn'] as Map<String, Object?>?;
    return (
      rejected: [
        for (final r in (json['rejected'] as List? ?? []).cast<Map>())
          '${r['name']}: ${r['reasons']}',
      ],
      ended: ended == null ? null : '${ended['reason']}',
      continuedIn: continued?['sessionId'] as String?,
      badge: badgeFromJson(json['badge']),
    );
  }
}
