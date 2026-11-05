import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/repositories/progress_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';
import 'badge_disc.dart';
import 'play_moment.dart';
import 'trail_screen.dart';

enum _Step { sent, streak, up, closed }

/// After a solved case, in order: Y4 Sent to your grown-up (648:83),
/// Streak (650:202), Up (651:35), then X1 Case closed (650:166), which
/// shows the next case. [ProgressRepository.afterCase] decides which of
/// the first three show.
class AfterCaseScreen extends StatefulWidget {
  const AfterCaseScreen({super.key, required this.after});

  final AfterCase after;

  @override
  State<AfterCaseScreen> createState() => _AfterCaseScreenState();
}

class _AfterCaseScreenState extends State<AfterCaseScreen> {
  late final List<_Step> _steps = [
    if (widget.after.sentBadge != null) _Step.sent,
    if (widget.after.streak) _Step.streak,
    if (widget.after.opened != null) _Step.up,
    _Step.closed,
  ];
  int _at = 0;

  void _next() => setState(() => _at++);

  void _home() => context.go(Paths.home);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final a = widget.after;
    return switch (_steps[_at]) {
      _Step.sent => AuraPage(
        play: true,
        top: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Ribbon(text: l.kidMySash),
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            _Sash(badgeId: a.sentBadge!),
            PlayLine(l.kidInYourSash),
          ],
        ),
        bottom: ButtonStack([
          AuraButton(label: l.kidNextCase, onPressed: _next),
          AuraButton(
            label: l.kidHome,
            color: AuraButtonColor.white,
            onPressed: _home,
          ),
        ]),
      ),
      _Step.streak => PlayMoment(
        gap: 20,
        content: [
          const Art('✨', size: 120),
          const SizedBox(height: 10),
          Ribbon(text: l.kidOnARoll),
          PlayLine(l.kidCaseAfterCase),
        ],
        bottom: AuraButton(label: l.next, onPressed: _next),
      ),
      _Step.up => PlayMoment(
        content: [
          Ribbon(text: l.kidTryNewSkill),
          const BadgeDisc(art: '🧗', size: 190, look: BadgeLook.blue),
          PlayLine(l.kidNewStopOpened(a.opened!.label(l))),
        ],
        bottom: AuraButton(
          label: l.kidSeeMyTrail,
          onPressed: () {
            _next();
            context.push(Paths.trail);
          },
        ),
      ),
      _Step.closed => _CaseClosed(solved: a.solved, next: a.next),
    };
  }
}

/// X1: the next case, and whether to take it now. A harder level than the
/// one just solved says so ("a trickier one"); nothing names a level.
class _CaseClosed extends StatelessWidget {
  const _CaseClosed({required this.solved, required this.next});

  final ComparisonProblem? solved;
  final ComparisonProblem next;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final trickier =
        solved != null && (next.level ?? '').compareTo(solved!.level ?? '') > 0;
    final tree = _treeStories.contains(next.storyId);
    // the same story with its words turned round ("shorter" that adds)
    final watchWords =
        tree &&
        solved?.storyId == next.storyId &&
        TrailStop.of(next) == TrailStop.trickyWords;
    return AuraPage(
      play: true,
      top: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Ribbon(text: trickier ? l.kidTrickierOne : l.readyForNewCase),
      ),
      body: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 220),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: AuraColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AuraColors.navy, width: 3),
            boxShadow: const [
              BoxShadow(color: AuraColors.navy, offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Art('${next.a.pic}${next.b.pic}', size: 70),
              Text(
                tree ? l.kidTreeWordProblem : l.kidWordProblem,
                textAlign: TextAlign.center,
                style: AuraText.caseTitle,
              ),
              if (watchWords)
                Text(
                  l.kidSameTreesWatchWords,
                  textAlign: TextAlign.center,
                  style: AuraText.caseLine,
                ),
            ],
          ),
        ),
      ),
      bottom: ButtonStack([
        AuraButton(
          label: l.kidLetsGo,
          // a fresh `?s=` so a repeat of the same case builds a new lesson
          onPressed: () => context.go(
            Uri(
              path: Paths.lesson(next.id),
              queryParameters: {'s': const Uuid().v4()},
            ).toString(),
          ),
        ),
        AuraButton(
          label: l.kidDoneForToday,
          color: AuraButtonColor.white,
          onPressed: () => context.go(Paths.home),
        ),
      ]),
    );
  }

  // ponytail: packs don't name their stories yet; every story this term is
  // two trees, so the title comes from this set until they do.
  static const _treeStories = {'lemon-fig', 'mango-guava'};
}

/// Y4's sash: the badge just earned, on the gold board.
class _Sash extends StatelessWidget {
  const _Sash({required this.badgeId});

  final String badgeId;

  @override
  Widget build(BuildContext context) => Container(
    width: 282,
    height: 282,
    padding: const EdgeInsets.only(top: 20),
    alignment: Alignment.topCenter,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: AuraColors.navy, width: 4),
      boxShadow: const [
        BoxShadow(color: AuraColors.navy, offset: Offset(0, 8)),
      ],
      gradient: const LinearGradient(
        begin: Alignment(-0.35, -1),
        end: Alignment(0.35, 1),
        stops: [0.11, 0.89],
        colors: [AuraColors.sashLight, AuraColors.yellow],
      ),
    ),
    child: BadgeDisc(art: badgeArt(badgeId), size: 86),
  );
}
