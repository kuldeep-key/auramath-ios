import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/choice_tile.dart';
import 'setup_parts.dart';

/// Figma's goals and what each sends. The server knows only
/// `school_curriculum` and `not_sure` (services/child_profile.py, a
/// placeholder list until product supplies one), so a goal it doesn't know
/// is shown but not sent.
List<(String, String, String?)> goalOptions(AppLocalizations l) => [
  (l.setupGoalConfidence, l.setupGoalConfidenceDetail, null),
  (l.setupGoalCatchUp, l.setupGoalCatchUpDetail, 'school_curriculum'),
  (l.setupGoalAhead, l.setupGoalAheadDetail, null),
  (l.setupGoalWordProblems, l.setupGoalWordProblemsDetail, null),
];

/// Goal (643:169).
class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key, required this.draft});

  final SetupDraft draft;

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final options = goalOptions(l);
    return AuraPage(
      top: setupTopBar(SetupStep.goal),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(title: l.setupGoalTitle),
          for (final (i, (label, detail, _)) in options.indexed) ...[
            ChoiceTile(
              label: label,
              detail: detail,
              selected: _picked == i,
              onTap: () => setState(() => _picked = i),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
      bottom: AuraButton(
        label: l.setupContinue,
        color: AuraButtonColor.blue,
        onPressed: _picked == null
            ? null
            : () {
                widget.draft.goal = options[_picked!].$3;
                context.push(Paths.setupData);
              },
      ),
    );
  }
}
