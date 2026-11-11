import 'package:flutter/material.dart';

import '../../../../data/repositories/rewards_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/tokens.dart';
import 'badge_disc.dart';

/// What Home celebrates when the child comes back to it: the badge of the
/// session that just stopped (REW-01). It shows once.
typedef HomeMoments = ({SessionBadge? badge});

/// The one badge a session earns, however it stopped (REW-01): the
/// server's when it names one, else a DRAFT name for the way it ended.
typedef SessionBadge = ({String sessionId, String reason, ServedBadge? served});

/// Decides [HomeMoments] for one visit to Home, and remembers what it has
/// shown so each session's badge shows once.
class HomeMomentsSource {
  HomeMomentsSource({required this.rewards});

  final RewardsRepository rewards;
  final Set<String> _shownSessions = {};

  Future<HomeMoments> next({
    required ({String sessionId, String reason})? lastStop,
  }) async {
    SessionBadge? badge;
    if (lastStop != null && _shownSessions.add(lastStop.sessionId)) {
      badge = (
        sessionId: lastStop.sessionId,
        reason: lastStop.reason,
        served: await rewards.sessionBadge(lastStop.sessionId),
      );
    }
    return (badge: badge);
  }
}

/// Home's card for [HomeMoments]; nothing when there is none.
class HomeMomentCard extends StatelessWidget {
  const HomeMomentCard({super.key, required this.moments});

  final HomeMoments moments;

  /// DRAFT for Design and Julia (REW-01, D-47): a plain-words name for what
  /// the child did, by how the session stopped, until the server names
  /// the badge.
  static String draftName(AppLocalizations l, String reason) =>
      switch (reason) {
        'finished' => l.kidSessionBadgeFinished,
        'time_up' => l.kidSessionBadgeTimeUp,
        'left' => l.kidSessionBadgeLeft,
        _ => l.kidSessionBadgePaused,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final b = moments.badge;
    if (b == null) return const SizedBox.shrink();
    final name = b.served?.name ?? draftName(l, b.reason);
    return Pop(
      duration: const Duration(milliseconds: 450),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AuraColors.white,
            borderRadius: BorderRadius.circular(AuraRadii.panel),
            border: Border.all(color: AuraColors.navy, width: 3),
          ),
          child: Column(
            spacing: 8,
            children: [
              Row(
                spacing: 12,
                children: [
                  BadgeDisc(art: badgeArt(b.served?.id ?? 'session'), size: 56),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.kidSessionBadgeEarned, style: AuraText.caption),
                        Text(name, style: AuraText.option),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
