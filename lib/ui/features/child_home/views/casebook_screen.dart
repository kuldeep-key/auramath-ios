import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../data/repositories/casebook_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/journey_art.dart';
import '../../../core/theme/tokens.dart';
import 'play_icon_button.dart';
import 'play_moment.dart';

/// CB1 "My casebook" (REW-15, Figma 1043:11224): the child's solved cases
/// under their day, newest day first; each day's heading says it (Today,
/// Last time, then the date) with that day's session badge, and each case
/// is a card with its story sticker and its name. Never a count, a total
/// or "N of M" (catalogue `story_stickers.counter_shown: false`, REW-03).
/// Tapping a case opens it (CB2). With none yet, the tutor and one line.
class CasebookScreen extends StatelessWidget {
  const CasebookScreen({
    super.key,
    required this.days,
    required this.today,
    this.pictures = const {},
    this.world = 'detective',
    this.tutorId,
    this.tutorKind = 'grown_up_teacher',
  });

  /// Newest day first, as the server sends them.
  final List<CasebookDay> days;

  /// The phone's today, for the newest day's heading.
  final DateTime today;

  /// Story objects' pictures by lower-case name (the pack's), for stickers.
  final Map<String, String> pictures;
  final String world;
  final String? tutorId;
  final String tutorKind;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayName(AppLocalizations l, int i, DateTime date, String locale) {
    if (_sameDay(date, today)) return l.kidCasebookToday;
    // the newest day before today is "last time"; older days by their date
    final firstPast = days.indexWhere((d) => !_sameDay(d.date, today));
    if (i == firstPast) return l.kidCasebookLastTime;
    return DateFormat.MMMMEEEEd(locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final shown = [
      for (final d in days)
        if (d.cases.isNotEmpty) d,
    ];
    return AuraPage(
      play: true,
      say: shown.isEmpty
          ? '${l.kidMyCasebook}. ${l.kidCasebookEmpty}'
          : l.kidMyCasebook,
      top: PlayHeader(title: l.kidMyCasebook),
      body: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        child: shown.isEmpty
            ? Column(
                key: const Key('casebookEmpty'),
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 12,
                children: [
                  if (tutorId != null)
                    TutorFigure(
                      tutorId: tutorId!,
                      kind: tutorKind,
                      world: world,
                      size: 150,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: PlayLine(l.kidCasebookEmpty),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, d) in shown.indexed) ...[
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 18, bottom: 8),
                      child: Semantics(
                        header: true,
                        child: Text(
                          d.sessionBadges.isEmpty
                              ? _dayName(l, i, d.date, locale)
                              : l.kidCasebookDayBadge(
                                  _dayName(l, i, d.date, locale),
                                  d.sessionBadges.map((b) => b.name).join(', '),
                                ),
                          style: AuraText.badgeNext.copyWith(fontSize: 17),
                        ),
                      ),
                    ),
                    for (final (j, c) in d.cases.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Pop(
                          duration: const Duration(milliseconds: 400),
                          delay: Duration(milliseconds: (i + j) * 60),
                          child: _CaseCard(entry: c, pictures: pictures),
                        ),
                      ),
                  ],
                ],
              ),
      ),
      bottom: AuraButton(
        label: l.kidBackHome,
        onPressed: () => context.go(Paths.home),
      ),
    );
  }
}

/// A case in the day view: its sticker, its name, and the way in.
class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.entry, required this.pictures});

  final CasebookCase entry;
  final Map<String, String> pictures;

  @override
  Widget build(BuildContext context) {
    final name = caseName(entry);
    return Semantics(
      button: true,
      label: name,
      excludeSemantics: true,
      child: GestureDetector(
        key: Key('case-${entry.problemId}'),
        onTap: () {
          AuraHaptics.tap();
          context.push(Paths.casebookCase(entry.problemId));
        },
        child: PressScale(
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
            decoration: BoxDecoration(
              color: AuraColors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AuraColors.navy, width: 3),
              boxShadow: const [
                BoxShadow(color: AuraColors.navy, offset: Offset(0, 6)),
              ],
            ),
            child: Row(
              spacing: 12,
              children: [
                StickerArt(sticker: entry.sticker, pictures: pictures),
                Expanded(
                  child: Text(
                    name,
                    style: AuraText.caseTitle.copyWith(
                      color: AuraColors.keyText,
                      fontSize: 19,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AuraColors.navy,
                  size: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The case's plain name (TUT-12); a case the server didn't name, by its
/// story's object ("Lemon tree").
String caseName(CasebookCase c) {
  final n = c.name?.trim() ?? '';
  return n.isNotEmpty ? n : stickerName(c.sticker);
}

/// A sticker's name: its story's object, as a name ("Lemon tree").
String stickerName(CaseSticker s) {
  final o = s.object.trim();
  return o.isEmpty ? o : o[0].toUpperCase() + o.substring(1);
}

/// A case's story sticker (catalogue `story_stickers`): the picture of the
/// story's object, from the pack's stories, else by its words; a story
/// the phone has no picture for gets the detective's glass.
class StickerArt extends StatelessWidget {
  const StickerArt({
    super.key,
    required this.sticker,
    this.pictures = const {},
    this.size = 44,
  });

  final CaseSticker sticker;
  final Map<String, String> pictures;
  final double size;

  static const _words = {
    'lemon': '🍋',
    'mango': '🥭',
    'guava': '🍐',
    'pear': '🍐',
    'orange': '🍊',
    'apple': '🍎',
    'palm': '🌴',
    'fig': '🌳',
    'gum': '🌳',
    'tree': '🌳',
    'bowl': '🥣',
    'mug': '☕',
    'cup': '☕',
    'rocket': '🚀',
  };

  static String pictureOf(String object, Map<String, String> pictures) {
    final o = object.toLowerCase().trim();
    if (pictures[o] case final p?) return p;
    for (final w in o.split(RegExp(r'[^a-z]+'))) {
      if (_words[w] case final p?) return p;
    }
    return '🔍';
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context)!.kidCaseSticker(sticker.object),
    excludeSemantics: true,
    child: SizedBox.square(
      dimension: size,
      child: FittedBox(
        child: Text(
          pictureOf(sticker.object, pictures),
          style: TextStyle(fontSize: size * .86, height: 1.1),
        ),
      ),
    ),
  );
}
