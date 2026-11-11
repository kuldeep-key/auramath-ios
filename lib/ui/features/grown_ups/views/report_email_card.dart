import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/report_email_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/theme/tokens.dart';
import 'parts.dart';

/// Settings' report email card (PAR-05): on or off, and once on, how
/// often (PAR-06). Off to on goes through Notify (659:52), the designed
/// ask; on to off is one tap. Not designed in Figma: built as the lesson
/// settings card.
class ReportEmailCard extends StatefulWidget {
  const ReportEmailCard({super.key, required this.email});

  final ReportEmailRepository email;

  @override
  State<ReportEmailCard> createState() => _ReportEmailCardState();
}

class _ReportEmailCardState extends State<ReportEmailCard> {
  late Future<ReportFrequency?> _now = widget.email.frequency();
  bool _busy = false;
  Object? _error;

  void _reload() => setState(() => _now = widget.email.frequency());

  Future<void> _toggle(ReportFrequency? f) async {
    if (f == null || !f.on) {
      await context.push(Paths.notify);
      if (mounted) _reload();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.email.setFrequency(ReportFrequency.off);
      if (mounted) _reload();
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FutureBuilder(
      future: _now,
      builder: (context, snap) {
        final loading = snap.connectionState != ConnectionState.done;
        final f = snap.data;
        return GuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KvRow(
                label: l.guEmailRow,
                value: loading
                    ? '…'
                    : f == null
                    ? l.guEmailUnknown
                    : f.on
                    ? l.guOn
                    : l.guOff,
                hint: l.guSetChangeHint,
                divider: f != null && f.on,
                onTap: loading || _busy ? null : () => _toggle(f),
              ),
              if (!loading && f != null && f.on)
                KvRow(
                  label: l.guEmailHowOften,
                  value: f == ReportFrequency.weekly
                      ? l.guEmailWeekly
                      : l.guEmailEach,
                  divider: false,
                  onTap: _busy
                      ? null
                      : () async {
                          await context.push(Paths.emailFrequency);
                          if (mounted) _reload();
                        },
                ),
              if (snap.hasError)
                ErrorNote(snap.error!, onRetry: _reload)
              else if (_error != null)
                ErrorNote(_error!),
              if (!loading && f != null && f.on)
                Text(l.guEmailUnsubscribeNote, style: AuraText.caption),
            ],
          ),
        );
      },
    );
  }
}
