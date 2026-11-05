import 'package:flutter/material.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/setup_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/aura_text_field.dart';
import '../../../core/parts/choice_tile.dart';
import '../../setup/views/age_screen.dart' show AgeChip, setupAges;
import '../../setup/views/year_screen.dart'
    show setupYears, yearLabel, yearValue;
import 'parts.dart';

/// The server's longest display name (parent.py).
const maxChildName = 40;

/// A child's details (ACC-14; no Figma frame yet): first name, age and
/// school year, from the lists setup uses (`/api/setup/options`). Only
/// what changed is sent. The server checks the name (and, before legal
/// review, that it's a made-up one) and says why it refuses.
class EditChildScreen extends StatelessWidget {
  const EditChildScreen({
    super.key,
    required this.childId,
    required this.family,
    required this.setup,
  });

  final String childId;
  final FamilyRepository family;
  final SetupRepository setup;

  @override
  Widget build(BuildContext context) => Loaded<(Child, SetupOptions)>(
    load: () => withChild(family, childId, setup.options),
    fallback: Paths.learning(childId),
    builder: (context, data, _) =>
        _EditChild(child: data.$1, options: data.$2, family: family),
  );
}

class _EditChild extends StatefulWidget {
  const _EditChild({
    required this.child,
    required this.options,
    required this.family,
  });

  final Child child;
  final SetupOptions options;
  final FamilyRepository family;

  @override
  State<_EditChild> createState() => _EditChildState();
}

class _EditChildState extends State<_EditChild> {
  late final _name = TextEditingController(text: widget.child.name);
  late int? _age = widget.child.age;
  late String? _year = widget.child.schoolYear;
  bool _busy = false;
  String? _nameError;
  Object? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final child = widget.child;
    final back = Paths.learning(child.id);
    final name = _name.text.trim();
    final nameError = name.isEmpty
        ? l.guEditNameNeeded
        : name.length > maxChildName
        ? l.guEditNameLong
        : null;
    if (nameError != null) {
      setState(() => _nameError = nameError);
      return;
    }
    final changes = <String, Object?>{
      if (name != child.name) 'displayName': name,
      if (_age != child.age) 'age': _age,
      if (_year != child.schoolYear) 'schoolYear': _year,
    };
    if (changes.isEmpty) {
      popOr(context, back);
      return;
    }
    setState(() {
      _busy = true;
      _nameError = null;
      _error = null;
    });
    try {
      await widget.family.editChild(child.id, changes);
      if (mounted) popOr(context, back);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final ages = widget.options.ages.isEmpty ? setupAges : widget.options.ages;
    final years = inServerOrder(
      [
        for (final y in setupYears)
          (id: yearValue(y), label: yearLabel(l, yearValue(y))),
      ],
      (o) => o.id,
      widget.options.schoolYears,
      (s) => s,
    );
    return AuraPage(
      top: AuraTopBar(fallback: Paths.learning(widget.child.id)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(
            title: l.guEditTitle(widget.child.name),
            subtitle: l.guEditBody,
          ),
          AuraTextField(
            label: l.guEditName,
            controller: _name,
            capitalization: TextCapitalization.words,
            error: _nameError,
          ),
          // most refusals are about the name; said where it was typed
          if (_error != null) ...[
            const SizedBox(height: 8),
            ErrorNote(_error!),
          ],
          SectionLabel(l.guEditAge),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final age in ages)
                AgeChip(
                  age: age,
                  selected: age == _age,
                  onTap: () => setState(() => _age = age),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SectionLabel(l.guEditYear),
          for (final (:id, :label) in years) ...[
            ChoiceTile(
              label: label,
              selected: _year == id,
              onTap: () => setState(() => _year = id),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
      bottom: AuraButton(
        label: l.guEditSave,
        color: AuraButtonColor.blue,
        onPressed: _busy ? null : _save,
      ),
    );
  }
}
