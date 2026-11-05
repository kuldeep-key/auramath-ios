import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'setup_parts.dart';

/// The ages offered (Figma 643:40 and Welcome's "ages 5 to 10"); the
/// server takes 4 to 12.
const setupAges = [5, 6, 7, 8, 9, 10];

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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final age in setupAges)
                _AgeChip(
                  age: age,
                  selected: age == _age,
                  onTap: () => setState(() => _age = age),
                ),
            ],
          ),
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

/// A number to pick (Figma "Button · 7"): blue with a navy lip when chosen.
class _AgeChip extends StatelessWidget {
  const _AgeChip({
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
            width: 64,
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
