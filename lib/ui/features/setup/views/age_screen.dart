import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'setup_parts.dart';

/// The ages offered, 6 to 10 (D-36); the server takes 4 to 12. A parent of
/// a younger or older child reads the line under them (E25).
const setupAges = [6, 7, 8, 9, 10];

/// Age (643:40).
class AgeScreen extends StatefulWidget {
  const AgeScreen({super.key, required this.draft});

  final SetupDraft draft;

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  late int? _age = widget.draft.age;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      top: setupTopBar(SetupStep.age),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(
            title: sentence(
              l.setupAgeTitle(childName(context, widget.draft.name)),
            ),
          ),
          AgeChips(
            ages: widget.draft.options?.ages ?? setupAges,
            selected: _age,
            onPick: (age) => setState(() => _age = age),
          ),
          // D-36, E25: the range is said here too (not in the prototype)
          const SizedBox(height: 16),
          Text(l.setupAgeRange, style: AuraText.cardLine),
        ],
      ),
      bottom: AuraButton(
        label: l.setupContinue,
        color: AuraButtonColor.blue,
        onPressed: _age == null
            ? null
            : () {
                if (widget.draft.age != _age) widget.draft.schoolYear = null;
                widget.draft.age = _age;
                context.push(Paths.setupYear);
              },
      ),
    );
  }
}

/// The ages in one row (`.chips`): five share the width, more wrap.
class AgeChips extends StatelessWidget {
  const AgeChips({
    super.key,
    required this.ages,
    required this.selected,
    required this.onPick,
  });

  final List<int> ages;
  final int? selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    Widget chip(int age) =>
        AgeChip(age: age, selected: age == selected, onTap: () => onPick(age));
    if (ages.length > 5) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [for (final a in ages) chip(a)],
      );
    }
    return Row(
      children: [
        for (final (i, a) in ages.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: chip(a)),
        ],
      ],
    );
  }
}

/// A number to pick (Figma "Button · 7"): blue with a navy lip when chosen.
/// Also on the grown-ups' edit child screen.
class AgeChip extends StatelessWidget {
  const AgeChip({
    super.key,
    required this.age,
    required this.selected,
    required this.onTap,
  });

  final int age;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 56),
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AuraColors.blue : AuraColors.white,
              borderRadius: radius,
              border: Border.all(
                color: selected ? AuraColors.navy : AuraColors.line,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected ? AuraColors.navy : AuraColors.line,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '$age',
              style: AuraText.button.copyWith(
                color: selected ? AuraColors.white : AuraColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
