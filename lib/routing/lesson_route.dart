import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../deps.dart';
import '../ui/features/lesson/view_models/lesson_view_model.dart';
import '../ui/features/lesson/views/lesson_flow.dart';
import 'paths.dart';

List<RouteBase> lessonRoutes(Deps deps) => [
  GoRoute(
    path: Paths.lessonNext,
    redirect: (context, state) async {
      final next = await deps.sessions.whereNext(deps.pack);
      // ponytail: lemon is the first case until the server says the level
      final id = next?.problemId ?? 'lemon';
      final resume = next?.resumeSessionId;
      return resume == null
          ? '${Paths.lesson(id)}?s=${const Uuid().v4()}'
          : '${Paths.lesson(id)}?resume=$resume';
    },
  ),
  GoRoute(
    path: '/lesson/:problemId',
    builder: (context, state) => _LessonRoute(
      // The whole URI: each visit carries its own `?s=`, so going to the
      // same problem again still builds a fresh lesson.
      key: ValueKey(state.uri.toString()),
      problemId: state.pathParameters['problemId']!,
      resumeSessionId: state.uri.queryParameters['resume'],
      deps: deps,
    ),
  ),
];

/// Owns one lesson's view model for as long as the lesson is on screen.
class _LessonRoute extends StatefulWidget {
  const _LessonRoute({
    super.key,
    required this.problemId,
    required this.resumeSessionId,
    required this.deps,
  });

  final String problemId;

  /// Set when reopening a case that was left part way.
  final String? resumeSessionId;
  final Deps deps;

  @override
  State<_LessonRoute> createState() => _LessonRouteState();
}

class _LessonRouteState extends State<_LessonRoute> {
  static const _uuid = Uuid();

  late final _vm = LessonViewModel(
    pack: widget.deps.pack,
    problemId: widget.problemId,
    sessionId: widget.resumeSessionId ?? _uuid.v4(),
    sessions: widget.deps.sessions,
    voice: widget.deps.voice,
    newSessionId: _uuid.v4,
    sitting: widget.deps.sitting,
  );

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    widget.resumeSessionId != null ? _vm.restore() : _vm.start();
    // The phone locks or the app goes away: pause, and don't count the time.
    _lifecycle = AppLifecycleListener(
      onPause: _vm.paused,
      onResume: _vm.resumed,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LessonFlow(
    vm: _vm,
    onHome: () => context.go(Paths.home),
    // past the cap, a finished problem ends the sitting instead of starting one
    onFinished: (next) => context.go(
      widget.deps.sitting.over ? Paths.home : Paths.afterCaseNext(next),
    ),
  );
}
