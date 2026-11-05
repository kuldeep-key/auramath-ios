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
/// 10 (Year = age − 5). The server stores the text as given (≤ 20 chars).
const setupYears = [0, 1, 2, 3, 4, 5];

String yearValue(int year) => year == 0 ? 'Kindergarten' : 'Year $year';

String yearLabel(AppLocalizations l, String value) => value == 'Kindergarten'
    ? l.setupKindergarten
    : l.setupYearN(int.parse(value.substring(5)));

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
