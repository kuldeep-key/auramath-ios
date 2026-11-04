import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/choice_tile.dart';
import 'setup_parts.dart';

/// NSW school years, Kindergarten to Year 5: the usual year for ages 5 to
/// 10 (Year = age − 5). Sent as the ids of `/api/setup/options`.
const setupYears = [0, 1, 2, 3, 4, 5];

String yearValue(int year) => year == 0 ? 'kindergarten' : 'year_$year';

/// The year's label; a value that isn't one of the ids (a child added
/// before the ids) reads as it was stored.
String yearLabel(AppLocalizations l, String value) => switch (value) {
  'kindergarten' => l.setupKindergarten,
  _ when value.startsWith('year_') => l.setupYearN(
    int.parse(value.substring(5)),
  ),
  _ => value,
};

/// The year id for what a grown-up typed ("Year 2", "2", "Kindy"), or null
/// when it isn't Kindergarten to Year 5.
String? yearIdFrom(String typed) {
  final t = typed.trim().toLowerCase();
  if (t.startsWith('k')) return 'kindergarten';
  final n = int.tryParse(t.replaceFirst(RegExp(r'^(year|yr)\s*'), ''));
  return n != null && n > 0 && setupYears.contains(n) ? yearValue(n) : null;
}

/// Year (643:66). The usual year for the child's age is flagged and
/// chosen to start with.
class YearScreen extends StatefulWidget {
  const YearScreen({super.key, required this.draft});

  final SetupDraft draft;

  @override
  State<YearScreen> createState() => _YearScreenState();
}

class _YearScreenState extends State<YearScreen> {
  late final int? _usual = widget.draft.age == null
      ? null
      : (widget.draft.age! - 5).clamp(0, setupYears.last);
  late String? _year =
      widget.draft.schoolYear ?? (_usual == null ? null : yearValue(_usual));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      top: setupTopBar(SetupStep.year),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(
            title: sentence(
              l.setupYearTitle(childName(context, widget.draft.name)),
            ),
          ),
          for (final y in setupYears) ...[
            ChoiceTile(
              label: yearLabel(l, yearValue(y)),
              flag: y == _usual ? l.setupYearUsual(widget.draft.age!) : null,
              selected: _year == yearValue(y),
              onTap: () => setState(() => _year = yearValue(y)),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
      bottom: AuraButton(
        label: l.setupContinue,
        color: AuraButtonColor.blue,
        onPressed: _year == null
            ? null
            : () {
                widget.draft.schoolYear = _year;
                context.push(Paths.setupStart);
              },
      ),
    );
  }
}
