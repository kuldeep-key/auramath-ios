import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/choice_tile.dart';
import '../../../core/theme/tokens.dart';
import 'setup_parts.dart';

/// Figma's "can already do" areas, in school order, and the skill id
/// (`content/skill-map.yaml`) each one sends: the server refuses any other.
/// ponytail: closest skills by hand; product to confirm the mapping.
List<(String, String)> canDoOptions(AppLocalizations l) => [
  (l.setupCanCount100, 'ns.count-fwd-30'),
  (l.setupCanAdd100, 'arith.addsub-2d'),
  (l.setupCanSub100, 'arith.addsub-2d-regroup'),
  (l.setupCanAdd1000, 'arith.add-3d-regroup'),
  (l.setupCanSub1000, 'arith.sub-3d-regroup'),
  (l.setupCanWordProblems, 'cmp.compare-bars'),
];

/// Start (643:102): pick everything that feels easy, or "I'm not sure".
class StartScreen extends StatefulWidget {
  const StartScreen({super.key, required this.draft});

  final SetupDraft draft;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late final _picked = {...widget.draft.canDo};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final draft = widget.draft;
    return AuraPage(
      top: setupTopBar(SetupStep.start),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(
            title: sentence(l.setupStartTitle(childName(context, draft.name))),
            subtitle: l.setupStartSubtitle,
          ),
          for (final (label, id) in canDoOptions(l)) ...[
            ChoiceTile(
              label: label,
              selected: _picked.contains(id),
              onTap: () => setState(
                () =>
                    _picked.contains(id) ? _picked.remove(id) : _picked.add(id),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _NotSureTile(
            onTap: () {
              draft
                ..startingPoint = 'not_sure'
                ..canDo = [];
              context.push(Paths.setupNotSure);
            },
          ),
        ],
      ),
      bottom: AuraButton(
        label: l.setupContinue,
        color: AuraButtonColor.blue,
        onPressed: _picked.isEmpty
            ? null
            : () {
                draft
                  ..startingPoint = 'chosen'
                  ..canDo = [..._picked];
                context.push(Paths.setupGoal);
              },
      ),
    );
  }
}

/// "I'm not sure · Help me figure it out": a way on, not a choice, so it
/// has a help icon and no tick.
class _NotSureTile extends StatelessWidget {
  const _NotSureTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final radius = BorderRadius.circular(AuraRadii.button);
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AuraColors.white,
              borderRadius: radius,
              border: Border.all(color: AuraColors.line, width: 2),
              boxShadow: const [
                BoxShadow(color: AuraColors.line, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.help_outline_rounded, color: AuraColors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.setupNotSure, style: AuraText.option),
                      Text(
                        l.setupNotSureDetail,
                        style: AuraText.small.copyWith(
                          color: AuraColors.mute,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
