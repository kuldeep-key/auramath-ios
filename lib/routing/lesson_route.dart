import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../data/models/child_settings.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/child_settings_repository.dart';
import '../data/repositories/grown_up_repository.dart';
import '../data/repositories/partner_intro_repository.dart';
import '../data/services/api.dart';
import '../data/services/sound_effects.dart';
import '../config/env.dart';
import '../deps.dart';
import '../ui/features/lesson/view_models/lesson_view_model.dart';
import '../ui/features/lesson/views/lesson_flow.dart';
import 'paths.dart';
import '../ui/core/motion/screen_motion.dart';
import '../ui/core/parts/journey_art.dart';

List<RouteBase> lessonRoutes(Deps deps) => [
  GoRoute(
    path: Paths.lessonNext,
    redirect: (context, state) async {
      // the case partner says what it is first, once per child (AI-07)
      if (deps.flags.on('case_partner_intro') &&
          !await PartnerIntroRepository(deps.store).met(deps.account.childId)) {
        return Paths.meetPartner;
      }
      final next = await deps.sessions.whereNext(
        deps.pack,
        childId: deps.account.childId,
      );
      // the server's next problem; a build on the bundled pack starts at
      // lemon
      final id =
          next?.problemId ??
          (Env.serverProblems ? LessonViewModel.newProblem : 'lemon');
      final resume = next?.resumeSessionId;
      // a case started on another phone: offer to carry on here first
      // (DEV-05); "Carry on here" comes back with ?here=1
      final elsewhere = next?.startedOn;
      if (elsewhere != null && state.uri.queryParameters['here'] == null) {
        return Uri(
          path: Paths.carryOn,
          queryParameters: {if (elsewhere.isNotEmpty) 'device': elsewhere},
        ).toString();
      }
      // a case whose session ended carries on in a new one (SES-01,
      // SES-04); the time on Choose today goes along (LES-14)
      final carry = next?.carryFrom;
      final ms = state.uri.queryParameters['ms'];
      return Uri(
        path: Paths.lesson(id),
        queryParameters: resume != null
            ? {'resume': resume}
            : {'s': const Uuid().v4(), 'carry': ?carry, 'today': ?ms},
      ).toString();
    },
  ),
  GoRoute(
    path: '/lesson/:problemId',
    pageBuilder: (context, state) => MotionPage(
      key: state.pageKey,
      arrive: Arrive.fade,
      child: _LessonRoute(
        // The whole URI: each visit carries its own `?s=`, so going to the
        // same problem again still builds a fresh lesson.
        key: ValueKey(state.uri.toString()),
        problemId: state.pathParameters['problemId']!,
        resumeSessionId: state.uri.queryParameters['resume'],
        carryFrom: state.uri.queryParameters['carry'],
        chosenMs: int.tryParse(state.uri.queryParameters['today'] ?? ''),
        deps: deps,
      ),
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
    this.carryFrom,
    this.chosenMs,
  });

  final String problemId;

  /// Set when reopening a case that was left part way.
  final String? resumeSessionId;

  /// Set when carrying on a case whose session ended (SES-01, SES-04).
  final String? carryFrom;

  /// The story problem was picked on Choose today, after this long there
  /// (LES-14).
  final int? chosenMs;
  final Deps deps;

  @override
  State<_LessonRoute> createState() => _LessonRouteState();
}

class _LessonRouteState extends State<_LessonRoute> {
  late final _vm = LessonViewModel(
    pack: widget.deps.pack,
    problemId: widget.problemId,
    sessionId: widget.resumeSessionId,
    sessions: widget.deps.sessions,
    voice: widget.deps.voice,
    // REW-01: the sitting's open session, else a new one
    openSession: _open,
    nextProblem: Env.serverProblems
        ? (sessionId, {level}) => widget.deps.sessions.nextProblem(
            widget.deps.pack,
            sessionId,
            level: level,
          )
        : null,
    sitting: widget.deps.sitting,
  );

  late final AppLifecycleListener _lifecycle;

  /// The sitting's open session, else a new one; a new one says what is
  /// left of the child's day (SES-01) and the settings it runs with
  /// (PAR-05), which the lesson then runs with.
  Future<String> _open() async {
    final deps = widget.deps;
    final id = await deps.sessions.openOrGoOn(childId: deps.account.childId);
    if (deps.sessions.takeDailyTime(id) case final day?) {
      deps.sitting.runFor(day.capMs);
    }
    if (deps.sessions.takeSettings(id) case final s?) {
      await ChildSettingsRepository(deps.client, deps.store).remember(s);
      _vm.readAloud = deps.flags.on('read_aloud') && s.readAloud;
    }
    return id;
  }

  @override
  void initState() {
    super.initState();
    _begin();
    // The phone locks or the app goes away: pause, and don't count the time.
    _lifecycle = AppLifecycleListener(
      onPause: _vm.paused,
      onResume: _vm.resumed,
    );
  }

  /// The child's settings from the server (PAR-05), this phone's bigger
  /// pad and the server's flags, then the lesson.
  Future<void> _begin() async {
    final deps = widget.deps;
    await deps.flags.refresh();
    final prefs = await GrownUpRepository(deps.client, deps.store).loadPrefs();
    final settings = await _settings();
    final flags = deps.flags;
    final age = settings == null || flags.on('self_rating')
        ? await _childAge()
        : null;
    if (!mounted) return;
    // the sound effects follow the grown-up's read-aloud, once it is set
    if (settings != null && !settings.readAloudIsDefault) {
      AuraSound.soundOn.value = settings.readAloud;
    }
    _vm
      // the server's read-aloud has the flag and the age default in it;
      // without it, the age default (TTR-03): off for every age since
      // 20 Nov, and off when the age isn't known
      ..readAloud =
          flags.on('read_aloud') &&
          (settings?.readAloud ??
              (age != null && flags.readAloudAges.contains(age)))
      ..readQuestionAloud = flags.on('read_question_aloud')
      ..readAloudFlag = flags.on('read_aloud')
      ..barSenseLessons = flags.on('bar_sense_side_lessons')
      // D-51: no badge after each case. The big badges come from the
      // server's rewards (the stop medal, habit and land badges) and the
      // session badge at the end (REW-01), so the v4 case badge stays off
      ..showBadges = false
      ..selfRating = flags.on('self_rating')
      ..childQuestions = flags.on('child_questions')
      ..wordMeanings = flags.on('word_meanings')
      ..weightStories = flags.on('weight_stories')
      ..selfRatingMinAge = flags.selfRatingMinAge
      ..childAge = age
      ..askDecisions = Env.serverProblems
      ..actOnDecisions = flags.on('ai_decisions')
      ..readAgainPrompt = flags.on('read_again_prompt')
      ..seenBeforeBridge = flags.on('seen_before_bridge')
      ..cueAfterMs = deps.config.cueAfterMs
      ..fallbackAfterMs = deps.config.fallbackAfterMs
      ..clockPausesOffline = deps.config.clockPausesWhileOffline
      ..childId = deps.account.childId
      ..tutorId = _tutor.id
      ..tutorKind = _tutor.kind
      ..launchSource = deps.account.role == Role.parent
          ? 'parent_handover'
          : 'child_opened'
      ..biggerPad = prefs.biggerPad
      ..carryFrom = widget.carryFrom
      ..chosenToday = widget.chosenMs
      ..chooseToday = flags.on('quick_sums');
    // the template's optional steps, each behind its flag (LES-03)
    _vm.enableSteps({
      for (final step in const ['name_quantities', 'number_sentence'])
        if (flags.on(step)) step,
    }, addingUp: flags.on('adding_up_option'));
    // each child's own day's time, not the phone's (SES-01)
    await widget.deps.sitting.forChild(deps.account.childId);
    // a case after the first in a sitting keeps the cap the sitting opened
    // with: the session cap counts from then, not from each case (SES-01)
    final goesOn = deps.sessions.sittingOpen(deps.account.childId);
    // the grown-up's time each day, as the server keeps it (PAR-05)
    if (!goesOn) widget.deps.sitting.useMinutes(settings?.dailyLimitMinutes);
    if (!mounted) return;
    // SES-01: what is left of the child's day on every family phone; with
    // none left the server opens no lesson, so none is asked for
    if (settings?.today case final today?) {
      if (today.timesUp) return _vm.timesUpBeforeStart();
      if (!goesOn) widget.deps.sitting.runFor(today.capMs);
    }
    await (widget.resumeSessionId != null ? _vm.restore() : _vm.start());
  }

  /// The child's time each day and read-aloud (PAR-05): the server's,
  /// else what this phone kept from it; null when neither is known.
  Future<ChildSettings?> _settings() async {
    final id = widget.deps.account.childId;
    if (id == null) return null;
    final repo = ChildSettingsRepository(widget.deps.client, widget.deps.store);
    try {
      return await repo.load(id);
    } on ApiException {
      return repo.cached(id);
    }
  }

  /// The child's age, which sets read-aloud's default; null when it can't
  /// be read (then read-aloud is off, its default since 20 Nov).
  Future<int?> _childAge() async {
    try {
      final kids = await widget.deps.family.children();
      return kids
          .where((c) => c.id == widget.deps.account.childId)
          .firstOrNull
          ?.age;
    } on ApiException {
      return null;
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TutorScope(
    // the child's tutor talks in the lesson header (TTR-05)
    tutorId: _tutor.id,
    kind: _tutor.kind,
    child: _flow(context),
  );

  /// The child's chosen tutor, else tutors.yaml's default.
  ({String id, String kind}) get _tutor {
    final deps = widget.deps;
    final config = deps.journey;
    final id = deps.looks.cached(deps.account.childId)?.tutorId;
    final t =
        config.pickable.where((t) => t.id == id).firstOrNull ??
        config.tutorById(config.defaultTutor);
    return (
      id: t?.id ?? config.defaultTutor,
      kind: t?.kind ?? 'grown_up_teacher',
    );
  }

  Widget _flow(BuildContext context) => LessonFlow(
    vm: _vm,
    onHome: () => context.go(Paths.home),
    // past the cap, a finished problem ends the sitting instead of starting
    // one; a next case the server couldn't send yet is asked for again
    onFinished: (next) => context.go(
      widget.deps.sitting.over
          ? Paths.home
          : next == LessonViewModel.newProblem
          ? Paths.lessonNext
          : Paths.afterCaseNext(next),
    ),
  );
}
