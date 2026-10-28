import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../view_models/lesson_view_model.dart';
import 'board_view.dart';
import 'question_view.dart';
import 'side_lesson_view.dart';
import 'solved_view.dart';

/// One lesson, start to finish: picks the screen for the engine's step.
/// Figma: M0, M1, D1–D6, H0, T1, S1/S2, J17, Y2, Y3.
class LessonFlow extends StatelessWidget {
  const LessonFlow({
    super.key,
    required this.vm,
    required this.onHome,
    required this.onFinished,
  });

  final LessonViewModel vm;
  final VoidCallback onHome;

  /// Called with the next problem the engine chose.
  final ValueChanged<String> onFinished;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: vm,
    builder: (context, _) => Scaffold(
      // the celebration paints edge to edge and keeps its own safe area
      body: vm.state.step == LessonStep.solved
          ? SolvedView(vm: vm, onFinished: onFinished)
          : SafeArea(
              child: switch (vm.state.step) {
                LessonStep.question => QuestionView(
                  key: ValueKey(vm.sessionId),
                  vm: vm,
                  onHome: onHome,
                ),
                LessonStep.sideLesson => SideLessonView(vm: vm, onHome: onHome),
                _ => BoardView(vm: vm, onHome: onHome),
              },
            ),
    ),
  );
}
