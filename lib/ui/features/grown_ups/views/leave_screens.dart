import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../data/repositories/session_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/aura_text_field.dart';
import '../../../core/parts/aura_toast.dart';
import '../../../core/theme/tokens.dart';
import 'parts.dart';

/// SignOut (659:105). A paired child phone stays paired, but no child's
/// lessons stay on the phone (DEV-06): unsent work is sent first, and while
/// it can't be, the grown-up stays signed in and is told why. Saved
/// exports and cached clips go too.
class SignOutScreen extends StatelessWidget {
  const SignOutScreen({
    super.key,
    required this.account,
    required this.repo,
    required this.sessions,
  });

  final AccountRepository account;
  final GrownUpRepository repo;
  final SessionRepository sessions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ConfirmScreen(
      title: l.guSignOutTitle,
      body: l.guSignOutBody,
      action: l.guSignOut,
      fallback: Paths.grownUps,
      onConfirm: () async {
        await sessions.sendAllThenForget();
        await repo.forgetSavedData();
        await account.chooseChild(null);
        await account.signOut();
        if (!context.mounted) return;
        AuraToast.show(context, l.guSignedOut);
        // the prototype's sign-out fades to Open
        context.go(Paths.open);
      },
    );
  }
}

/// Deleting the family account (ACC-09, D-42; Apple requires it in the
/// app), as the prototype's three steps: DeleteWhat says exactly what goes,
/// DeleteConfirm asks for DELETE typed, Deleted says it is done. The
/// server call happens on DeleteConfirm; this phone signs out on Close.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({
    super.key,
    required this.account,
    required this.repo,
    required this.sessions,
  });

  final AccountRepository account;
  final GrownUpRepository repo;
  final SessionRepository sessions;

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

enum _Step { what, confirm, deleted }

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  _Step _step = _Step.what;
  final _typed = TextEditingController();
  bool _busy = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _typed.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repo.erase();
      // the chosen child and their lessons went with the family
      await widget.sessions.forget();
      await widget.repo.forgetSavedData();
      if (mounted) setState(() => _step = _Step.deleted);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close() async {
    await widget.account.chooseChild(null);
    await widget.account.signOut();
    if (mounted) context.go(Paths.open);
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    // the prototype's Deleted fades in (`t:'fade'`); the other steps push
    duration: calmMotion(context) ? Duration.zero : AuraDurations.screen,
    switchInCurve: AuraCurves.screen,
    child: KeyedSubtree(
      key: ValueKey(_step),
      child: switch (_step) {
        _Step.what => _what(context),
        _Step.confirm => _confirm(context),
        _Step.deleted => _deleted(context),
      },
    ),
  );

  Widget _what(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      top: const AuraTopBar(fallback: Paths.rights),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(title: l.guDeleteTitle, subtitle: l.guDeleteBody),
          GuCard(
            child: Column(
              children: [
                for (final (icon, title, body) in [
                  (
                    Icons.group_rounded,
                    l.guDeleteChildren,
                    l.guDeleteChildrenBody,
                  ),
                  (
                    Icons.history_rounded,
                    l.guDeleteSessions,
                    l.guDeleteSessionsBody,
                  ),
                  (Icons.mail_rounded, l.guDeleteNotes, l.guDeleteNotesBody),
                  (
                    Icons.smartphone_rounded,
                    l.guDeletePhones,
                    l.guDeletePhonesBody,
                  ),
                ])
                  _CoralRow(icon: icon, title: title, body: body),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(l.guDeleteNow, style: AuraText.subtitle.copyWith(fontSize: 15)),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraButton(
            label: l.guDeleteDownloadFirst,
            color: AuraButtonColor.white,
            onPressed: () => popOr(context, Paths.rights),
          ),
          const SizedBox(height: 12),
          AuraButton(
            label: l.guDeleteButton,
            color: AuraButtonColor.coral,
            onPressed: () => setState(() => _step = _Step.confirm),
          ),
        ],
      ),
    );
  }

  Widget _confirm(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final ready =
        _typed.text.trim().toUpperCase() == l.guDeleteConfirmWord && !_busy;
    return AuraPage(
      top: AuraTopBar(onBack: () => setState(() => _step = _Step.what)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(
            title: l.guDeleteConfirmTitle,
            subtitle: l.guDeleteConfirmBody,
          ),
          AuraTextField(
            label: l.guDeleteConfirmLabel,
            controller: _typed,
            capitalization: TextCapitalization.characters,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            ErrorNote(_error!),
          ],
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraButton(
            label: l.guDeleteConfirmButton,
            color: AuraButtonColor.coral,
            onPressed: ready ? _delete : null,
          ),
          const SizedBox(height: 12),
          AuraLink(
            label: l.guDeleteKeep,
            onPressed: _busy ? null : () => context.go(Paths.grownUps),
          ),
        ],
      ),
    );
  }

  Widget _deleted(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      child: AuraPage(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 96,
              color: AuraColors.green,
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(l.guDeletedTitle, style: AuraText.heading),
            ),
            const SizedBox(height: 16),
            Text(
              l.guDeletedBody,
              textAlign: TextAlign.center,
              style: AuraText.subtitle,
            ),
            const SizedBox(height: 28),
            AuraButton(
              label: l.guClose,
              color: AuraButtonColor.blue,
              onPressed: _close,
            ),
          ],
        ),
      ),
    );
  }
}

/// A "Li" row with a coral-tinted icon tile (DeleteWhat).
class _CoralRow extends StatelessWidget {
  const _CoralRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE2D9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: const Color(0xFF9A3A1F)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AuraText.infoTitle),
              Text(body, style: AuraText.optionDetail),
            ],
          ),
        ),
      ],
    ),
  );
}
