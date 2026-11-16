import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import '../../setup/views/year_screen.dart' show yearLabel;
import 'parts.dart';

/// GHome, the prototype's Family area (PRD §10.5): one hub behind the
/// passcode. The children (each opens where they are, ChildDetail), Add a
/// child, then This family: Settings, Phones and family, Your data and
/// rights, Sign out of this phone. Progress goes to the grown-up by email
/// (D-39), so nothing here grades the child. Once consent is withdrawn, a
/// card says lessons are paused and links to Rights. With
/// `recent_notes_in_app` on, each child links to their last five notes
/// (PAR-12).
///
/// The children are read again whenever this phone changes one
/// ([FamilyRepository.childrenChanged]), so a new name shows here at once.
class GrownUpHomeScreen extends StatelessWidget {
  const GrownUpHomeScreen({
    super.key,
    required this.account,
    required this.family,
    required this.repo,
    this.recentNotes = false,
  });

  final AccountRepository account;
  final FamilyRepository family;
  final GrownUpRepository repo;

  /// Flag `recent_notes_in_app` (off by default).
  final bool recentNotes;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Loaded<({List<Child> children, bool consented})>(
      load: family.family,
      refresh: family.childrenChanged,
      builder: (context, f, reload) {
        final children = f.children;
        Future<void> push(String path) async {
          await context.push(path);
          reload();
        }

        final back = children
            .where((c) => c.id == account.childId)
            .followedBy(children)
            .firstOrNull;
        return AuraPage(
          top: _HubBar(
            title: l.guHomeHi,
            onClose: () => context.go(Paths.kids),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PartLabel(l.guHomeChildren, top: 4),
              if (!f.consented && children.isNotEmpty) ...[
                GuCard(
                  child: Semantics(
                    liveRegion: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.guHomePaused, style: AuraText.option),
                        const SizedBox(height: 4),
                        Text(l.guHomePausedBody, style: AuraText.cardLine),
                        const SizedBox(height: 8),
                        AuraLink(
                          label: l.guHomePausedLink,
                          onPressed: () => push(Paths.rights),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (children.isEmpty) ...[
                // the prototype's EmptyChildren
                EmptyNote(
                  icon: Icons.child_care_rounded,
                  title: l.guHomeNoChildren,
                  body: l.guHomeNoChildrenBody,
                ),
                const SizedBox(height: 12),
              ],
              for (final c in children) ...[
                _ChildCard(
                  key: ValueKey('${c.id}/${c.name}'),
                  child: c,
                  lessons: () => repo.lessons(c.id),
                  onOpen: () => push(Paths.learning(c.id)),
                  onNotes: recentNotes ? () => push(Paths.notes(c.id)) : null,
                ),
                const SizedBox(height: 12),
              ],
              NavRow(
                icon: Icons.person_add_rounded,
                label: l.guAddChild,
                detail: l.guHomeAddChildDetail,
                chevron: false,
                onTap: () => push(Paths.addChild),
              ),
              PartLabel(l.guHomeThisFamily, top: 22),
              NavRow(
                icon: Icons.tune_rounded,
                label: l.guSettingsTitle,
                detail: l.guHomeSettingsDetail,
                onTap: () => push(Paths.settings),
              ),
              const SizedBox(height: 12),
              NavRow(
                icon: Icons.devices_rounded,
                label: l.guHomePhones,
                detail: l.guHomePhonesDetail,
                onTap: () => push(Paths.family),
              ),
              const SizedBox(height: 12),
              NavRow(
                icon: Icons.shield_rounded,
                label: l.guRightsLink,
                detail: l.guHomeRightsDetail,
                onTap: () => push(Paths.rights),
              ),
              const SizedBox(height: 12),
              NavRow(
                icon: Icons.logout_rounded,
                iconColor: AuraColors.mute,
                label: l.guHomeSignOut,
                chevron: false,
                onTap: () => push(Paths.signOut),
              ),
            ],
          ),
          bottom: back == null
              ? null
              : AuraButton(
                  label: l.guHomeBackTo(back.name),
                  color: AuraButtonColor.blue,
                  onPressed: () async {
                    await account.chooseChild(back.id);
                    if (context.mounted) context.go(Paths.home);
                  },
                ),
        );
      },
      fallback: Paths.kids,
    );
  }
}

/// ✕ and the area's name beside it, Bold 18 (the prototype's GHome top).
class _HubBar extends StatelessWidget {
  const _HubBar({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close_rounded, color: AuraColors.ink),
          onPressed: onClose,
        ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: AuraText.barTitle),
          ),
        ),
      ],
    ),
  );
}

/// A child: portrait, name, "8, Year 3 · 2 sessions this week", chevron;
/// the whole card opens where they are.
class _ChildCard extends StatefulWidget {
  const _ChildCard({
    super.key,
    required this.child,
    required this.lessons,
    required this.onOpen,
    this.onNotes,
  });

  final Child child;
  final Future<List<Lesson>> Function() lessons;
  final VoidCallback onOpen;

  /// Recent notes (PAR-12), when the flag is on.
  final VoidCallback? onNotes;

  @override
  State<_ChildCard> createState() => _ChildCardState();
}

class _ChildCardState extends State<_ChildCard> {
  late final _lessons = widget.lessons();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final child = widget.child;
    final age = child.age;
    final year = child.schoolYear == null
        ? null
        : yearLabel(l, child.schoolYear!);
    final about = age != null && year != null
        ? l.guHomeAbout(age, year)
        : age != null
        ? l.guHomeAge(age)
        : year;
    return GuCard(
      onTap: widget.onOpen,
      label: child.name,
      child: Row(
        children: [
          ChildAvatar(name: child.name, avatar: child.avatar),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.name, style: AuraText.option),
                const SizedBox(height: 2),
                FutureBuilder<List<Lesson>>(
                  future: _lessons,
                  builder: (context, snap) {
                    final week = snap.hasError
                        ? l.guProgressError
                        : snap.hasData
                        ? l.guHomeWeek(
                            tally(snap.data!, weekStart(DateTime.now())).count,
                          )
                        : null;
                    return Text(
                      [?about, ?week].join(' · '),
                      style: AuraText.optionDetail.copyWith(
                        fontWeight: FontWeight.w700,
                        fontVariations: const [FontVariation('wght', 700)],
                      ),
                    );
                  },
                ),
                if (widget.onNotes != null)
                  AuraLink(label: l.guNotesLink, onPressed: widget.onNotes),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AuraColors.ink),
        ],
      ),
    );
  }
}
