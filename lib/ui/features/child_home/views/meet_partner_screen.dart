import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/ribbon.dart';
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
    this.figure,
  });

  /// The child's tutor (TTR-01); the detective portrait without one.
  final Widget? figure;

  /// The lines the content serves; empty: the bundled drafts.
  final List<String> served;

  /// Reads a line aloud in the case partner's voice: [tapped] when the
  /// child asked ("Hear it again"), else as the screen opens.
  final void Function(String text, {required bool tapped}) onSay;

  /// "Let's start": the scene is done for this child.
  final VoidCallback onStart;

  /// Spoken as it opens, too.
  final bool readAloud;

  @override
  State<MeetPartnerScreen> createState() => _MeetPartnerScreenState();
}

class _MeetPartnerScreenState extends State<MeetPartnerScreen> {
  List<String> _lines = const [];
  bool _said = false;

  /// Runs again whenever something the screen reads changes (the voice,
  /// the text size): the lines are read each time, and said only once.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l = AppLocalizations.of(context)!;
    _lines = widget.served.isNotEmpty
        ? widget.served
        : [l.kidMeetLine1, l.kidMeetLine2, l.kidMeetLine3, l.kidMeetLine4];
    if (widget.readAloud && !_said) {
      _said = true;
      widget.onSay(_lines.join(' '), tapped: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      play: true,
      // the prototype's Meet: a white pill saying the family is here, the
      // tutor talking, the ribbon, and the lines as one paragraph
      top: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Center(
          child: Container(
            key: const Key('grownUpNote'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AuraColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                const Icon(
                  Icons.family_restroom_rounded,
                  size: 18,
                  color: AuraColors.navy,
                ),
                Flexible(
                  child: Text(
                    l.kidMeetGrownUp,
                    style: AuraText.small.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AuraColors.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          widget.figure ?? const Float(child: Portrait(size: 120)),
          Semantics(header: true, child: Ribbon(text: l.kidMeetTitle)),
          // the prototype's 300 pt measure (padding, not a max width: the
          // page measures the body's height through it)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _lines.join(' '),
              textAlign: TextAlign.center,
              style: AuraText.play.copyWith(fontSize: 20, height: 1.3),
            ),
          ),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          AuraButton(
            label: l.hearItAgain,
            leading: const Icon(
              Icons.volume_up_rounded,
              size: 26,
              color: AuraColors.navy,
            ),
            color: AuraButtonColor.white,
            onPressed: () => widget.onSay(_lines.join(' '), tapped: true),
          ),
          AuraButton(label: l.kidMeetStart, onPressed: widget.onStart),
        ],
      ),
    );
  }
}
