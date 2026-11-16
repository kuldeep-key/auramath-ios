import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons, Curves;

import '../motion/motion.dart';
import '../theme/tokens.dart';
import 'tutor_art.dart';

/// The art Apoorv delivers (D-59), by the spec's art keys
/// (`art.look.look_03.detective`, `art.tutor.robot.detective`,
/// `art.path.detective.mist`, ...): a file at `assets/art/<key>.png` is used
/// as soon as it is in the build, with no code change. Until then each
/// place draws its placeholder.
abstract final class ArtAssets {
  static Set<String> _have = const {};

  /// Reads which art files this build holds (once, at start).
  static Future<void> load([AssetBundle? bundle]) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(
        bundle ?? rootBundle,
      );
      _have = manifest.listAssets().toSet();
    } on Object {
      _have = const {};
    }
  }

  /// The file for [key], if the build has it.
  static String? pathOf(String? key) {
    if (key == null) return null;
    final path = 'assets/art/$key.png';
    return _have.contains(path) ? path : null;
  }
}

/// [artKey]'s picture when the build has it, else [placeholder]. Hidden
/// from screen readers: the words beside it carry the meaning.
class ArtOr extends StatelessWidget {
  const ArtOr({
    super.key,
    required this.artKey,
    required this.size,
    required this.placeholder,
  });

  final String? artKey;
  final double size;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final path = ArtAssets.pathOf(artKey);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: path == null
            ? placeholder
            : Image.asset(
                path,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

/// The placeholder for look [index] (0 to 7): a disc in one of the theme's
/// colours with a detective's tool on it. No face, hair or clothes, so
/// nothing implies a gender (looks.yaml rules); never red (NFR-03).
const lookPlaceholders = <({Color color, IconData icon})>[
  (color: AuraColors.blue, icon: Icons.search_rounded),
  (color: AuraColors.yellowLip, icon: Icons.fingerprint_rounded),
  (color: AuraColors.green, icon: Icons.key_rounded),
  (color: AuraColors.navy, icon: Icons.explore_rounded),
  (color: AuraColors.badgeGold, icon: Icons.lightbulb_rounded),
  (color: AuraColors.blueInk, icon: Icons.edit_note_rounded),
  (color: AuraColors.badgeBlueEdge, icon: Icons.star_rounded),
  (color: AuraColors.yellowInk, icon: Icons.extension_rounded),
];

/// The child's look ([lookId], `look_01` to `look_08`) in [world]'s
/// costume (looks.yaml `costume.<world>`): Apoorv's art once delivered,
/// else its placeholder disc.
class LookPortrait extends StatelessWidget {
  const LookPortrait({
    super.key,
    required this.lookId,
    required this.size,
    this.world = 'detective',
  });

  final String lookId;
  final String world;
  final double size;

  static int indexOf(String lookId) {
    final n = int.tryParse(lookId.replaceFirst('look_', '')) ?? 1;
    return (n - 1).clamp(0, lookPlaceholders.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final p = lookPlaceholders[indexOf(lookId)];
    return ArtOr(
      artKey: 'art.look.$lookId.$world',
      size: size,
      placeholder: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: p.color,
          border: Border.all(color: AuraColors.navy, width: size < 60 ? 3 : 4),
        ),
        child: Icon(p.icon, size: size * 0.55, color: AuraColors.white),
      ),
    );
  }
}

/// The tutor's five animation states (tutors.yaml `animation`, TTR-04).
enum TutorState { idle, talking, thinking, cheering, encourage }

/// The tutor ([tutorId], its [kind] from tutors.yaml) in [world]'s costume
/// and its [state], drawn as the prototype draws it (16 Nov, [TutorPainter]):
/// `teacher_1` is its teacher a, `teacher_2` its teacher b, and the robot a
/// DRAFT in the same parts. Apoorv's art (`art.tutor.<id>.<world>[.<state>]`)
/// replaces the drawing once it is in the build.
///
/// [headOnly] draws the head alone, as the prototype's `tutorHead` for the
/// 56 to 64 pt lesson header and the Me screen (TTR-05); by default any
/// figure 64 pt or smaller. The whole figure pops in (`pop .5s`) when
/// [entrance] is on.
///
/// The prototype's moves, timed as its keyframes:
/// * the body bobs 4 units up and back every 2.8 s (`tuBob`) while idle,
///   talking or encouraging; cheering it jumps 8 units, 0.5 s each way
///   (`tuCheer`); thinking it stands still;
/// * the eyes blink every 5 s, shut at 97 % (`tuBlink`); cheering eyes
///   are happy arcs and don't blink;
/// * the talking mouth opens and closes, 0.3 s each way (`tuTalk`);
/// * thinking shows three dots fading 1.2 s, 0.2 s apart (`tuDot`);
/// * cheering shows three sparks, 1.1 s, the second 0.35 s late
///   (`tuSpark`).
///
/// With reduced motion each state is a still picture (tutors.yaml
/// `reduced_motion: still_pose_per_state`). Never red; nothing flashes
/// faster than about twice a second.
class TutorFigure extends StatefulWidget {
  const TutorFigure({
    super.key,
    required this.tutorId,
    required this.size,
    this.kind = 'grown_up_teacher',
    this.world = 'detective',
    this.state = TutorState.idle,
    this.headOnly,
    this.entrance = true,
  });

  final String tutorId;
  final String kind;
  final String world;

  /// The figure's width; its height follows the drawing (220/228 for the
  /// whole figure, 124/120 for the head).
  final double size;
  final TutorState state;

  /// The head alone. Null: for a figure 64 pt or smaller.
  final bool? headOnly;

  /// The whole figure pops in when first shown (the prototype's `.tutor`).
  final bool entrance;

  bool get head => headOnly ?? size <= 64;

  @override
  State<TutorFigure> createState() => _TutorFigureState();
}

class _TutorFigureState extends State<TutorFigure>
    with SingleTickerProviderStateMixin {
  late final _ticker = createTicker(_tick);
  final _pose = ValueNotifier(const TutorPose());
  Duration _since = Duration.zero;
  Duration _last = Duration.zero;

  TutorPart get _part => TutorPart.values[widget.state.index];

  void _tick(Duration elapsed) {
    _last = elapsed;
    final ms = (elapsed - _since).inMicroseconds / 1000;
    _pose.value = TutorPose.at(_part, ms);
  }

  /// Runs the moves, from the start of the state (as the prototype's
  /// animations restart with each new drawing); still with calm motion.
  void _run() {
    if (calmMotion(context)) {
      if (_ticker.isActive) _ticker.stop();
      _pose.value = const TutorPose();
      return;
    }
    _since = _last;
    _pose.value = TutorPose.at(_part, 0);
    if (!_ticker.isActive) _ticker.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _run();
  }

  @override
  void didUpdateWidget(TutorFigure old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) _run();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final head = widget.head;
    final box = head ? TutorPainter.headBox : TutorPainter.bodyBox;
    final width = widget.size;
    final height = width * box.height / box.width;
    final key =
        'art.tutor.${widget.tutorId}.${widget.world}'
        '${widget.state == TutorState.idle ? '' : '.${widget.state.name}'}';
    final path = ArtAssets.pathOf(key);
    Widget art = path != null
        ? Image.asset(path, fit: BoxFit.contain)
        : CustomPaint(
            painter: TutorPainter(
              look: TutorLook.of(widget.tutorId, widget.kind),
              state: _part,
              head: head,
              pose: _pose,
            ),
          );
    art = ExcludeSemantics(
      child: SizedBox(
        key: ValueKey('tutor.${widget.state.name}'),
        width: width,
        height: height,
        child: art,
      ),
    );
    if (!head && widget.entrance) {
      art = Pop(duration: AuraDurations.popBig, curve: Curves.ease, child: art);
    }
    return art;
  }
}

/// The child's tutor for the screens below it: the lesson header's tutor
/// button draws this one. Without a scope, `teacher_1` (tutors.yaml
/// `default`).
class TutorScope extends InheritedWidget {
  const TutorScope({
    super.key,
    required this.tutorId,
    this.kind = 'grown_up_teacher',
    this.world = 'detective',
    required super.child,
  });

  final String tutorId;
  final String kind;
  final String world;

  static const fallback = TutorScope(tutorId: 'teacher_1', child: SizedBox());

  static TutorScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TutorScope>() ?? fallback;

  @override
  bool updateShouldNotify(TutorScope old) =>
      old.tutorId != tutorId || old.kind != kind || old.world != world;
}
