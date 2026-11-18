import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/problem_report_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/aura_text_field.dart';
import '../../../core/parts/choice_tile.dart';
import '../../../core/theme/tokens.dart';
import 'parts.dart';

/// What the report screen offers: the last sessions' problems, and the
/// family's children to name them by.
typedef _Choices = ({List<ReportChoice> choices, Map<String, String> names});

/// Report a problem (PAR-13, Figma 1046:7734 Report and 1046:7814
/// ReportSent): a parent or carer picks one of the last sessions' problems
/// (by the child, the day and the story, never an id) or "Something else",
/// adds an optional note that asks for no names, and sends it into Key's
/// weekly review. Once sent, the same screen says thank you.
class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({
    super.key,
    required this.reports,
    required this.family,
    this.storyOf,
  });

  final ProblemReportRepository reports;
  final FamilyRepository family;

  /// The story of a problem this phone has drawn ("Tree and Lamp"); null
  /// when it hasn't.
  final String? Function(String problemId)? storyOf;

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _note = TextEditingController();

  /// The case picked; [_somethingElse] when it's "Something else".
  ReportChoice? _picked;
  bool _somethingElse = false;
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<_Choices> _load() async {
    final kids = await widget.family.children();
    return (
      choices: await widget.reports.choices(),
      names: {for (final c in kids) c.id: c.name},
    );
  }

  bool get _ready => _picked != null || _somethingElse;

  Future<void> _send() async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.reports.send(
        about: _somethingElse ? null : _picked,
        note: _note.text,
      );
      if (mounted) setState(() => _sent = true);
    } on ApiException catch (e) {
      if (!mounted) return;
      // what was picked and written stays, to send again
      setState(
        () => _error = switch (e.status) {
          null => l.reportOffline,
          429 => l.reportTooMany,
          404 => l.reportGone,
          _ => l.reportNotSent,
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      _sent ? const ReportSentView() : _form(context);

  Widget _form(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return Loaded<_Choices>(
      load: _load,
      fallback: Paths.settings,
      builder: (context, data, _) => AuraPage(
        top: const AuraTopBar(fallback: Paths.settings),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuraHeading(title: l.reportTitle, subtitle: l.reportIntro),
            PartLabel(l.reportAbout, top: 4),
            if (data.choices.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(l.reportNoCases, style: AuraText.cardLine),
              ),
            for (final c in data.choices) ...[
              ChoiceTile(
                key: ValueKey('case-${c.sessionId}-${c.problemId}'),
                label: widget.storyOf?.call(c.problemId) ?? l.reportCaseLabel,
                detail: l.reportCaseWhen(
                  data.names[c.childId] ?? '',
                  DateFormat.MMMEd(locale).add_jm().format(c.shownAt),
                ),
                selected: !_somethingElse && identical(_picked, c),
                onTap: () => setState(() {
                  _picked = c;
                  _somethingElse = false;
                  _error = null;
                }),
              ),
              const SizedBox(height: 12),
            ],
            ChoiceTile(
              key: const ValueKey('something-else'),
              label: l.reportSomethingElse,
              detail: l.reportSomethingElseDetail,
              selected: _somethingElse,
              onTap: () => setState(() {
                _somethingElse = true;
                _picked = null;
                _error = null;
              }),
            ),
            PartLabel(l.reportWhatHappened),
            AuraTextField(
              label: l.reportNoteLabel,
              hint: l.reportNoteHint,
              controller: _note,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              capitalization: TextCapitalization.sentences,
              maxLines: 6,
              maxLength: ProblemReportRepository.noteMax,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: AuraColors.mute,
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(l.reportNoNames, style: AuraText.small)),
              ],
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(error, style: AuraText.body)),
                  ],
                ),
              ),
            ],
          ],
        ),
        bottom: AuraButton(
          label: l.reportSend,
          color: AuraButtonColor.blue,
          onPressed: _busy || !_ready ? null : _send,
        ),
      ),
    );
  }
}

/// ReportSent (Figma 1046:7814): thank you, Key will look at it, and back
/// to the Family area.
class ReportSentView extends StatelessWidget {
  const ReportSentView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      top: const AuraTopBar(fallback: Paths.grownUps),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(title: l.reportThanksTitle, subtitle: l.reportThanksBody),
          StateCard(
            ok: true,
            art: const Icon(
              Icons.check_circle_rounded,
              size: 48,
              color: AuraColors.green,
            ),
            title: l.reportSentTitle,
            body: l.reportSentBody,
          ),
        ],
      ),
      bottom: AuraButton(
        label: l.reportBackToFamily,
        color: AuraButtonColor.blue,
        onPressed: () => context.go(Paths.grownUps),
      ),
    );
  }
}
