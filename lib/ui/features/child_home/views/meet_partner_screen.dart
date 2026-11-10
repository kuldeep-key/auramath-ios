import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/parts/speech_bubble.dart';
import '../../../core/theme/tokens.dart';

/// The first meeting (AI-07): with the grown-up there, the case partner
/// says it is a computer helper, an AI, that Julia's team wrote its rules,
/// that it can make mistakes, and that the grown-up can see the work.
// Draft: no Figma frame yet; built from the child's play screens.
class MeetPartnerScreen extends StatefulWidget {
  const MeetPartnerScreen({
    super.key,
    required this.served,
    required this.onSay,
    required this.onStart,
    this.readAloud = true,
  });

  /// The lines the content serves; empty: the bundled drafts.
  final List<String> served;

  /// Reads a line aloud in the case partner's voice.
  final ValueChanged<String> onSay;

  /// "Let's start": the scene is done for this child.
  final VoidCallback onStart;

  /// Spoken as it opens, too.
  final bool readAloud;

  @override
  State<MeetPartnerScreen> createState() => _MeetPartnerScreenState();
}

class _MeetPartnerScreenState extends State<MeetPartnerScreen> {
  late final List<String> _lines;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l = AppLocalizations.of(context)!;
    _lines = widget.served.isNotEmpty
        ? widget.served
        : [l.kidMeetLine1, l.kidMeetLine2, l.kidMeetLine3, l.kidMeetLine4];
    if (widget.readAloud) widget.onSay(_lines.join(' '));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      play: true,
      top: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          key: const Key('grownUpNote'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AuraColors.flag,
            borderRadius: BorderRadius.circular(AuraRadii.small),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.family_restroom_rounded,
                color: AuraColors.flagInk,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.kidMeetGrownUp,
                  style: AuraText.small.copyWith(color: AuraColors.flagInk),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 14,
        children: [
          const Float(child: Portrait(size: 120)),
          Semantics(
            header: true,
            child: Text(
              l.kidMeetTitle,
              textAlign: TextAlign.center,
              style: AuraText.playTitle.copyWith(color: AuraColors.white),
            ),
          ),
          for (final line in _lines) SpeechBubble(text: line),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          AuraButton(
            label: l.hearItAgain,
            icon: Icons.volume_up_rounded,
            color: AuraButtonColor.white,
            onPressed: () => widget.onSay(_lines.join(' ')),
          ),
          AuraButton(label: l.kidMeetStart, onPressed: widget.onStart),
        ],
      ),
    );
  }
}
