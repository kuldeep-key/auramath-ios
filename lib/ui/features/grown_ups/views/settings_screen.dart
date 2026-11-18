import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/child_settings.dart';
import '../../../../data/repositories/child_settings_repository.dart';
import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../data/repositories/report_email_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../data/services/sound_effects.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/aura_sheet.dart';
import '../../../core/parts/aura_toast.dart';
import '../../../core/parts/choice_tile.dart';
import 'parts.dart';
import 'report_email_card.dart';

/// What Settings shows: each child with their settings from the server,
/// and this phone's own.
typedef _SettingsData = ({
  List<(Child, ChildSettings?)> children,
  LessonPrefs prefs,
});

/// Settings (652:75, Figma 1046:7536): each child's time each day and
/// read-aloud, kept on the server so every family phone has them (PAR-05);
/// this phone's bigger pad; the family's report email; and Report a
/// problem (PAR-13). Time each day opens a picker sheet; the rest are
/// switches; each change says Saved. The family, rights and sign-out rows
/// live on the Family area (GHome).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.family,
    required this.repo,
    required this.email,
    required this.settings,
  });

  final FamilyRepository family;
  final GrownUpRepository repo;
  final ReportEmailRepository email;
  final ChildSettingsRepository settings;

  Future<_SettingsData> _load() async {
    final kids = await family.children();
    final out = <(Child, ChildSettings?)>[];
    for (final c in kids) {
      // the list of children carries them; an older server: ask, else
      // what this phone kept
      ChildSettings? s = c.settings;
      if (s != null) {
        await settings.remember(s);
      } else {
        try {
          s = await settings.load(c.id);
        } on ApiException {
          s = await settings.cached(c.id);
        }
      }
      out.add((c, s));
    }
    return (children: out, prefs: await repo.loadPrefs());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Loaded<_SettingsData>(
      load: _load,
      fallback: Paths.grownUps,
      builder: (context, data, _) {
        return AuraPage(
          top: const AuraTopBar(fallback: Paths.grownUps),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuraHeading(title: l.guSettingsTitle),
              for (final (child, s) in data.children) ...[
                PartLabel(child.name, top: 8),
                s == null
                    ? GuCard(child: Text(l.guSetCantRead))
                    : ChildSettingsCard(
                        key: ValueKey('settings-${child.id}'),
                        initial: s,
                        repo: settings,
                      ),
              ],
              PartLabel(l.guSetThisPhone),
              _PadCard(initial: data.prefs, save: repo.savePrefs),
              const SizedBox(height: 12),
              ReportEmailCard(email: email),
              const SizedBox(height: 12),
              // PAR-13: reachable without leaving the app
              NavRow(
                icon: Icons.flag_outlined,
                label: l.reportProblemRow,
                detail: l.reportProblemRowDetail,
                onTap: () => context.push(Paths.reportProblem),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One child's time each day (a picker) and read-aloud (a switch), each
/// saved on the server at once (PAR-05). A change that can't be saved goes
/// back and says why.
class ChildSettingsCard extends StatefulWidget {
  const ChildSettingsCard({
    super.key,
    required this.initial,
    required this.repo,
  });

  final ChildSettings initial;
  final ChildSettingsRepository repo;

  @override
  State<ChildSettingsCard> createState() => _ChildSettingsCardState();
}

class _ChildSettingsCardState extends State<ChildSettingsCard> {
  late ChildSettings _s = widget.initial;
  bool _saving = false;

  /// What "No limit" is in the picker: the sheet pops an int.
  static const _noLimit = 0;

  Future<void> _save(
    ChildSettings shown,
    Future<ChildSettings> Function() send,
  ) async {
    final before = _s;
    setState(() {
      _s = shown;
      _saving = true;
    });
    final l = AppLocalizations.of(context)!;
    try {
      final saved = await send();
      if (!mounted) return;
      setState(() => _s = saved);
      // the sound effects follow the grown-up's read-aloud on this phone
      if (!saved.readAloudIsDefault) AuraSound.soundOn.value = saved.readAloud;
      AuraToast.show(context, l.guSaved);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _s = before);
      AuraToast.show(context, e.offline ? l.guSetOffline : l.guSetNotSaved);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  ChildSettings _with({int? minutes, bool setMinutes = false, bool? read}) =>
      ChildSettings(
        childId: _s.childId,
        dailyLimitMinutes: setMinutes ? minutes : _s.dailyLimitMinutes,
        dailyLimitIsDefault: setMinutes ? false : _s.dailyLimitIsDefault,
        readAloud: read ?? _s.readAloud,
        readAloudIsDefault: read != null ? false : _s.readAloudIsDefault,
      );

  /// The prototype's `pick`: a sheet of the lengths, and no limit.
  Future<void> _pickMinutes() async {
    final l = AppLocalizations.of(context)!;
    final now = _s.dailyLimitMinutes ?? _noLimit;
    final picked = await showAuraSheet<int>(
      context,
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeading(title: l.guSetTime, body: l.guSetTimeSheetBody),
          for (final m in [...ChildSettings.minuteChoices, _noLimit]) ...[
            ChoiceTile(
              label: m == _noLimit ? l.guSetNoLimit : l.guSetMinutesLong(m),
              selected: m == now,
              onTap: () => Navigator.of(context).pop(m),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
    if (picked == null || !mounted || picked == now) return;
    final minutes = picked == _noLimit ? null : picked;
    await _save(
      _with(minutes: minutes, setMinutes: true),
      () => widget.repo.save(_s.childId, dailyLimitMinutes: minutes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final minutes = _s.dailyLimitMinutes;
    return GuCard(
      child: Column(
        children: [
          KvRow(
            label: l.guSetTime,
            value: minutes == null ? l.guSetNoLimit : l.guSetMinutes(minutes),
            chevron: true,
            hint: l.guSetChangeHint,
            onTap: _saving ? null : _pickMinutes,
          ),
          SwitchRow(
            label: l.guSetReadAloud,
            detail: l.guSetReadAloudDetail,
            value: _s.readAloud,
            divider: false,
            onChanged: _saving
                ? null
                : (v) => _save(
                    _with(read: v),
                    () => widget.repo.save(_s.childId, readAloud: v),
                  ),
          ),
        ],
      ),
    );
  }
}

/// This phone's bigger pad (a switch), saved at once on the phone.
class _PadCard extends StatefulWidget {
  const _PadCard({required this.initial, required this.save});

  final LessonPrefs initial;
  final Future<void> Function(LessonPrefs) save;

  @override
  State<_PadCard> createState() => _PadCardState();
}

class _PadCardState extends State<_PadCard> {
  late LessonPrefs _p = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GuCard(
      child: SwitchRow(
        label: l.guSetBigPad,
        detail: l.guSetBigPadDetail,
        value: _p.biggerPad,
        divider: false,
        onChanged: (v) {
          setState(() => _p = _p.copyWith(biggerPad: v));
          widget.save(_p);
          AuraToast.show(context, l.guSaved);
        },
      ),
    );
  }
}
