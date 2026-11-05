import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'parts.dart';

typedef _Family = ({
  List<Member> members,
  List<Invite> invites,
  List<Child> children,
  List<Device> devices,
});

/// Family (652:213): the grown-ups and invitations, the children, and the
/// joined phones, each removable. Invite a grown-up, add a child's phone.
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
    ]);
    return (
      members: r[0] as List<Member>,
      invites: r[1] as List<Invite>,
      children: r[2] as List<Child>,
      devices: r[3] as List<Device>,
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

        final grownUps = [
          for (final m in f.members)
            (
              m.you ? l.guYou(m.email) : m.email,
              m.owner ? l.guOwner : l.guGrownUp,
            ),
          for (final i in f.invites) (i.email, l.guInvited),
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
                    for (final (i, (who, role)) in grownUps.indexed)
                      KvRow(
                        label: who,
                        value: role,
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
                        value: c.schoolYear,
                        divider: i < f.children.length - 1,
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
                        trailing: Semantics(
                          label: l.guRemovePhoneLabel(d.label),
                          button: true,
                          excludeSemantics: true,
                          onTap: () => push(Paths.removePhone(d.id)),
                          child: AuraLink(
                            label: l.guRemove,
                            onPressed: () => push(Paths.removePhone(d.id)),
                          ),
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
