import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'parts.dart';

/// Plan (652:119), read-only: the server's next step, the spaced check if
/// one is open, and how long since the last lesson. Figma's "drag to
/// change what comes next" has no write route on the server yet.
class PlanScreen extends StatelessWidget {
  const PlanScreen({
    super.key,
    required this.childId,
    required this.family,
    required this.repo,
  });

  final String childId;
  final FamilyRepository family;
  final GrownUpRepository repo;

  @override
  Widget build(BuildContext context) => Loaded<(Child, ChildPlan)>(
    load: () => withChild(family, childId, () => repo.plan(childId)),
    fallback: Paths.grownUps,
    builder: (context, data, _) {
      final (child, plan) = data;
      final l = AppLocalizations.of(context)!;
      final checkDue = plan.checkDue;
      final empty = plan.next == null && checkDue == null;
      return AuraPage(
        top: const AuraTopBar(fallback: Paths.grownUps),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuraHeading(
              title: l.guChildPlan(child.name),
              subtitle: l.guPlanBody(child.name),
            ),
            if (empty)
              GuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.guPlanEmpty, style: AuraText.option),
                    const SizedBox(height: 6),
                    Text(
                      l.guPlanEmptyBody(child.name),
                      style: AuraText.cardLine,
                    ),
                  ],
                ),
              ),
            if (plan.next != null) ...[
              NavRow(
                icon: Icons.flag_outlined,
                label: plan.next!,
                detail: l.guPlanNext,
                chevron: false,
                onTap: null,
              ),
              const SizedBox(height: 12),
            ],
            if (checkDue != null) ...[
              NavRow(
                icon: Icons.fact_check_outlined,
                label: l.guPlanCheck,
                detail: plan.checkDueNow
                    ? l.guPlanCheckNow
                    : l.guPlanCheckOn(
                        DateFormat.MMMd(
                          Localizations.localeOf(context).toString(),
                        ).format(checkDue),
                      ),
                chevron: false,
                onTap: null,
              ),
              const SizedBox(height: 12),
            ],
            if (plan.awayDays != null)
              NavRow(
                icon: Icons.schedule_rounded,
                label: l.guPlanAway(plan.awayDays!),
                chevron: false,
                onTap: null,
              ),
          ],
        ),
      );
    },
  );
}
