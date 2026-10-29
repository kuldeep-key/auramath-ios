import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../view_models/lesson_view_model.dart';
import 'board_view.dart';
import 'break_views.dart';
import 'question_view.dart';
import 'side_lesson_view.dart';
import 'solved_view.dart';
import 'worked_example_view.dart';

/// One lesson, start to finish: picks the screen for the engine's step.
/// Figma: M0, M1, D1–D6, H0, T1, S1/S2, J17, Y2, Y3, M1-pause, TU.
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
    builder: (context, _) {
      if (!vm.ready) {
        final error = vm.startError;
        return error == null
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : NeedInternetView(
                // an answer from the server is its own message; no answer
                // is the plain "check the Wi-Fi"
                detail: error.offline ? null : error.message,
                onRetry: vm.start,
                onGoHome: onHome,
              );
      }
      if (vm.timeUp) {
        return Scaffold(
          body: TimeUpView(
            onStop: () async {
              await vm.callItADay();
              onHome();
            },
            onFinish: vm.finishThisOne,
          ),
        );
      }
      return Scaffold(
        // the celebration paints edge to edge and keeps its own safe area
        body: vm.state.step == LessonStep.solved
            ? SolvedView(vm: vm, onFinished: onFinished)
            : Stack(
                children: [
                  SafeArea(
                    child: vm.showingExample
                        ? WorkedExampleView(vm: vm, onHome: vm.askBreak)
                        : switch (vm.state.step) {
                            LessonStep.question => QuestionView(
                              key: ValueKey(vm.sessionId),
                              vm: vm,
                              onHome: vm.askBreak,
                            ),
                            LessonStep.sideLesson => SideLessonView(
                              vm: vm,
                              onHome: vm.askBreak,
                            ),
                            _ => BoardView(vm: vm, onHome: vm.askBreak),
                          },
                  ),
                  if (!vm.online)
                    LostInternetPause(
                      onRetry: vm.retryConnection,
                      onGoHome: () async {
                        await vm.leave();
                        onHome();
                      },
                    ),
                  if (vm.askingBreak)
                    BreakSheet(
                      onKeepGoing: vm.keepGoing,
                      onGoHome: () async {
                        await vm.leave();
                        onHome();
                      },
                    ),
                ],
              ),
      );
    },
  );
}
