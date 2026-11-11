import 'package:flutter/material.dart';

import '../../../../data/repositories/report_email_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/choice_tile.dart';
import 'parts.dart';

/// How often the report email goes (PAR-06): after each session, once a
/// week, or off. A tap saves at once and goes back. Not designed in Figma:
/// built as the setup choices.
class EmailFrequencyScreen extends StatefulWidget {
  const EmailFrequencyScreen({super.key, required this.email});

  final ReportEmailRepository email;

  @override
  State<EmailFrequencyScreen> createState() => _EmailFrequencyScreenState();
}

class _EmailFrequencyScreenState extends State<EmailFrequencyScreen> {
  ReportFrequency? _picked;
  bool _busy = false;
  Object? _error;

  Future<void> _pick(ReportFrequency f) async {
    setState(() {
      _picked = f;
      _busy = true;
      _error = null;
    });
    try {
      await widget.email.setFrequency(f);
      if (mounted) popOr(context, Paths.settings);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Loaded<ReportFrequency?>(
      load: widget.email.frequency,
      fallback: Paths.settings,
      builder: (context, now, _) {
        final shown = _picked ?? now;
        Widget tile(ReportFrequency f, String label, String detail) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ChoiceTile(
            label: label,
            detail: detail,
            selected: shown == f,
            onTap: _busy ? () {} : () => _pick(f),
          ),
        );
        return AuraPage(
          top: const AuraTopBar(fallback: Paths.settings),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuraHeading(title: l.guEmailHowOftenTitle),
              tile(ReportFrequency.each, l.guEmailEach, l.guEmailEachDetail),
              tile(
                ReportFrequency.weekly,
                l.guEmailWeekly,
                l.guEmailWeeklyDetail,
              ),
              tile(ReportFrequency.off, l.guEmailOff, l.guEmailOffDetail),
              if (_error != null) ErrorNote(_error!),
            ],
          ),
        );
      },
    );
  }
}
