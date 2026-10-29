import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import 'setup_parts.dart';

/// Data (643:203): the notice the grown-up agrees to (ACC-03). The consent
/// itself is recorded once they have signed in. Figma's "Learn more" is
/// left out until there is a full notice to link to.
class DataScreen extends StatelessWidget {
  const DataScreen({super.key, required this.draft});

  final SetupDraft draft;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      top: setupTopBar(SetupStep.data),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(
            title: sentence(l.setupDataTitle(childName(context, draft.name))),
          ),
          InfoCard(
            rows: [
              (
                Icons.location_on_outlined,
                l.setupDataStored,
                l.setupDataStoredDetail,
              ),
              (
                Icons.smart_toy_outlined,
                l.setupDataNoAi,
                l.setupDataNoAiDetail,
              ),
              (
                Icons.badge_outlined,
                l.setupDataFirstName,
                l.setupDataFirstNameDetail,
              ),
              (
                Icons.delete_outline_rounded,
                l.setupDataDelete,
                l.setupDataDeleteDetail,
              ),
            ],
          ),
        ],
      ),
      bottom: AuraButton(
        label: l.setupAgree,
        color: AuraButtonColor.blue,
        onPressed: () {
          draft.agreed = true;
          context.push(Paths.setupSave);
        },
      ),
    );
  }
}
