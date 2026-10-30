import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/progress_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';
import 'play_icon_button.dart';
import 'play_moment.dart';

/// The winding path: the two stops behind (done), where the child is, and
/// only the next stop through the mist, so the child never sees how much
/// is left. Figma: K2 My trail (651:68).
///
/// The scene is full-bleed (the hills reach the screen edges), so this
/// screen lays out its own frame instead of `AuraPage`; header and footer
/// keep its 16 pt margins and 560 pt column.
class TrailScreen extends StatelessWidget {
  const TrailScreen({super.key, required this.here});

  final TrailStop here;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final stops = TrailStop.values;
    final i = here.index;
    return Scaffold(
      backgroundColor: AuraColors.blueLip,
      body: DecoratedBox(
        decoration: auraPlayBackground,
        child: SafeArea(
          child: Column(
            children: [
              _Column(PlayHeader(title: l.kidMyTrail)),
              Expanded(
                child: ClipRect(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 337,
                        height: 640,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _scene('assets/images/trail_ground.png'),
                            for (final (emoji, x, y, size) in _decor)
                              Positioned(
                                left: x,
                                top: y,
                                child: Art(emoji, size: size),
                              ),
                            _scene('assets/images/trail_over.png'),
                            for (final (slot, at) in [
                              (0, i - 2),
                              (1, i - 1),
                              (2, i),
                              (3, i + 1),
                            ])
                              if (at >= 0 && at < stops.length)
                                ..._stop(l, slot, stops[at]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _Column(
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 22),
                  child: AuraButton(
                    label: l.keepGoing,
                    onPressed: () => context.go(Paths.lessonNext),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Slots 0 and 1 are done, 2 is here, 3 is next.
  List<Widget> _stop(AppLocalizations l, int slot, TrailStop stop) {
    final (x, y) = _slots[slot];
    final right = x < 150;
    final kind = switch (slot) {
      2 => _Kind.here,
      3 => _Kind.next,
      _ => _Kind.done,
    };
    final label = _Label(
      kind: kind,
      title: stop.label(l),
      note: switch (kind) {
        _Kind.done => l.kidDone,
        _Kind.here => l.kidYouAreHere,
        _Kind.next => l.kidNextStop,
      },
    );
    return [
      Positioned(
        left: x,
        top: y,
        child: kind == _Kind.here
            ? const Portrait(size: 60)
            : _Stop(art: stop.art, done: kind == _Kind.done),
      ),
      Positioned(
        top: y + 8,
        left: right ? x + 68 : null,
        right: right ? null : 337 - x + 8,
        child: label,
      ),
    ];
  }

  static Widget _scene(String asset) => Positioned(
    left: -90,
    top: -46,
    width: 550,
    height: 703,
    child: Image.asset(asset, excludeFromSemantics: true),
  );

  /// Stop positions in Figma's 337 × 640 map, bottom to top.
  static const _slots = [
    (54.0, 510.0),
    (220.0, 390.0),
    (62.0, 260.0),
    (214.0, 132.0),
  ];

  /// The scene's emoji: trees, flowers, a mushroom and a far mountain.
  static const _decor = [
    ('🌲', 17.0, 574.0, 26.0),
    ('🌲', 285.0, 530.0, 30.0),
    ('🌲', 9.0, 418.0, 22.0),
    ('🌲', 296.0, 272.0, 28.0),
    ('🌲', 170.0, 330.0, 20.0),
    ('🌲', 18.0, 176.0, 24.0),
    ('🌲', 141.0, 482.0, 18.0),
    ('🌲', 291.0, 452.0, 18.0),
    ('🌲', 151.0, 212.0, 18.0),
    ('🌼', 270.0, 542.0, 18.0),
    ('🌷', 40.0, 368.0, 12.0),
    ('🍄', 200.0, 588.0, 12.0),
    ('⛰️', 300.0, 98.0, 22.0),
  ];
}

/// What the child reads for each stop.
extension TrailStopLabel on TrailStop {
  String label(AppLocalizations l) => switch (this) {
    TrailStop.addBig => l.kidStopAddBig,
    TrailStop.takeAwayBig => l.kidStopTakeAwayBig,
    TrailStop.trees => l.kidStopTrees,
    TrailStop.trickyWords => l.kidStopTrickyWords,
    TrailStop.totalAndDifference => l.kidStopTotalAndDifference,
  };
}

enum _Kind { done, here, next }

class _Column extends StatelessWidget {
  const _Column(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}

class _Stop extends StatelessWidget {
  const _Stop({required this.art, required this.done});

  final String art;
  final bool done;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: done ? 1 : 0.6,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AuraColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AuraColors.navy, width: 4),
            boxShadow: done
                ? const [
                    BoxShadow(color: AuraColors.navy, offset: Offset(0, 5)),
                  ]
                : null,
          ),
          child: Art(art, size: 28),
        ),
        if (done)
          Positioned(
            left: 34,
            top: -6,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AuraColors.green,
                shape: BoxShape.circle,
                border: Border.all(color: AuraColors.white, width: 2),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 16,
                color: AuraColors.white,
              ),
            ),
          ),
      ],
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label({required this.kind, required this.title, required this.note});

  final _Kind kind;
  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    final here = kind == _Kind.here;
    final next = kind == _Kind.next;
    // the next stop looks quieter (soft fill, no lip), not see-through: a
    // faded label over the map can't be read (WCAG contrast)
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: here
            ? AuraColors.yellowTint
            : next
            ? AuraColors.soft
            : AuraColors.white,
        borderRadius: BorderRadius.circular(AuraRadii.small),
        border: Border.all(color: AuraColors.navy, width: 3),
        boxShadow: next
            ? null
            : const [BoxShadow(color: AuraColors.navy, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 3,
        children: [
          Text(title, style: AuraText.trailStop),
          Text(
            note,
            style: AuraText.trailNote.copyWith(
              color: here ? AuraColors.yellowInk : AuraColors.mute,
            ),
          ),
        ],
      ),
    );
  }
}
