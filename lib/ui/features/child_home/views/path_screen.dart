import 'package:flutter/material.dart';

import '../../../../data/repositories/rewards_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/play_backdrop.dart';
import '../../../core/parts/journey_art.dart';
import '../../../core/parts/speak_button.dart';
import '../../../core/theme/tokens.dart';
import 'play_icon_button.dart';

/// The trail drawn as a path (JRN-03, REW-04), from the server's
/// `trail.lands`: the land the child is in, every stop with its state,
/// the child's look standing at their current stop, the next stop clear,
/// later stops in mist with no names, and one teaser of the next land in
/// mist. No other land, and never a number about the child (REW-03). It
/// scrolls, so nothing clips on a small phone or at 1.3x text (NFR-04).
/// DRAFT for Apoorv: placeholder stop markers until the path art
/// (`art.path.<world>.*`) is in the build.
class PathScreen extends StatelessWidget {
  const PathScreen({
    super.key,
    required this.lands,
    required this.lookId,
    this.world = 'detective',
  });

  final List<PathLand> lands;
  final String lookId;
  final String world;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final current =
        lands.where((x) => x.current).firstOrNull ??
        lands.where((x) => !x.teaser).firstOrNull;
    final teaser = lands.where((x) => x.teaser).firstOrNull;
    // the path runs from the bottom up, as the child climbs
    final stops = [...?current?.stops].reversed.toList();
    return Scaffold(
      backgroundColor: AuraColors.blueLip,
      body: PlayBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: [
                    Expanded(child: PlayHeader(title: l.kidMyTrail)),
                    SpeakButton(
                      text: [
                        l.kidMyTrail,
                        ?current?.name,
                        for (final s in current?.stops ?? const <PathStop>[])
                          if (s.state == 'current')
                            '${l.kidYouAreHere}: ${s.name}',
                      ].join('. '),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView(
                      key: const Key('path'),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        if (teaser != null) _Teaser(label: l.kidTrailMist),
                        if (current != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Semantics(
                              header: true,
                              child: Text(
                                current.name,
                                textAlign: TextAlign.center,
                                style: AuraText.playTitle.copyWith(
                                  color: AuraColors.white,
                                ),
                              ),
                            ),
                          ),
                        for (final (i, s) in stops.indexed)
                          _Stop(
                            stop: s,
                            // a winding path: stops step left and right
                            left: i.isEven,
                            lookId: lookId,
                            world: world,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({
    required this.stop,
    required this.left,
    required this.lookId,
    required this.world,
  });

  final PathStop stop;
  final bool left;
  final String lookId;
  final String world;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mist = stop.state == 'mist';
    final here = stop.state == 'current';
    final tag = switch (stop.state) {
      'earned' => l.kidTrailEarned,
      'explored' => l.kidTrailExplored,
      'current' => l.kidYouAreHere,
      'next' => l.kidTrailNext,
      _ => null,
    };
    final marker = ArtOr(
      artKey: 'art.path.$world.stops.${stop.state}',
      size: 64,
      placeholder: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: switch (stop.state) {
            'earned' => AuraColors.badgeGold,
            'explored' => AuraColors.badgeBlueLight,
            'current' => AuraColors.yellow,
            'next' => AuraColors.white,
            _ => AuraColors.white.withValues(alpha: 0.25),
          },
          border: Border.all(
            color: mist
                ? AuraColors.white.withValues(alpha: 0.4)
                : AuraColors.navy,
            width: 3,
          ),
        ),
        child: Icon(
          switch (stop.state) {
            'earned' => Icons.military_tech_rounded,
            'explored' => Icons.explore_rounded,
            'next' => Icons.flag_rounded,
            'mist' => Icons.cloud_rounded,
            _ => Icons.place_rounded,
          },
          size: 34,
          color: mist ? AuraColors.white : AuraColors.navy,
        ),
      ),
    );
    final words = Column(
      crossAxisAlignment: left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // nothing is named in the mist
        if (!mist)
          Text(
            stop.name,
            textAlign: left ? TextAlign.left : TextAlign.right,
            style: AuraText.badgeName,
          ),
        if (tag != null)
          Text(
            tag.toUpperCase(),
            style: AuraText.eyebrow.copyWith(color: AuraColors.linkOnBlue),
          ),
        if (stop.polishMe && !mist)
          Text(
            l.kidPolishMe,
            style: AuraText.trailNote.copyWith(color: AuraColors.white),
          ),
      ],
    );
    final row = [
      Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          marker,
          // the child's look stands at their stop (JRN-03, AVT-02)
          if (here)
            Positioned(
              top: -40,
              child: LookPortrait(lookId: lookId, world: world, size: 48),
            ),
        ],
      ),
      const SizedBox(width: 14),
      Flexible(child: words),
    ];
    return Semantics(
      label: mist ? l.kidTrailMist : [stop.name, ?tag].join(', '),
      excludeSemantics: true,
      child: Opacity(
        opacity: mist ? 0.6 : 1,
        child: Padding(
          padding: EdgeInsets.only(
            top: here ? 52 : 14,
            bottom: 14,
            left: left ? 8 : 48,
            right: left ? 48 : 8,
          ),
          child: Row(
            mainAxisAlignment: left
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            children: left ? row : row.reversed.toList(),
          ),
        ),
      ),
    );
  }
}

/// The next land: one glimpse, in mist, unnamed (journey.yaml `next_land:
/// teaser`).
class _Teaser extends StatelessWidget {
  const _Teaser({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    excludeSemantics: true,
    child: Container(
      height: 96,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AuraColors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AuraRadii.panel),
        border: Border.all(color: AuraColors.white.withValues(alpha: 0.4)),
      ),
      child: const Icon(Icons.cloud_rounded, size: 56, color: AuraColors.white),
    ),
  );
}
