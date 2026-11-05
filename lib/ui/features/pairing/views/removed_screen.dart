import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import 'play_message.dart';

/// On the child's phone after a grown-up removed it. Not designed in Figma:
/// the play style, with Removed 653:172's wording for the child.
class RemovedScreen extends StatelessWidget {
  const RemovedScreen({super.key, required this.account});

  final AccountRepository account;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PlayMessage(
      art: const EmojiArt('📱'),
      title: l.pairRemoved,
      line: l.pairRemovedBody,
      buttons: [
        AuraButton(
          label: l.ok,
          onPressed: () async {
            await account.forgetPhone();
            if (context.mounted) context.go(Paths.open);
          },
        ),
      ],
    );
  }
}
