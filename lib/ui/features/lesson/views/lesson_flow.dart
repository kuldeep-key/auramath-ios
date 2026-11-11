import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/paths.dart';
import '../../child_home/views/choose_today_screen.dart';
import '../../child_home/views/welcome_back_screen.dart';

import '../view_models/lesson_view_model.dart';
import 'bar_sense_view.dart';
import 'board_view.dart';
import 'break_views.dart';
import 'question_overlay.dart';
import 'question_view.dart';
import 'word_meaning.dart';
import 'side_lesson_view.dart';
import 'solved_view.dart';
import 'starting_check_view.dart';
import 'worked_example_view.dart';

/// One lesson, start to finish: picks the screen for the engine's step.
/// Figma: M0, M1, D1–D6, H0, T1, S1/S2, J17, Y2, Y3, M1-pause, TU; the
/// starting check has no frame yet.
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
      if (vm.offerLeft case final left?) {
        return Scaffold(
          body: OfferLeftView(
            problem: left,
            onAgain: () => vm.takeLeft(again: true),
            onNew: () => vm.takeLeft(again: false),
          ),
        );
      }
      if (vm.inStartingCheck) {
        return Scaffold(
          body: SafeArea(
            child: StartingCheckView(
              vm: vm,
              onHome: () async {
                await vm.leave();
                onHome();
              },
            ),
          ),
        );
      }
      if (vm.welcomingBack case final w?) {
        // SES-07: back on a later day, as the server counts it
        return WelcomeBackScreen(
          name: null,
          caseWaiting: w.caseWaiting,
          onCarryOn: vm.welcomedBack,
        );
      }
      if (vm.choosingToday) {
        // LES-14: the starting check just placed the child
        return ChooseTodayScreen(
          suggestQuickSums: vm.suggestQuickSums,
          onStory: vm.chooseStory,
          onQuick: (ms) async {
            await vm.chooseQuickSums(ms);
            if (context.mounted) context.go(Paths.quickSums);
          },
          onHome: () async {
            await vm.leave();
            onHome();
          },
        );
      }
      if (!vm.ready) {
        final error = vm.startError;
        return error == null
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            // a new session's 409: the family has no child yet
            : error.status == 409
            ? Scaffold(body: NoChildYetView(onOk: onHome))
            // 403: consent was withdrawn, so lessons are paused
            : error.status == 403
            ? Scaffold(body: LessonsPausedView(onOk: onHome))
            : NeedInternetView(
                // an answer from the server is its own message; no answer
                // is the plain "check the Wi-Fi"
                detail: error.offline ? null : error.message,
                onRetry: vm.start,
                onGoHome: onHome,
              );
      }
      if (vm.offerSound) {
        // read-aloud is off: sound on, or I'll read it myself (NFR-06)
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted || !vm.offerSound) return;
          vm.soundOffered();
          final choice = await context.push<String>(Paths.sound);
          await vm.soundAnswered(choice);
        });
      }
      if (vm.askVoiceResting) {
        // once, between frames: "My voice is resting", then big words
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted || !vm.askVoiceResting) return;
          vm.toldVoiceResting();
          context.push(Paths.noVoice);
        });
      }
      if (vm.endedByServer) {
        return Scaffold(
          body: vm.pausedByConsent
              // consent withdrawn mid-lesson, as at the start
              ? LessonsPausedView(onOk: onHome)
              : KeptForNextTimeView(onOk: onHome),
        );
      }
      if (vm.timeUp) {
        return Scaffold(
          body: TimeUpView(
            onStop: () async {
              vm.promptAnswered('time_up', 'call_it_a_day');
              await vm.callItADay();
              onHome();
            },
            onFinish: vm.canFinish
                ? () {
                    vm.promptAnswered('time_up', 'finish_this_one');
                    vm.finishThisOne();
                  }
                : null,
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
                            // bars the wrong way round, with the flag on:
                            // Julia's bar-sense lessons (TUT-17, draft)
                            LessonStep.sideLesson
                                when vm.sideLesson == SideLesson.readRelation &&
                                    vm.barSenseLessons =>
                              BarSenseView(vm: vm, onHome: vm.askBreak),
                            // a detour on reading the story (TUT-08): the
                            // smaller worked example, then back
                            LessonStep.sideLesson
                                when vm.sideLesson?.arithmetic == false =>
                              WorkedExampleView(vm: vm, onHome: vm.askBreak),
                            LessonStep.sideLesson => SideLessonView(
                              vm: vm,
                              onHome: vm.askBreak,
                            ),
                            _ => BoardView(
                              vm: vm,
                              onHome: vm.askBreak,
                              onLeave: () async {
                                await vm.leaveProblem();
                                onFinished(LessonViewModel.newProblem);
                              },
                            ),
                          },
                  ),
                  if (vm.questionOpen) QuestionOverlay(vm: vm),
                  if (vm.wordOpen case final word?)
                    WordMeaningSheet(vm: vm, word: word),
                  if (!vm.online)
                    LostInternetPause(
                      onRetry: () {
                        vm.promptAnswered('offline', 'try_again');
                        vm.retryConnection();
                      },
                      onGoHome: () async {
                        vm.promptAnswered('offline', 'stop_for_today');
                        await vm.leave();
                        onHome();
                      },
                    ),
                  if (vm.askingBreak)
                    BreakSheet(
                      onKeepGoing: () {
                        vm.promptAnswered('paused', 'keep_going');
                        vm.keepGoing();
                      },
                      onGoHome: () async {
                        vm.promptAnswered('paused', 'stop_for_today');
                        await vm.leave();
                        onHome();
                      },
                      onLeave: () async {
                        vm.promptAnswered('paused', 'leave');
                        await vm.leaveProblem();
                        onFinished(LessonViewModel.newProblem);
                      },
                    ),
                ],
              ),
      );
    },
  );
}
