import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import 'setup_parts.dart';
import 'year_screen.dart' show yearLabel;

/// StartNotSure (643:145): what happens when the grown-up isn't sure.
class NotSureScreen extends StatelessWidget {
  const NotSureScreen({super.key, required this.draft});

  final SetupDraft draft;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final name = childName(context, draft.name);
    final year = draft.schoolYear;
    return AuraPage(
      top: setupTopBar(SetupStep.notSure),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(
            title: l.setupNotSureTitle,
            subtitle: sentence(
              year == null
                  ? l.setupNotSureBodyNoYear(name)
                  : l.setupNotSureBody(name, yearLabel(l, year)),
            ),
          ),
          InfoCard(
            rows: [
              (Icons.bolt_rounded, l.setupQuickSums, l.setupQuickSumsDetail),
              (
                Icons.mail_outline_rounded,
                l.setupEmailAfter,
                sentence(l.setupEmailAfterDetail(name)),
              ),
            ],
          ),
        ],
      ),
      bottom: AuraButton(
        label: l.setupContinue,
        color: AuraButtonColor.blue,
        onPressed: () => context.push(Paths.setupGoal),
      ),
    );
  }
}
