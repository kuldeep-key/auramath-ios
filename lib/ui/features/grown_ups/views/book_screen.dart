import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'parts.dart';

/// Book (652:35): this week's sessions with the server's note on each,
/// then skills and badges, the month view and the simple report.
class BookScreen extends StatelessWidget {
  const BookScreen({
    super.key,
    required this.childId,
    required this.family,
    required this.repo,
  });

  final String childId;
  final FamilyRepository family;
  final GrownUpRepository repo;

  @override
  Widget build(BuildContext context) => Loaded<(Child, List<Lesson>)>(
    load: () => withChild(family, childId, () => repo.lessons(childId)),
    fallback: Paths.grownUps,
    builder: (context, data, _) {
      final (child, lessons) = data;
      final l = AppLocalizations.of(context)!;
      return AuraPage(
        top: TitleBar(
          title: l.guBookTitle(child.name),
          fallback: Paths.grownUps,
        ),
        body: _Tabs(child: child, lessons: lessons, repo: repo),
        bottom: AuraButton(
          label: l.guWhatsNext,
          icon: Icons.map_outlined,
          color: AuraButtonColor.white,
          onPressed: () => context.push(Paths.plan(child.id)),
        ),
      );
    },
  );
}

class _Tabs extends StatefulWidget {
  const _Tabs({required this.child, required this.lessons, required this.repo});

  final Child child;
  final List<Lesson> lessons;
  final GrownUpRepository repo;

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final name = widget.child.name;
    final week = widget.lessons
        .where((s) => !s.startedAt.isBefore(weekStart(DateTime.now())))
        .toList();
    Widget note(String title, String body) => GuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AuraText.option),
          const SizedBox(height: 10),
          Text(body, style: AuraText.body.copyWith(fontSize: 16)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        _Segments(
          labels: [l.guTabWeek, l.guTabSkills, l.guTabBadges],
          selected: _tab,
          onSelect: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 14),
        ...switch (_tab) {
          0 when week.isEmpty => [
            note(l.guNothingSaved, l.guNothingThisWeek(name)),
          ],
          0 => [
            for (final s in week) ...[
              _SessionCard(lesson: s, repo: widget.repo),
              const SizedBox(height: 12),
            ],
          ],
          1 => [note(l.guTabSkills, l.guSkillsEmpty)],
          _ => [note(l.guTabBadges, l.guBadgesEmpty(name))],
        },
        const SizedBox(height: 12),
        GuCard(
          tint: true,
          onTap: () => context.push(Paths.month(widget.child.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.show_chart_rounded, color: AuraColors.blue),
                  const SizedBox(width: 6),
                  Text(l.guMonthView, style: AuraText.option),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l.guMonthViewBody,
                style: weight(
                  AuraText.body,
                  700,
                ).copyWith(fontSize: 16, color: AuraColors.mute),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AuraLink(
          label: l.guSimpleReport,
          onPressed: () => context.push(Paths.report(widget.child.id)),
        ),
      ],
    );
  }
}

/// This week / Skills / Badges.
class _Segments extends StatelessWidget {
  const _Segments({
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AuraColors.track,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        for (final (i, label) in labels.indexed)
          Expanded(
            child: Semantics(
              button: true,
              selected: i == selected,
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? AuraColors.blue : null,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: weight(AuraText.small, 800).copyWith(
                      fontSize: 14,
                      color: i == selected ? AuraColors.white : AuraColors.mute,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// "Tuesday · 12 min" and the server's sentences about it.
class _SessionCard extends StatefulWidget {
  const _SessionCard({required this.lesson, required this.repo});

  final Lesson lesson;
  final GrownUpRepository repo;

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  late final _lines = widget.repo.summary(widget.lesson.id);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = widget.lesson;
    final day = DateFormat.EEEE(
      Localizations.localeOf(context).toString(),
    ).format(s.startedAt);
    final body = AuraText.body.copyWith(fontSize: 16);
    return GuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.minutes == null
                ? l.guSessionUnfinished(day)
                : l.guSessionTitle(day, s.minutes!),
            style: AuraText.option,
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<String>>(
            future: _lines,
            builder: (context, snap) => Text(
              snap.hasError
                  ? l.guNoteError
                  : !snap.hasData
                  ? ''
                  : snap.data!.isEmpty
                  ? l.guNoNote
                  : snap.data!.join(' '),
              style: snap.hasData && snap.data!.isNotEmpty
                  ? body
                  : body.copyWith(color: AuraColors.mute),
            ),
          ),
        ],
      ),
    );
  }
}
