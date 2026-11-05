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
import 'parts.dart';

/// PHome (658:84): the family's children, Family, and back to the child.
/// Progress goes to the grown-up by email (D-39), so the book, month and
/// plan screens aren't linked from here.
class GrownUpHomeScreen extends StatelessWidget {
  const GrownUpHomeScreen({
    super.key,
    required this.account,
    required this.family,
    required this.repo,
  });

  final AccountRepository account;
  final FamilyRepository family;
  final GrownUpRepository repo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final top = AuraTopBar(
      close: true,
      onBack: () => context.go(Paths.kids),
      trailing: IconButton(
        tooltip: l.guSettingsTitle,
        icon: const Icon(Icons.settings_outlined, color: AuraColors.ink),
        onPressed: () => context.push(Paths.settings),
      ),
    );
    return Loaded<List<Child>>(
      load: family.children,
      builder: (context, children, reload) {
        Future<void> push(String path) async {
          await context.push(path);
          reload();
        }

        final back = children
            .where((c) => c.id == account.childId)
            .followedBy(children)
            .firstOrNull;
        return AuraPage(
          top: top,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              Semantics(
                header: true,
                child: Text(l.guHomeHi, style: AuraText.heading),
              ),
              const SizedBox(height: 10),
              if (children.isEmpty)
                GuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.guHomeNoChildren, style: AuraText.option),
                      const SizedBox(height: 4),
                      Text(l.guHomeNoChildrenBody, style: AuraText.cardLine),
                      const SizedBox(height: 8),
                      AuraLink(
                        label: l.guAddChild,
                        onPressed: () => push(Paths.addChild),
                      ),
                    ],
                  ),
                ),
              for (final c in children) ...[
                _ChildCard(child: c, lessons: () => repo.lessons(c.id)),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),
              AuraButton(
                label: l.guHomeFamily,
                icon: Icons.group_outlined,
                color: AuraButtonColor.white,
                onPressed: () => push(Paths.family),
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

/// A child: avatar, name, this week's sessions.
class _ChildCard extends StatefulWidget {
  const _ChildCard({required this.child, required this.lessons});

  final Child child;
  final Future<List<Lesson>> Function() lessons;

  @override
  State<_ChildCard> createState() => _ChildCardState();
}

class _ChildCardState extends State<_ChildCard> {
  late final _lessons = widget.lessons();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final child = widget.child;
    return GuCard(
      child: Row(
        children: [
          ChildAvatar(name: child.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.name, style: AuraText.option),
                const SizedBox(height: 4),
                FutureBuilder<List<Lesson>>(
                  future: _lessons,
                  builder: (context, snap) => Text(
                    snap.hasError
                        ? l.guProgressError
                        : snap.hasData
                        ? l.guHomeWeek(
                            tally(snap.data!, weekStart(DateTime.now())).count,
                          )
                        : '',
                    style: AuraText.cardLine,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
