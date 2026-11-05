import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../deps.dart';
import '../../../routing/paths.dart';
import 'setup_paths.dart';

/// Signed in from setup: record the "I agree" the grown-up gave on Data,
/// add the child they described, and go to Ready with the new child.
/// Throws the server's [ApiException] (403 no consent, 400 a name the dev
/// server refuses) for the screen to show; the draft stays for a retry.
Future<void> finishSetup(BuildContext context, Deps deps) async {
  final draft = deps.account.draft;
  await deps.family.giveConsent();
  final child = await deps.family.addChild(draft.toChildJson());
  // Saved on the server: a later sign-in must not add the child again.
  draft
    ..name = null
    ..age = null
    ..schoolYear = null
    ..startingPoint = null
    ..canDo = []
    ..goal = null
    ..agreed = false;
  if (context.mounted) {
    context.go(
      SetupPaths.withChild(Paths.setupReady, id: child.id, name: child.name),
    );
  }
}
