import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'data/repositories/session_repository.dart';
import 'data/services/voice.dart';
import 'ui/features/child_home/views/home_screen.dart';
import 'ui/features/lesson/view_models/lesson_view_model.dart';
import 'ui/features/lesson/views/lesson_flow.dart';

GoRouter buildRouter({
  required SessionRepository sessions,
  required Pack pack,
  required Voice voice,
}) => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, _) => HomeScreen(
        onKeepGoing: () async {
          final next = await sessions.whereNext(pack);
          if (!context.mounted) return;
          // ponytail: lemon is the first case until setup picks a starting level
          final id = next?.problemId ?? 'lemon';
          final resume = next?.resumeSessionId;
          context.go(
            resume == null
                ? '/lesson/$id?s=${_LessonRouteState._uuid.v4()}'
                : '/lesson/$id?resume=$resume',
          );
        },
      ),
    ),
    GoRoute(
      path: '/lesson/:problemId',
      builder: (context, state) => _LessonRoute(
        // The whole URI: each visit carries its own `?s=`, so going to the
        // same problem again still builds a fresh lesson.
        key: ValueKey(state.uri.toString()),
        problemId: state.pathParameters['problemId']!,
        resumeSessionId: state.uri.queryParameters['resume'],
        sessions: sessions,
        pack: pack,
        voice: voice,
      ),
    ),
  ],
);

/// Owns one lesson's view model for as long as the lesson is on screen.
class _LessonRoute extends StatefulWidget {
  const _LessonRoute({
    super.key,
    required this.problemId,
    required this.resumeSessionId,
    required this.sessions,
    required this.pack,
    required this.voice,
  });

  final String problemId;

  /// Set when reopening a case that was left part way.
  final String? resumeSessionId;
  final SessionRepository sessions;
  final Pack pack;
  final Voice voice;

  @override
  State<_LessonRoute> createState() => _LessonRouteState();
}

class _LessonRouteState extends State<_LessonRoute> {
  static const _uuid = Uuid();

  late final _vm = LessonViewModel(
    pack: widget.pack,
    problemId: widget.problemId,
    sessionId: widget.resumeSessionId ?? _uuid.v4(),
    sessions: widget.sessions,
    voice: widget.voice,
    newSessionId: _uuid.v4,
  );

  @override
  void initState() {
    super.initState();
    widget.resumeSessionId != null ? _vm.restore() : _vm.start();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LessonFlow(
    vm: _vm,
    onHome: () => context.go('/'),
    onFinished: (next) => context.go('/lesson/$next?s=${_uuid.v4()}'),
  );
}
