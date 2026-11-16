import 'contract.dart';

/// What a session runs with (JRN-07, `session_started.look`): ids from
/// avatar/looks.yaml, tutor/tutors.yaml (tutor and voice) and the world
/// from rewards/rules.yaml `worlds`.
typedef SessionLook = ({
  String avatarId,
  String tutorId,
  String voiceId,
  String world,
});

/// The worlds the event contract knows (rewards/rules.yaml `worlds.ids`).
const worldIds = {'detective', 'space', 'wildlife'};

/// The world every child is in until another is enabled (REW-17).
const defaultWorld = 'detective';

/// `session_started` (SES-05): why the lesson opened, the content it
/// teaches from, and what it runs with. `is_test` is always sent (D-55),
/// and `look` from v0.5.4 (JRN-07). A world the contract doesn't know is
/// sent as Detective, the world the child sees then.
SpecEvent sessionStarted({
  required String launchSource,
  required Map<String, String> contentVersions,
  required bool isDemo,
  required SessionLook look,
  bool isTest = false,
}) => SpecEvent('session_started', {
  'launch_source': launchSource,
  'content_versions': contentVersions,
  'is_demo': isDemo,
  'is_test': isTest,
  'look': {
    'avatar_id': look.avatarId,
    'tutor_id': look.tutorId,
    'voice_id': look.voiceId,
    'world': worldIds.contains(look.world) ? look.world : defaultWorld,
  },
});

/// How a line started (TTR-03): the tutor spoke it as it appeared, or the
/// child asked to hear it.
enum ReadTrigger { auto, tap }

final _lineId = RegExp(r'^line\.[a-z0-9.-]{1,60}$');

/// `read_aloud_played` (NFR-06, NFR-08, TTR-03): what was read, how it
/// started, and whether a child action cut it short. Never the words, so no
/// name or child text is in the log. [lineId] only for a tutor line from
/// the policy's library (`line.*`); an app line has none.
SpecEvent readAloudPlayed({
  required String target,
  required ReadTrigger trigger,
  required bool stoppedEarly,
  String? lineId,
}) => SpecEvent('read_aloud_played', {
  'target': target,
  'trigger': trigger.name,
  'stopped_early': stoppedEarly,
  if (lineId != null && _lineId.hasMatch(lineId)) 'line_id': lineId,
});

/// `badge_shown` (REW-11): the child saw the badge. This, not the
/// server's `badge_awarded`, counts it as given (REW-19). [queued] when it
/// waited from an earlier session; [problemId] the case it was shown
/// after (D-54), none for a session badge.
SpecEvent badgeShown(
  String badgeId, {
  bool queued = false,
  String? problemId,
}) => SpecEvent('badge_shown', {
  'badge_id': badgeId,
  'queued': queued,
  'problem_id': ?problemId,
});

/// Where a badge was tapped open (REW-12, REW-20).
enum BadgeOpenedFrom { cabinet, casebook, celebration }

/// `badge_opened` (REW-12): the child tapped a badge; [openedCase] when the
/// tap opened the case it came from (the casebook, once it exists).
SpecEvent badgeOpened(
  String badgeId, {
  required BadgeOpenedFrom from,
  bool? openedCase,
}) => SpecEvent('badge_opened', {
  'badge_id': badgeId,
  'from': from.name,
  'opened_case': ?openedCase,
});

/// `cabinet_opened` (REW-12): how many badges it showed. Logged, never
/// shown (no counts, rules.yaml `cabinet.counts_shown`).
SpecEvent cabinetOpened(int badgesShown) =>
    SpecEvent('cabinet_opened', {'badges_shown': badgesShown});

/// The celebration moments the event contract knows (rewards/rules.yaml
/// `celebrations.moments`).
const celebrationMoments = {
  'step_right', 'wrong_move', 'case_solved', 'session_badge', //
  'detour_return', 'warm_up_done', 'streak_moment', 'stop_badge',
  'habit_badge', 'first_badge', 'kept_mark', 'kept_for_good',
  'polish_cleared', 'land_badge', 'secret_badge', 'collectible_unlocked',
  'mystery_clue_found', 'partner_taught', 'case_made',
};

/// `celebration_shown` (REW-16, REW-20): which version of which moment
/// played, in which world, for how long, and whether it was skipped or a
/// still (reduced motion).
SpecEvent celebrationShown({
  required String moment,
  required int variant,
  required String world,
  required int ms,
  required bool skipped,
  required bool reducedMotion,
}) {
  assert(celebrationMoments.contains(moment), 'no moment $moment');
  return SpecEvent('celebration_shown', {
    'moment': moment,
    'variant': variant.clamp(1, 20),
    'world': worldIds.contains(world) ? world : defaultWorld,
    'ms': ms < 0 ? 0 : ms,
    'skipped': skipped,
    'reduced_motion': reducedMotion,
  });
}

/// `trail_opened` (JRN-03): the child opened the trail; no payload.
const trailOpened = SpecEvent('trail_opened', {});

/// The next version of a celebration (rules.yaml `celebrations.global
/// .variant_pick: rotate_never_repeat_last`), 1 to [count]: the one after
/// [last], round again after the last. Never [last] while there are two or
/// more.
int nextVariant(int? last, int count) {
  if (count <= 1) return 1;
  if (last == null || last < 1 || last >= count) return 1;
  return last + 1;
}
