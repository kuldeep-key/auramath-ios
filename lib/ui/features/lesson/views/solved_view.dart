import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';
import '../../child_home/views/badge_disc.dart' show badgeArt;
import '../view_models/lesson_view_model.dart';

/// Case cracked, then the one badge that says what the child did.
/// Figma: Y2, Y3.
class SolvedView extends StatefulWidget {
  const SolvedView({super.key, required this.vm, required this.onFinished});

  final LessonViewModel vm;
  final ValueChanged<String> onFinished;

  @override
  State<SolvedView> createState() => _SolvedViewState();
}

class _SolvedViewState extends State<SolvedView> {
  bool _showBadge = false;

  // ponytail: badge art by id until packs carry badge pictures.
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final badge = widget.vm.badge;
    final white = AuraText.title.copyWith(color: AuraColors.white);
    return Container(
      width: double.infinity,
      decoration: auraPlayBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Spacer(),
              if (!_showBadge) ...[
                Ribbon(text: l.caseCracked),
                const SizedBox(height: 24),
                const Portrait(size: 200),
                const SizedBox(height: 24),
                Text(l.youSolvedIt, style: white, textAlign: TextAlign.center),
              ] else ...[
                Ribbon(text: l.newBadge),
                const SizedBox(height: 24),
                Container(
                  width: 190,
                  height: 190,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AuraColors.blueTint,
                    boxShadow: [
                      BoxShadow(
                        color: AuraColors.blueLip,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    badgeArt(widget.vm.badgeId ?? ''),
                    style: const TextStyle(fontSize: 88),
                  ),
                ),
                const SizedBox(height: 24),
                Text(badge?.name ?? '', style: white),
                const SizedBox(height: 8),
                Text(
                  badge?.says ?? '',
                  style: AuraText.body.copyWith(color: AuraColors.white),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              AuraButton(
                label: _showBadge ? l.addToSash : l.next,
                onPressed: () => _showBadge
                    ? widget.onFinished(widget.vm.nextProblemId!)
                    : setState(() => _showBadge = true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
