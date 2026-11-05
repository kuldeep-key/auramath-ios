import 'package:flutter/material.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/aura_text_field.dart';
import 'parts.dart';

/// AddChild (667:87): a first name, and the school year if the grown-up
/// wants (the backend takes any non-blank text). "I agree" records the
/// grown-up's consent first if this account has none yet.
class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key, required this.family});

  final FamilyRepository family;

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _name = TextEditingController();
  final _year = TextEditingController();
  bool _busy = false;
  String? _nameError;
  Object? _error;

  @override
  void dispose() {
    _name.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    final year = _year.text.trim();
    if (name.isEmpty) {
      setState(
        () => _nameError = AppLocalizations.of(context)!.guAddChildNameNeeded,
      );
      return;
    }
    setState(() {
      _busy = true;
      _nameError = null;
      _error = null;
    });
    try {
      await widget.family.giveConsent();
      await widget.family.addChild({
        'displayName': name,
        if (year.isNotEmpty) 'schoolYear': year,
      });
      if (mounted) popOr(context, Paths.grownUps);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      top: const AuraTopBar(fallback: Paths.grownUps),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(title: l.guAddChildTitle, subtitle: l.guAddChildBody),
          const Spacer(),
          AuraTextField(
            label: l.guAddChildName,
            controller: _name,
            capitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            error: _nameError,
          ),
          const SizedBox(height: 16),
          AuraTextField(
            label: l.guAddChildYear,
            hint: l.guAddChildYearHint,
            controller: _year,
            capitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _add(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorNote(_error!),
          ],
          const Spacer(),
        ],
      ),
      bottom: AuraButton(
        label: l.guAddChildAgree,
        color: AuraButtonColor.blue,
        onPressed: _busy ? null : _add,
      ),
    );
  }
}
