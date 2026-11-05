import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'api.dart';
import 'api_client.dart';

/// Crashes and errors, sent to `POST /api/app-errors` with whichever token
/// the phone holds. Held until there is one; at most 20 a call and about
/// one call every 6 min (the server allows ~10 an hour). Never the child's
/// name or work: messages are the app's own.
class ErrorReporter {
  ErrorReporter(
    this._client, {
    required this.hasToken,
    required this.appVersion,
    required this.platform,
    required this.osVersion,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ApiClient _client;
  final bool Function() hasToken;
  final String appVersion;
  final String platform;
  final String osVersion;
  final DateTime Function() _now;

  static const perCall = 20;
  static const gap = Duration(minutes: 6);

  /// More than this and the oldest go: a crash loop shouldn't fill memory.
  static const held = 100;

  final List<Map<String, Object?>> pending = [];
  DateTime? _lastSent;
  Timer? _timer;

  /// [kind] is `crash`, `error`, `network`, `render` or `other`.
  void report(
    String kind,
    String message, {
    String? stack,
    String? screen,
    String? sessionId,
  }) {
    pending.add({
      'kind': kind,
      'message': message,
      'stack': ?stack,
      'at': _now().millisecondsSinceEpoch,
      'appVersion': appVersion,
      'platform': platform,
      'osVersion': osVersion,
      'screen': ?screen,
      'sessionId': ?sessionId,
    });
    if (pending.length > held) pending.removeRange(0, pending.length - held);
    schedule();
  }

  /// Sends soon: 10 s from now, or once the gap since the last call is up.
  void schedule() {
    if (_timer != null || pending.isEmpty) return;
    final since = _lastSent == null ? gap : _now().difference(_lastSent!);
    final wait = Duration(
      milliseconds: math.max(10000, (gap - since).inMilliseconds),
    );
    _timer = Timer(wait, () {
      _timer = null;
      flush();
    });
  }

  Future<void> flush() async {
    if (pending.isEmpty || !hasToken()) return;
    final batch = pending.take(perCall).toList();
    try {
      await _client.post('/api/app-errors', {'errors': batch});
      pending.removeRange(0, batch.length);
      _lastSent = _now();
    } on ApiException catch (e) {
      // kept for the next try; reporting the reporter would loop
      debugPrint('app errors not sent: $e');
      _lastSent = _now();
    }
    schedule();
  }

  void dispose() => _timer?.cancel();
}
