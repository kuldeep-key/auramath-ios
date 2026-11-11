import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/ribbon.dart';
import 'play_icon_button.dart';
import 'play_moment.dart';

/// Choose today (LES-14): exactly two choices, the story problem or Quick
/// sums; either starts in one tap. The selector's suggestion comes first
/// (`todaySuggestion`; the story problem when the server sends none). The
/// choice is logged in the session it starts, as `choice_selected` with
/// its time here. After the starting check it shows inside the lesson,
/// which handles the choice ([onStory], [onQuick]).
/// Figma: A3 (journey 4.2); its "Taking away" is part of Quick sums.
/// Behind the flag `quick_sums`.
class ChooseTodayScreen extends StatefulWidget {
  const ChooseTodayScreen({
    super.key,
    this.suggestQuickSums = false,
    this.onStory,
    this.onQuick,
    this.onHome,
    int Function()? nowMs,
  }) : _now = nowMs;

  /// The selector suggests Quick sums today: it comes first.
  final bool suggestQuickSums;

  /// Each choice with its time here (ms); null: go to its own route.
  final ValueChanged<int>? onStory;
  final ValueChanged<int>? onQuick;

  /// Home tapped; null: straight Home.
  final VoidCallback? onHome;
  final int Function()? _now;

  @override
  State<ChooseTodayScreen> createState() => _ChooseTodayScreenState();
}

class _ChooseTodayScreenState extends State<ChooseTodayScreen> {
  int _now() => widget._now?.call() ?? DateTime.now().millisecondsSinceEpoch;
  late final int _shownAt = _now();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    void go(String path, ValueChanged<int>? chosen) {
      final ms = _now() - _shownAt;
      if (chosen != null) return chosen(ms);
      context.go(Uri(path: path, queryParameters: {'ms': '$ms'}).toString());
    }

    final story = AuraButton(
      key: const Key('todayStory'),
      label: l.kidTodayStory,
      icon: Icons.search_rounded,
      color: widget.suggestQuickSums
          ? AuraButtonColor.white
          : AuraButtonColor.blue,
      onPressed: () => go(Paths.lessonNext, widget.onStory),
    );
    final quick = AuraButton(
      key: const Key('todayQuick'),
      label: l.kidTodayQuick,
      icon: Icons.bolt_rounded,
      color: widget.suggestQuickSums
          ? AuraButtonColor.blue
          : AuraButtonColor.white,
      onPressed: () => go(Paths.quickSums, widget.onQuick),
    );
    return PlayMoment(
      top: Align(
        alignment: Alignment.centerLeft,
        child: PlayIconButton(
          icon: Icons.home_outlined,
          tooltip: l.kidHome,
          onPressed: widget.onHome ?? () => context.go(Paths.home),
        ),
      ),
      content: [
        const Portrait(size: 160),
        Ribbon(text: l.kidTodayTitle),
      ],
      bottom: ButtonStack(
        widget.suggestQuickSums ? [quick, story] : [story, quick],
      ),
    );
  }
}
