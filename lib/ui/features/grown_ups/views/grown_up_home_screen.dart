import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'parts.dart';

/// PHome (658:84): the family's children, each opening their book; the
/// month's progress, Family, Plan, and back to the child.
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

        final first = children.isEmpty ? null : children.first;
        final back = children
            .where((c) => c.id == account.childId)
            .followedBy(children)
            .firstOrNull;
        final month = DateFormat.MMMM(
          Localizations.localeOf(context).toString(),
        ).format(DateTime.now());
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
                _ChildCard(
                  child: c,
                  lessons: () => repo.lessons(c.id),
                  onTap: () => push(Paths.book(c.id)),
                ),
                const SizedBox(height: 12),
              ],
              if (first != null) ...[
                GuCard(
                  tint: true,
                  label:
                      '${l.guHomeProgressTitle(month)}. '
                      '${l.guHomeProgressBody(first.name)}',
                  onTap: () => push(Paths.month(first.id)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.show_chart_rounded,
                            color: AuraColors.blue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l.guHomeProgressTitle(month),
                            style: AuraText.option,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l.guHomeProgressBody(first.name),
                        style: AuraText.cardLine,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: AuraButton(
                      label: l.guHomeFamily,
                      icon: Icons.group_outlined,
                      color: AuraButtonColor.white,
                      onPressed: () => push(Paths.family),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AuraButton(
                      label: l.guHomePlan,
                      icon: Icons.map_outlined,
                      color: AuraButtonColor.white,
                      onPressed: first == null
                          ? null
                          : () => push(Paths.plan(first.id)),
                    ),
                  ),
                ],
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

/// A child: avatar, name, this week's sessions; opens their book.
class _ChildCard extends StatefulWidget {
  const _ChildCard({
    required this.child,
    required this.lessons,
    required this.onTap,
  });

  final Child child;
  final Future<List<Lesson>> Function() lessons;
  final VoidCallback onTap;

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
      onTap: widget.onTap,
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
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
