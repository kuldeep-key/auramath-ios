import 'package:flutter/material.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../data/repositories/report_email_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/aura_sheet.dart';
import '../../../core/parts/aura_toast.dart';
import '../../../core/parts/choice_tile.dart';
import 'parts.dart';
import 'report_email_card.dart';

/// Settings (652:75, the prototype's Settings): this phone's lesson
/// settings and the family's report email (PAR-05). Time each day opens a
/// picker sheet; the rest are switches; each change says Saved. The
/// family, rights and sign-out rows live on the Family area (GHome).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.family,
    required this.repo,
    required this.email,
  });

  final FamilyRepository family;
  final GrownUpRepository repo;
  final ReportEmailRepository email;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Loaded<LessonPrefs>(
      load: repo.loadPrefs,
      fallback: Paths.grownUps,
      builder: (context, prefs, _) {
        return AuraPage(
          top: const AuraTopBar(fallback: Paths.grownUps),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuraHeading(title: l.guSettingsTitle),
              _LessonPrefsCard(initial: prefs, save: repo.savePrefs),
              const SizedBox(height: 12),
              ReportEmailCard(email: email),
            ],
          ),
        );
      },
    );
  }
}

/// Time each day (a picker), read-aloud and the bigger pad (switches),
/// each saved at once.
class _LessonPrefsCard extends StatefulWidget {
  const _LessonPrefsCard({required this.initial, required this.save});

  final LessonPrefs initial;
  final Future<void> Function(LessonPrefs) save;

  @override
  State<_LessonPrefsCard> createState() => _LessonPrefsCardState();
}

class _LessonPrefsCardState extends State<_LessonPrefsCard> {
  late LessonPrefs _p = widget.initial;

  void _set(LessonPrefs p) {
    setState(() => _p = p);
    widget.save(p);
    AuraToast.show(context, AppLocalizations.of(context)!.guSaved);
  }

  /// The prototype's `pick`: a sheet of the four lengths.
  Future<void> _pickMinutes() async {
    final l = AppLocalizations.of(context)!;
    final picked = await showAuraSheet<int>(
      context,
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeading(title: l.guSetTime, body: l.guSetTimeSheetBody),
          for (final m in LessonPrefs.minuteChoices) ...[
            ChoiceTile(
              label: l.guSetMinutesLong(m),
              selected: m == _p.minutes,
              onTap: () => Navigator.of(context).pop(m),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
    if (picked != null && mounted && picked != _p.minutes) {
      _set(_p.copyWith(minutes: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GuCard(
      child: Column(
        children: [
          KvRow(
            label: l.guSetTime,
            value: l.guSetMinutes(_p.minutes),
            chevron: true,
            hint: l.guSetChangeHint,
            onTap: _pickMinutes,
          ),
          SwitchRow(
            label: l.guSetReadAloud,
            detail: l.guSetReadAloudDetail,
            value: _p.readAloud ?? true,
            onChanged: (v) => _set(_p.copyWith(readAloud: v)),
          ),
          SwitchRow(
            label: l.guSetBigPad,
            detail: l.guSetBigPadDetail,
            value: _p.biggerPad,
            divider: false,
            onChanged: (v) => _set(_p.copyWith(biggerPad: v)),
          ),
        ],
      ),
    );
  }
}
