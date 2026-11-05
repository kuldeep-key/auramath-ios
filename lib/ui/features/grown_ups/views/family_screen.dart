import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import '../../setup/views/year_screen.dart' show yearLabel;
import 'parts.dart';

typedef _Family = ({
  List<Member> members,
  List<Invite> invites,
  List<Child> children,
  List<Device> devices,
  List<Browser> browsers,
});

/// Family (652:213): the grown-ups and invitations, the children, and the
/// joined phones, each removable. Invite a grown-up, add a child's phone.
/// A child opens where they are. Removing a grown-up, cancelling an
/// invite and the signed-in list follow the server's rules (FamilyRules)
/// and have no Figma frame yet.
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key, required this.family, required this.repo});

  final FamilyRepository family;
  final GrownUpRepository repo;

  Future<_Family> _load() async {
    // Future.wait rethrows the first failure as it is, for ErrorNote
    final r = await Future.wait<Object>([
      repo.members(),
      repo.invites(),
      family.children(),
      repo.devices(),
      repo.browsers(),
    ]);
    return (
      members: r[0] as List<Member>,
      invites: r[1] as List<Invite>,
      children: r[2] as List<Child>,
      devices: r[3] as List<Device>,
      browsers: r[4] as List<Browser>,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Loaded<_Family>(
      load: _load,
      fallback: Paths.grownUps,
      builder: (context, f, reload) {
        Future<void> push(String path) async {
          await context.push(path);
          reload();
        }

        final rules = FamilyRules(f.members);
        Widget link(String label, String semantics, String path) => Semantics(
          label: semantics,
          button: true,
          excludeSemantics: true,
          onTap: () => push(path),
          child: AuraLink(label: label, onPressed: () => push(path)),
        );
        final grownUps = [
          for (final m in f.members)
            (
              m.you ? l.guYou(m.email) : m.email,
              m.owner ? l.guOwner : l.guGrownUp,
              rules.canRemove(m)
                  ? link(
                      l.guRemove,
                      l.guRemoveGrownUpLabel(m.email),
                      Paths.removeGrownUp(m.id!),
                    )
                  : null,
            ),
          for (final i in f.invites)
            rules.canCancel(i)
                ? (
                    l.guInvitedEmail(i.email),
                    null,
                    link(
                      l.guCancelInviteLink,
                      l.guCancelInviteLabel(i.email),
                      Paths.cancelInvite(i.id),
                    ),
                  )
                : (i.email, l.guInvited, null),
        ];
        return AuraPage(
          top: const AuraTopBar(fallback: Paths.grownUps),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              Semantics(
                header: true,
                child: Text(l.guFamilyTitle, style: AuraText.heading),
              ),
              const SizedBox(height: 4),
              SectionLabel(l.guGrownUps),
              GuCard(
                child: Column(
                  children: [
                    for (final (i, (who, role, action)) in grownUps.indexed)
                      KvRow(
                        label: who,
                        value: role,
                        trailing: action,
                        divider: i < grownUps.length - 1,
                      ),
                  ],
                ),
              ),
              SectionLabel(l.guChildren),
              GuCard(
                child: Column(
                  children: [
                    if (f.children.isEmpty)
                      KvRow(label: l.guNoChildrenRow, divider: false),
                    for (final (i, c) in f.children.indexed)
                      KvRow(
                        label: c.name,
                        value: c.schoolYear == null
                            ? null
                            : yearLabel(l, c.schoolYear!),
                        divider: i < f.children.length - 1,
                        hint: l.guOpenChildHint,
                        onTap: () => push(Paths.learning(c.id)),
                      ),
                  ],
                ),
              ),
              SectionLabel(l.guPhones),
              GuCard(
                child: Column(
                  children: [
                    if (f.devices.isEmpty)
                      KvRow(label: l.guNoPhones, divider: false),
                    for (final (i, d) in f.devices.indexed)
                      KvRow(
                        label: d.label,
                        divider: i < f.devices.length - 1,
                        trailing: link(
                          l.guRemove,
                          l.guRemovePhoneLabel(d.label),
                          Paths.removePhone(d.id),
                        ),
                      ),
                  ],
                ),
              ),
              SectionLabel(l.guSignedIn),
              GuCard(
                child: Column(
                  children: [
                    if (f.browsers.isEmpty)
                      KvRow(label: l.guNoBrowsers, divider: false),
                    for (final (i, b) in f.browsers.indexed)
                      KvRow(
                        label: b.label.isEmpty ? l.guBrowserUnnamed : b.label,
                        value: b.you ? l.guThisPhone : null,
                        divider: i < f.browsers.length - 1,
                        // this phone signs out from Settings, with its
                        // unsent lessons sent first
                        trailing: b.you
                            ? null
                            : link(
                                l.guSignOutBrowserLink,
                                l.guSignOutBrowserLabel(
                                  b.label.isEmpty
                                      ? l.guBrowserUnnamed
                                      : b.label,
                                ),
                                Paths.removeBrowser(b.id),
                              ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AuraButton(
                label: l.guInviteGrownUp,
                icon: Icons.person_add_outlined,
                color: AuraButtonColor.white,
                onPressed: () => push(Paths.invite),
              ),
              const SizedBox(height: 12),
              AuraButton(
                label: l.guAddPhone,
                icon: Icons.add_to_home_screen_rounded,
                color: AuraButtonColor.white,
                onPressed: () => push(Paths.newCode),
              ),
            ],
          ),
        );
      },
    );
  }
}
