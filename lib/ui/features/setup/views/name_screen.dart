import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/aura_text_field.dart';
import 'setup_parts.dart';

/// Name (643:24): the child's first name, kept in the draft.
class NameScreen extends StatefulWidget {
  const NameScreen({super.key, required this.draft});

  final SetupDraft draft;

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  late final _name = TextEditingController(text: widget.draft.name)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _continue() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    widget.draft.name = name;
    context.push(Paths.setupAge);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      top: setupTopBar(SetupStep.name),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(title: l.setupNameTitle, subtitle: l.setupNameSubtitle),
          // Figma centres the field; under the title it stays in view when
          // the keyboard is up.
          AuraTextField(
            label: l.setupNameLabel,
            controller: _name,
            autofocus: true,
            capitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.givenName],
            onSubmitted: (_) => _continue(),
          ),
        ],
      ),
      bottom: AuraButton(
        label: l.setupContinue,
        color: AuraButtonColor.blue,
        onPressed: _name.text.trim().isEmpty ? null : _continue,
      ),
    );
  }
}
