import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../data/services/sound_effects.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/confetti.dart';
import '../../../core/motion/fx_burst.dart';
import '../../../core/motion/motion.dart';
import '../../../core/motion/play_backdrop.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/journey_art.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/parts/speak_button.dart';
import '../../../core/theme/tokens.dart';
import '../../child_home/views/badge_disc.dart' show badgeArt;
import '../view_models/lesson_view_model.dart';
import 'self_rating.dart';

/// After the case, in the prototype's order: Y2 "case cracked" with the
/// tutor cheering and the solved celebration (one of confetti, a star
/// burst or streamers, 1.5 s from 200 ms, never the same twice running);
/// then, from age 7 with the flag on, Rate: three faces, no wrong answer
/// (AI-08); then the case's badge while `mastery_badges` is on. Figma: Y2,
/// Y3.
class SolvedView extends StatefulWidget {
  const SolvedView({super.key, required this.vm, required this.onFinished});

  final LessonViewModel vm;
  final ValueChanged<String> onFinished;

  @override
  State<SolvedView> createState() => _SolvedViewState();
}

enum _Phase { solved, rate, badge }

class _SolvedViewState extends State<SolvedView> {
  _Phase _phase = _Phase.solved;
  Timer? _afterRate;

  LessonViewModel get vm => widget.vm;

  @override
  void initState() {
    super.initState();
    // the prototype's solved(): SFX.win as the case closes
    AuraSound.celebrate();
  }

  @override
  void dispose() {
    _afterRate?.cancel();
    super.dispose();
  }

  /// Next on Y2 (y2next): the faces first if they're offered.
  void _next() {
    if (vm.offerRating && vm.rating == null) {
      setState(() => _phase = _Phase.rate);
    } else {
      _afterRating();
    }
  }

  /// afterRate: the badge while the flag is on, else the next case.
  void _afterRating() {
    if (vm.showBadges && _phase != _Phase.badge) {
      AuraHaptics.win();
      AuraSound.badge();
      setState(() => _phase = _Phase.badge);
    } else {
      _finish();
    }
  }

  void _finish() {
    final next = vm.nextProblemId;
    if (next == null) return;
    // no face tapped: the session ends unrated
    vm.skipRating();
    widget.onFinished(next);
  }

  /// A face: it presses in, then the next moment 350 ms later.
  void _rated(String face) {
    vm.rate(face);
    _afterRate = Timer(const Duration(milliseconds: 350), _afterRating);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final badge = vm.badge;
    final praise = vm.praise ?? l.youSolvedIt;
    return PlayBackdrop(
      child: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: SpeakButton(
                      text: switch (_phase) {
                        _Phase.solved => '${l.caseCracked} $praise',
                        _Phase.rate => l.lessonRateAsk,
                        _Phase.badge =>
                          '${badge?.name ?? ''}. ${badge?.says ?? ''}',
                      },
                    ),
                  ),
                  // centred; on a short phone with large text it scrolls
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: box.maxHeight),
                          child: switch (_phase) {
                            _Phase.solved => _solved(
                              l,
                              praise,
                              (box.maxHeight * .4).clamp(96, 200),
                            ),
                            _Phase.rate => _rate(l),
                            _Phase.badge => _badge(l),
                          },
                        ),
                      ),
                    ),
                  ),
                  if (_phase == _Phase.rate)
                    TextButton(
                      key: const Key('rateSkip'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(56, 56),
                      ),
                      onPressed: _afterRating,
                      child: Text(
                        l.lessonRateSkip,
                        style: AuraText.link.copyWith(
                          color: AuraColors.linkOnBlue,
                        ),
                      ),
                    )
                  else
                    AuraButton(
                      label: _phase == _Phase.badge ? l.addToSash : l.next,
                      // the server's next case may still be on its way
                      onPressed: _phase == _Phase.solved
                          ? (vm.offerRating || vm.showBadges
                                ? _next
                                : vm.nextProblemId == null
                                ? null
                                : _next)
                          : vm.nextProblemId == null
                          ? null
                          : _finish,
                    ),
                ],
              ),
            ),
          ),
          // celebrate('solved') 200 ms in; Y3's confetti 90 at 500 ms
          if (_phase == _Phase.solved)
            Positioned.fill(
              child: FxBurst.moment(
                FxMoment.solved,
                delay: const Duration(milliseconds: 200),
              ),
            ),
          if (_phase == _Phase.badge)
            const Positioned.fill(
              key: ValueKey('badgeConfetti'),
              child: Confetti(count: 90, delay: Duration(milliseconds: 500)),
            ),
        ],
      ),
    );
  }

  Widget _solved(AppLocalizations l, String praise, double tutor) => Column(
    key: const Key('y2'),
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Ribbon(text: l.caseCracked),
      const SizedBox(height: 18),
      TutorFigure(
        tutorId: vm.tutorId,
        kind: vm.tutorKind,
        size: tutor,
        state: TutorState.cheering,
      ),
      const SizedBox(height: 18),
      Text(
        praise,
        style: AuraText.cheer.copyWith(fontSize: 26),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 18),
      Opacity(
        opacity: .85,
        child: Text(
          l.lessonFamilySees,
          style: AuraText.play.copyWith(fontSize: 17),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );

  Widget _rate(AppLocalizations l) => Column(
    key: const Key('rate'),
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Ribbon(text: l.lessonRateAsk),
      const SizedBox(height: 22),
      ListenableBuilder(
        listenable: vm,
        builder: (_, _) => SelfRating(vm: vm, onRate: _rated),
      ),
      const SizedBox(height: 22),
      Opacity(
        opacity: .9,
        child: Text(
          l.lessonRateAnyAnswer,
          style: AuraText.play.copyWith(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );

  Widget _badge(AppLocalizations l) {
    final badge = vm.badge;
    return Column(
      key: const Key('badge'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Ribbon(text: l.newBadge),
        const SizedBox(height: 24),
        Burst(
          child: Container(
            width: 190,
            height: 190,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AuraColors.blueTint,
              boxShadow: [
                BoxShadow(color: AuraColors.blueLip, offset: Offset(0, 8)),
              ],
            ),
            child: Text(
              badgeArt(vm.badgeId ?? ''),
              style: const TextStyle(fontSize: 88),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          badge?.name ?? '',
          style: AuraText.playTitle.copyWith(color: AuraColors.white),
        ),
        const SizedBox(height: 8),
        Text(
          badge?.says ?? '',
          style: AuraText.play,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
