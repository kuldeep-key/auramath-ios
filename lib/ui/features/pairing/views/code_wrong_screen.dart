import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import 'play_message.dart';

/// The code was wrong, used or expired (the server doesn't say which), or
/// there were too many tries. Pops back to GetCode with `true` when the
/// child should ask for a new code. Figma: CodeWrong (653:55).
class CodeWrongScreen extends StatelessWidget {
  const CodeWrongScreen({super.key, this.tooMany = false});

  /// The server is refusing this phone for a while (its 429).
  final bool tooMany;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    void back(bool askNew) =>
        context.canPop() ? context.pop(askNew) : context.go(Paths.pair);
    return PlayMessage(
      art: const EmojiArt('🔑'),
      title: tooMany ? l.pairTooMany : l.pairCodeWrong,
      line: tooMany ? l.pairTooManyBody : l.pairCodeWrongBody,
      buttons: [
        if (tooMany)
          AuraButton(label: l.ok, onPressed: () => back(true))
        else ...[
          AuraButton(label: l.pairTryAgain, onPressed: () => back(false)),
          AuraButton(
            label: l.pairNewCode,
            color: AuraButtonColor.white,
            onPressed: () => back(true),
          ),
        ],
      ],
    );
  }
}
