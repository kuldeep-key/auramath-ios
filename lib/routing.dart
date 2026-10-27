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
      builder: (context, _) =>
          HomeScreen(onKeepGoing: () => context.go('/lesson/lemon')),
    ),
    GoRoute(
      path: '/lesson/:problemId',
      builder: (context, state) => _LessonRoute(
        key: ValueKey(state.pathParameters['problemId']),
        problemId: state.pathParameters['problemId']!,
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
    required this.sessions,
    required this.pack,
    required this.voice,
  });

  final String problemId;
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
    sessionId: _uuid.v4(),
    sessions: widget.sessions,
    voice: widget.voice,
    newSessionId: _uuid.v4,
  );

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LessonFlow(
    vm: _vm,
    onHome: () => context.go('/'),
    onFinished: (next) => context.go('/lesson/$next'),
  );
}
