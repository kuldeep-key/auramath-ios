import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../data/repositories/setup_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/choice_tile.dart';
import '../../../core/theme/tokens.dart';
import 'setup_parts.dart';

/// Figma's "can already do" areas, in school order, and the id each one
/// sends (`/api/setup/options` `canDo`; the server maps them to skills).
List<(String, String)> canDoOptions(AppLocalizations l) => [
  (l.setupCanCount100, 'counting_to_100'),
  (l.setupCanAdd100, 'adding_to_100'),
  (l.setupCanSub100, 'taking_away_to_100'),
  (l.setupCanAdd1000, 'adding_to_1000'),
  (l.setupCanSub1000, 'taking_away_to_1000'),
  (l.setupCanWordProblems, 'word_problems_with_bars'),
];

/// Start (643:102): pick everything that feels easy, or "I'm not sure".
class StartScreen extends StatefulWidget {
  const StartScreen({super.key, required this.draft});

  final SetupDraft draft;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late final _picked = {...widget.draft.canDo};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final draft = widget.draft;
    return AuraPage(
      top: setupTopBar(SetupStep.start),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(
            title: sentence(l.setupStartTitle(childName(context, draft.name))),
            subtitle: l.setupStartSubtitle,
          ),
          for (final (label, id) in inServerOrder(
            canDoOptions(l),
            (o) => o.$2,
            draft.options?.canDo,
            (s) => (s.label, s.id),
          )) ...[
            ChoiceTile(
              label: label,
              selected: _picked.contains(id),
              onTap: () => setState(
                () =>
                    _picked.contains(id) ? _picked.remove(id) : _picked.add(id),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _NotSureTile(
            name: childName(context, draft.name),
            onTap: () {
              draft
                ..startingPoint = 'not_sure'
                ..canDo = ['not_sure'];
              context.push(Paths.setupNotSure);
            },
          ),
        ],
      ),
      bottom: AuraButton(
        label: l.setupContinue,
        color: AuraButtonColor.blue,
        onPressed: _picked.isEmpty
            ? null
            : () {
                draft
                  ..startingPoint = 'chosen'
                  ..canDo = [..._picked];
                context.push(Paths.setupGoal);
              },
      ),
    );
  }
}

/// "I'm not sure · We'll start from Aarav's age": a way on, not a choice,
/// so it has a help icon, no tick, and a dashed edge (`border-style:
/// dashed`).
class _NotSureTile extends StatelessWidget {
  const _NotSureTile({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final radius = BorderRadius.circular(AuraRadii.button);
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: CustomPaint(
            painter: const _DashedEdge(radius: AuraRadii.button),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.help_rounded, color: AuraColors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.setupNotSure, style: AuraText.option),
                        Text(
                          l.setupNotSureFromAge(name),
                          style: AuraText.optionDetail,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A 2 pt dashed line edge with a 4 pt lip under it, as the other options.
class _DashedEdge extends CustomPainter {
  const _DashedEdge({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = AuraColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(r.shift(const Offset(0, 4)), paint..strokeWidth = 2);
    canvas.drawRRect(r, Paint()..color = AuraColors.white);
    final path = Path()..addRRect(r);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedEdge old) => old.radius != radius;
}
