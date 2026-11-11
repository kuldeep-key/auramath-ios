import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/confetti.dart';
import '../../../core/motion/motion.dart';
import '../../../core/motion/play_backdrop.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';
import '../../child_home/views/badge_disc.dart' show badgeArt;
import '../view_models/lesson_view_model.dart';
import 'self_rating.dart';

/// Case cracked, then the one badge that says what the child did.
/// Figma: Y2, Y3.
class SolvedView extends StatefulWidget {
  const SolvedView({super.key, required this.vm, required this.onFinished});

  final LessonViewModel vm;
  final ValueChanged<String> onFinished;

  @override
  State<SolvedView> createState() => _SolvedViewState();
}

class _SolvedViewState extends State<SolvedView> {
  bool _showBadge = false;

  void _reveal() {
    AuraHaptics.win();
    setState(() => _showBadge = true);
  }

  // ponytail: badge art by id until packs carry badge pictures.
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final badge = widget.vm.badge;
    return PlayBackdrop(
      child: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Spacer(),
                  if (!_showBadge) ...[
                    Ribbon(text: l.caseCracked),
                    const SizedBox(height: 24),
                    const Burst(child: Portrait(size: 200)),
                    const SizedBox(height: 24),
                    Text(
                      widget.vm.praise ?? l.youSolvedIt,
                      style: AuraText.cheer,
                      textAlign: TextAlign.center,
                    ),
                    if (widget.vm.offerRating) ...[
                      const SizedBox(height: 20),
                      ListenableBuilder(
                        listenable: widget.vm,
                        builder: (_, _) => SelfRating(vm: widget.vm),
                      ),
                    ],
                  ] else ...[
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
                            BoxShadow(
                              color: AuraColors.blueLip,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          badgeArt(widget.vm.badgeId ?? ''),
                          style: const TextStyle(fontSize: 88),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      badge?.name ?? '',
                      style: AuraText.playTitle.copyWith(
                        color: AuraColors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge?.says ?? '',
                      style: AuraText.play,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const Spacer(),
                  Builder(
                    builder: (context) {
                      // no badge moment while the flag is off
                      final finishing = _showBadge || !widget.vm.showBadges;
                      final next = widget.vm.nextProblemId;
                      return AuraButton(
                        label: _showBadge ? l.addToSash : l.next,
                        // the server's next case may still be on its way
                        onPressed: !finishing
                            ? _reveal
                            : next == null
                            ? null
                            : () {
                                // no face tapped: the session ends unrated
                                widget.vm.skipRating();
                                widget.onFinished(next);
                              },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // the prototype's confetti: 140 after 200 ms on "case closed", 90
          // after 500 ms on the badge
          Positioned.fill(
            key: ValueKey(_showBadge),
            child: Confetti(
              count: _showBadge ? 90 : 140,
              delay: Duration(milliseconds: _showBadge ? 500 : 200),
            ),
          ),
        ],
      ),
    );
  }
}
