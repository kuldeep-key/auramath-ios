import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/lesson_header.dart';
import '../../../core/parts/speak_button.dart';
import '../../../core/theme/tokens.dart';

/// Choose today (LES-14): exactly two choices, the story problem or Quick
/// sums; either starts in one tap. The selector's suggestion comes first
/// (`todaySuggestion`; the story problem when the server sends none). The
/// choice is logged in the session it starts, as `choice_selected` with
/// its time here. After the starting check it shows inside the lesson,
/// which handles the choice ([onStory], [onQuick]).
/// Figma: A3 (journey 4.2); its "Taking away" is part of Quick sums.
/// Drawn as the prototype's A3 (16 Nov): the lesson's header, then two
/// big tiles, the first blue, the second white, popping in 100 ms apart.
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

    final title = l.kidTodayTitle;
    final first = _TodayTile(
      key: Key(widget.suggestQuickSums ? 'todayQuick' : 'todayStory'),
      label: widget.suggestQuickSums ? l.kidTodayQuick : l.kidTodayStory,
      art: widget.suggestQuickSums ? '➕➖' : '🍋🌳',
      blue: true,
      onTap: widget.suggestQuickSums
          ? () => go(Paths.quickSums, widget.onQuick)
          : () => go(Paths.lessonNext, widget.onStory),
    );
    final second = _TodayTile(
      key: Key(widget.suggestQuickSums ? 'todayStory' : 'todayQuick'),
      label: widget.suggestQuickSums ? l.kidTodayStory : l.kidTodayQuick,
      art: widget.suggestQuickSums ? '🍋🌳' : '➕➖',
      blue: false,
      delay: const Duration(milliseconds: 100),
      onTap: widget.suggestQuickSums
          ? () => go(Paths.lessonNext, widget.onStory)
          : () => go(Paths.quickSums, widget.onQuick),
    );
    return AuraPage(
      top: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: LessonHeader(
          line: title,
          onSpeak: () => ReadAloud.maybeOf(context)?.say(title),
          onHome: widget.onHome ?? () => context.go(Paths.home),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [first, second],
      ),
    );
  }
}

/// A choice on A3 (the prototype's `.tile`): radius 22, a navy edge and
/// 6 pt lip, the picture over the words; [blue] is the suggestion.
class _TodayTile extends StatelessWidget {
  const _TodayTile({
    super.key,
    required this.label,
    required this.art,
    required this.blue,
    required this.onTap,
    this.delay = Duration.zero,
  });

  final String label;
  final String art;
  final bool blue;
  final VoidCallback onTap;
  final Duration delay;

  @override
  Widget build(BuildContext context) => Pop(
    duration: const Duration(milliseconds: 500),
    curve: Curves.ease,
    delay: delay,
    child: Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          AuraHaptics.tap();
          onTap();
        },
        child: PressScale(
          child: Container(
            constraints: BoxConstraints(minHeight: blue ? 190 : 150),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: blue
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AuraColors.tileBlueTop, AuraColors.blue],
                    )
                  : null,
              color: blue ? null : AuraColors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AuraColors.navy, width: 3),
              boxShadow: const [
                BoxShadow(color: AuraColors.navy, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                Text(art, style: TextStyle(fontSize: blue ? 70 : 54)),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AuraText.button.copyWith(
                    color: blue ? AuraColors.white : AuraColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
