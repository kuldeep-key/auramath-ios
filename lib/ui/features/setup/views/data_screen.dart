import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'setup_parts.dart';

/// Data (643:203): the notice the grown-up agrees to (ACC-03), naming the
/// services that process it and Julia's weekly summary (ACC-10, DRAFT
/// wording for Legal and Julia). The consent
/// itself is recorded once they have signed in. The prototype's
/// WhatWeHold: what we hold, who else sees anything, and the tick.
/// Figma's "Learn more" is
/// left out until there is a full notice to link to.
class DataScreen extends StatefulWidget {
  const DataScreen({super.key, required this.draft});

  final SetupDraft draft;

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  late bool _agreed = widget.draft.agreed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final draft = widget.draft;
    final name = childName(context, draft.name);
    return AuraPage(
      top: setupTopBar(SetupStep.data),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(
            title: sentence(l.setupDataTitle(name)),
            subtitle: l.setupDataSubtitle,
          ),
          InfoCard(
            rows: [
              (
                Icons.location_on_rounded,
                l.setupDataStored,
                l.setupDataStoredDetail,
              ),
              (
                Icons.badge_rounded,
                l.setupDataFirstName,
                l.setupDataFirstNameDetail,
              ),
              (Icons.touch_app_rounded, l.setupDataTaps, l.setupDataTapsDetail),
              (
                Icons.delete_rounded,
                l.setupDataDelete,
                l.setupDataDeleteDetail,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(
              l.setupDataWho.toUpperCase(),
              style: AuraText.eyebrow.copyWith(
                color: AuraColors.mute,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // DRAFT (ACC-10): the processors and Julia's weekly summary, for
          // Legal and Julia to word
          InfoCard(
            rows: [
              (Icons.smart_toy_rounded, l.setupDataAi, l.setupDataAiDetail),
              (
                Icons.record_voice_over_rounded,
                l.setupDataVoice,
                l.setupDataVoiceDetail,
              ),
              (Icons.mail_rounded, l.setupDataEmail, l.setupDataEmailDetail),
              (
                Icons.school_rounded,
                l.setupDataJuliaName,
                l.setupDataJuliaWeekly,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ConsentCheck(
            value: _agreed,
            label: l.setupDataConsent(name),
            onChanged: (v) => setState(() => _agreed = v),
          ),
        ],
      ),
      bottom: AuraButton(
        label: l.setupAgree,
        color: AuraButtonColor.blue,
        onPressed: _agreed
            ? () {
                draft.agreed = true;
                context.push(Paths.setupSave);
              }
            : null,
      ),
    );
  }
}
