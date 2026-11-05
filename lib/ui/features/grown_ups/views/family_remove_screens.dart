import 'package:flutter/material.dart';

import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_page.dart';
import 'parts.dart';

/// Are you sure? for one of the family's [T]: the item comes from the
/// server, so a deep link to one already gone says [gone]. Built as
/// RemovePhone (653:159). Confirmed, back to Family, which reloads.
class _RemoveOne<T> extends StatelessWidget {
  const _RemoveOne({
    required this.load,
    required this.find,
    required this.gone,
    required this.confirm,
  });

  final Future<List<T>> Function() load;
  final bool Function(T) find;
  final String gone;
  final ConfirmScreen Function(BuildContext context, T item) confirm;

  @override
  Widget build(BuildContext context) => Loaded<List<T>>(
    load: load,
    fallback: Paths.family,
    builder: (context, items, _) {
      final item = items.where(find).firstOrNull;
      if (item == null) {
        return AuraPage(
          top: const AuraTopBar(fallback: Paths.family),
          body: AuraHeading(title: gone),
        );
      }
      return confirm(context, item);
    },
  );
}

/// Removing an invited grown-up (no Figma frame yet). The server signs
/// their browsers out at once; it refuses (403) when this grown-up may
/// not remove them, and that reason shows here.
class RemoveGrownUpScreen extends StatelessWidget {
  const RemoveGrownUpScreen({
    super.key,
    required this.memberId,
    required this.repo,
  });

  final String memberId;
  final GrownUpRepository repo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _RemoveOne<Member>(
      load: repo.members,
      find: (m) => m.id == memberId,
      gone: l.guRemoveGrownUpGone,
      confirm: (context, m) => ConfirmScreen(
        title: l.guRemoveGrownUpTitle(m.email),
        body: l.guRemoveGrownUpBody,
        action: l.guRemoveGrownUpButton,
        fallback: Paths.family,
        onConfirm: () async {
          await repo.removeMember(memberId);
          if (context.mounted) popOr(context, Paths.family);
        },
      ),
    );
  }
}

/// Cancelling an invitation not yet accepted (no Figma frame yet).
class CancelInviteScreen extends StatelessWidget {
  const CancelInviteScreen({
    super.key,
    required this.inviteId,
    required this.repo,
  });

  final String inviteId;
  final GrownUpRepository repo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _RemoveOne<Invite>(
      load: repo.invites,
      find: (i) => i.id == inviteId,
      gone: l.guCancelInviteGone,
      confirm: (context, i) => ConfirmScreen(
        title: l.guCancelInviteTitle(i.email),
        body: l.guCancelInviteBody,
        action: l.guCancelInviteButton,
        cancel: l.guKeepInvite,
        fallback: Paths.family,
        onConfirm: () async {
          await repo.cancelInvite(inviteId);
          if (context.mounted) popOr(context, Paths.family);
        },
      ),
    );
  }
}

/// Signing out one browser a grown-up is signed in on (no Figma frame
/// yet): a lost laptop, signed out from here.
class RemoveBrowserScreen extends StatelessWidget {
  const RemoveBrowserScreen({
    super.key,
    required this.browserId,
    required this.repo,
  });

  final String browserId;
  final GrownUpRepository repo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _RemoveOne<Browser>(
      load: repo.browsers,
      // this phone signs out from Settings instead
      find: (b) => b.id == browserId && !b.you,
      gone: l.guBrowserGone,
      confirm: (context, b) => ConfirmScreen(
        title: l.guSignOutBrowserTitle(
          b.label.isEmpty ? l.guBrowserUnnamed : b.label,
        ),
        body: l.guSignOutBrowserBody,
        action: l.guSignOutBrowserButton,
        fallback: Paths.family,
        onConfirm: () async {
          await repo.removeBrowser(browserId);
          if (context.mounted) popOr(context, Paths.family);
        },
      ),
    );
  }
}
