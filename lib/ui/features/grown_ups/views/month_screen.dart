import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'parts.dart';

/// Monthly (658:121): this month's sessions and time. Figma's skill-steps
/// chart needs skill levels by name over time, which the server doesn't
/// report yet; the card says so rather than drawing made-up steps.
class MonthScreen extends StatelessWidget {
  const MonthScreen({
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
      final now = DateTime.now();
      final month = DateFormat.MMMM(
        Localizations.localeOf(context).toString(),
      ).format(now);
      final sums = tally(lessons, DateTime(now.year, now.month));
      return AuraPage(
        top: const AuraTopBar(fallback: Paths.grownUps),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuraHeading(
              title: l.guMonthTitle(child.name, month),
              subtitle: l.guMonthBody(month),
            ),
            GuCard(
              child: Column(
                children: [
                  KvRow(label: l.guMonthSessions, value: '${sums.count}'),
                  KvRow(
                    label: l.guMonthTime,
                    value: l.guSetMinutes(sums.minutes),
                    divider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GuCard(
              child: Row(
                children: [
                  const Icon(Icons.show_chart_rounded, color: AuraColors.mute),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.guMonthChartLater(child.name),
                      style: AuraText.cardLine.copyWith(color: AuraColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
