import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'parts.dart';

/// Settings (652:75): this phone's lesson settings, then the links.
/// Membership is not built this term, so its row is left out.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.family, required this.repo});

  final FamilyRepository family;
  final GrownUpRepository repo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Loaded<(LessonPrefs, List<Child>)>(
      load: () async => (await repo.loadPrefs(), await family.children()),
      fallback: Paths.grownUps,
      builder: (context, data, _) {
        final (prefs, children) = data;
        final first = children.isEmpty ? null : children.first;
        return AuraPage(
          top: const AuraTopBar(fallback: Paths.grownUps),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              Semantics(
                header: true,
                child: Text(l.guSettingsTitle, style: AuraText.heading),
              ),
              const SizedBox(height: 10),
              _LessonPrefsCard(initial: prefs, save: repo.savePrefs),
              const SizedBox(height: 14),
              NavRow(
                icon: Icons.group_outlined,
                label: l.guFamilyAndPhones,
                onTap: () => context.push(Paths.family),
              ),
              if (first != null) ...[
                const SizedBox(height: 12),
                NavRow(
                  icon: Icons.map_outlined,
                  label: l.guChildPlan(first.name),
                  onTap: () => context.push(Paths.plan(first.id)),
                ),
              ],
              const SizedBox(height: 12),
              NavRow(
                icon: Icons.mail_outline_rounded,
                label: l.guNotifyLink,
                onTap: () => context.push(Paths.notify),
              ),
              const SizedBox(height: 12),
              NavRow(
                icon: Icons.shield_outlined,
                label: l.guRightsLink,
                onTap: () => context.push(Paths.rights),
              ),
              const SizedBox(height: 12),
              NavRow(
                icon: Icons.person_add_outlined,
                label: l.guAddChild,
                onTap: () => context.push(Paths.addChild),
              ),
              const SizedBox(height: 12),
              NavRow(
                icon: Icons.logout_rounded,
                iconColor: AuraColors.coral,
                label: l.guSignOut,
                chevron: false,
                onTap: () => context.push(Paths.signOut),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Each row cycles through its choices on tap and is saved at once.
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
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    String onOff(bool v) => v ? l.guOn : l.guOff;
    const m = LessonPrefs.minuteChoices;
    return GuCard(
      child: Column(
        children: [
          KvRow(
            label: l.guSetTime,
            value: l.guSetMinutes(_p.minutes),
            hint: l.guSetChangeHint,
            onTap: () => _set(
              _p.copyWith(minutes: m[(m.indexOf(_p.minutes) + 1) % m.length]),
            ),
          ),
          KvRow(
            label: l.guSetReadAloud,
            value: onOff(_p.readAloud),
            hint: l.guSetChangeHint,
            onTap: () => _set(_p.copyWith(readAloud: !_p.readAloud)),
          ),
          KvRow(
            label: l.guSetPad,
            value: _p.phonePad ? l.guSetPadPhone : l.guSetPadApp,
            hint: l.guSetChangeHint,
            onTap: () => _set(_p.copyWith(phonePad: !_p.phonePad)),
          ),
          KvRow(
            label: l.guSetBigPad,
            value: onOff(_p.biggerPad),
            hint: l.guSetChangeHint,
            divider: false,
            onTap: () => _set(_p.copyWith(biggerPad: !_p.biggerPad)),
          ),
        ],
      ),
    );
  }
}
