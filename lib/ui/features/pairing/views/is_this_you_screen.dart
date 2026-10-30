import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';
import 'play_message.dart';

/// The child confirms the phone is theirs. Figma: IsThisYou (644:205).
class IsThisYouScreen extends StatelessWidget {
  const IsThisYouScreen({
    super.key,
    required this.account,
    required this.childId,
    required this.name,
  });

  final AccountRepository account;
  final String childId;
  final String name;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PlayMessage(
      art: const ExcludeSemantics(child: Portrait(size: 170)),
      title: l.pairIsThisYou,
      line: name,
      lineStyle: AuraText.playName,
      buttons: [
        AuraButton(
          label: l.pairYesMe,
          onPressed: () async {
            await account.chooseChild(childId);
            if (context.mounted) {
              context.go(
                Uri(
                  path: Paths.pairJoined,
                  queryParameters: {'name': name},
                ).toString(),
              );
            }
          },
        ),
        AuraButton(
          label: l.pairNo,
          color: AuraButtonColor.white,
          onPressed: () => context.go(Paths.pairWhichChild),
        ),
      ],
    );
  }
}
