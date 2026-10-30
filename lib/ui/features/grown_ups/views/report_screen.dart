import 'package:flutter/material.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_page.dart';
import 'parts.dart';

/// R0 · Simple report (667:44): this week in numbers the server holds,
/// and the plan's next step. Figma's "Working on" and per-skill rows wait
/// for the server to report skills by name.
class ReportScreen extends StatelessWidget {
  const ReportScreen({
    super.key,
    required this.childId,
    required this.family,
    required this.repo,
  });

  final String childId;
  final FamilyRepository family;
  final GrownUpRepository repo;

  @override
  Widget build(BuildContext context) =>
      Loaded<(Child, (List<Lesson>, ChildPlan))>(
        load: () => withChild(
          family,
          childId,
          () async => (await repo.lessons(childId), await repo.plan(childId)),
        ),
        fallback: Paths.grownUps,
        builder: (context, data, _) {
          final (_, (lessons, plan)) = data;
          final l = AppLocalizations.of(context)!;
          final week = tally(lessons, weekStart(DateTime.now()));
          return AuraPage(
            top: const AuraTopBar(fallback: Paths.grownUps),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuraHeading(title: l.guReportTitle, subtitle: l.guReportBody),
                GuCard(
                  child: Column(
                    children: [
                      KvRow(label: l.guReportSessions, value: '${week.count}'),
                      KvRow(
                        label: l.guReportTime,
                        value: l.guSetMinutes(week.minutes),
                      ),
                      KvRow(
                        label: l.guReportNext,
                        value: plan.next ?? l.guReportNextNone,
                        divider: false,
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
