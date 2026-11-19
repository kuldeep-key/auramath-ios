import 'package:flutter/material.dart';

import '../../../../data/repositories/rewards_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/tokens.dart';
import 'badge_disc.dart';

/// What Home celebrates when the child comes back to it: the badge of the
/// session that just stopped (REW-01), and the kind streak moment
/// (REW-05). Each shows once.
typedef HomeMoments = ({SessionBadge? badge, bool streak});

/// The one badge a session earns, however it stopped (REW-01), as the
/// server names it. None is made up on the phone: one the server hasn't
/// named yet shows later (`pendingSessionBadge`, H6).
typedef SessionBadge = ({String sessionId, String reason, ServedBadge? served});

/// Decides [HomeMoments] for one visit to Home, and remembers what it has
/// shown so each session's badge, and each day's streak, shows once.
class HomeMomentsSource {
  HomeMomentsSource({required this.rewards});

  final RewardsRepository rewards;
  final Set<String> _shownSessions = {};
  DateTime? _streakShownOn;

  /// [sessionId]'s badge has shown elsewhere (waiting from last time,
  /// REW-01): not again here.
  void markShown(String sessionId) => _shownSessions.add(sessionId);

  /// [replied]: the badge the server named in its answer to the batch
  /// that ended the session (REW-01), when it did: shown as it is, with no
  /// rewards read. Not there yet, [settle] lets a late answer arrive (a
  /// short wait), then the rewards read is asked. Named by neither, no
  /// badge shows now, and none is made up (H6): the server keeps it as
  /// `pendingSessionBadge` for the next open, or a later Home asks again.
  /// [onStreak]: today's streak moment is about to show (DAT-03 logs it as
  /// `streak_moment_shown`).
  Future<HomeMoments> next({
    required ({String sessionId, String reason})? lastStop,
    String? childId,
    bool streakOn = false,
    DateTime? now,
    ServedBadge? Function(String sessionId)? replied,
    Future<void> Function()? settle,
    void Function(StreakMoment moment)? onStreak,
  }) async {
    // one rewards read for this visit, whatever needs it (FL-49)
    Future<Rewards>? read;
    Future<Rewards> served(String id) => read ??= rewards.read(id);
    SessionBadge? badge;
    if (lastStop != null && _shownSessions.add(lastStop.sessionId)) {
      final id = lastStop.sessionId;
      var named = replied?.call(id);
      if (named == null && settle != null) {
        await settle();
        named = replied?.call(id);
      }
      named ??= childId == null
          ? null
          : (await served(childId)).sessionBadge(id);
      if (named == null) {
        _shownSessions.remove(id);
      } else {
        badge = (sessionId: id, reason: lastStop.reason, served: named);
      }
    }
    // REW-05 (flag streak_moment): the server counts the days, in the
    // family's time zone, with its free missed days; the phone only asks
    // whether today's moment shows, and shows it once a day
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    var streak = false;
    if (streakOn && childId != null && _streakShownOn != today) {
      final moment = (await served(childId)).streak;
      streak = moment != null;
      if (moment != null) {
        _streakShownOn = today;
        onStreak?.call(moment);
      }
    }
    return (badge: badge, streak: streak);
  }
}

/// Home's card for [HomeMoments]; nothing when there is none.
class HomeMomentCard extends StatelessWidget {
  const HomeMomentCard({super.key, required this.moments});

  final HomeMoments moments;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // only a badge the server named (H6)
    final b = moments.badge?.served == null ? null : moments.badge;
    if (b == null && !moments.streak) return const SizedBox.shrink();
    final name = b?.served?.name;
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
              if (b != null && name != null)
                Row(
                  spacing: 12,
                  children: [
                    BadgeDisc(
                      art: badgeArt(b.served?.id ?? 'session'),
                      size: 56,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.kidSessionBadgeEarned,
                            style: AuraText.caption,
                          ),
                          Text(name, style: AuraText.option),
                        ],
                      ),
                    ),
                  ],
                ),
              // REW-05: no number, never a loss
              if (moments.streak)
                Text(
                  l.kidStreakMoment,
                  textAlign: TextAlign.center,
                  style: AuraText.option,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
