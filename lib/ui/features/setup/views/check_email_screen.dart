import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../deps.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import '../finish_setup.dart';
import 'setup_parts.dart';

/// CheckEmail (653:144), for setup and for sign-in. The emailed link opens
/// the app at `/auth/verify`, which signs in (or, mid-setup, hands its
/// [token] back here to finish setup). A dev server's link comes back in
/// the reply: [devToken] offers to follow it without a mailbox.
class CheckEmailScreen extends StatefulWidget {
  const CheckEmailScreen({
    super.key,
    required this.deps,
    required this.fromSetup,
    this.devToken,
    this.token,
  });

  final Deps deps;
  final bool fromSetup;
  final String? devToken;

  /// A link to follow at once.
  final String? token;

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen> {
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final token = widget.token;
    if (token != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow(token));
    }
  }

  Future<void> _done() async {
    if (widget.fromSetup) {
      await finishSetup(context, widget.deps);
    } else if (mounted) {
      context.go(Paths.kids);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _follow(String token) => _run(() async {
    await widget.deps.account.verifyEmailLink(token);
    await _done();
  });

  /// "I tapped the link": the link signs in by itself when it opens here,
  /// so either that has happened, or it hasn't opened on this phone.
  void _tapped() => _run(() async {
    if (widget.deps.account.role != Role.parent) {
      throw ApiException(AppLocalizations.of(context)!.setupLinkNotYet);
    }
    await _done();
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final name = childName(context, widget.deps.account.draft.name);
    return AuraPage(
      top: AuraTopBar(
        fallback: widget.fromSetup ? Paths.setupSave : Paths.signIn,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(title: l.setupCheckTitle, subtitle: l.setupCheckBody),
          const SizedBox(height: 22),
          const IconTile(
            icon: Icons.mark_email_unread_outlined,
            color: AuraColors.yellowInk,
            background: AuraColors.yellowTint,
          ),
          const SizedBox(height: 16),
          if (_busy)
            Row(
              children: [
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.fromSetup
                        ? sentence(l.setupSaving(name))
                        : l.setupVerifying,
                    style: AuraText.body,
                  ),
                ),
              ],
            ),
          if (_error != null) ErrorNote(_error!),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.devToken != null) ...[
            AuraButton(
              label: l.setupDevLink,
              color: AuraButtonColor.white,
              onPressed: _busy ? null : () => _follow(widget.devToken!),
            ),
            const SizedBox(height: 12),
          ],
          AuraButton(
            label: l.setupTappedLink,
            color: AuraButtonColor.blue,
            onPressed: _busy ? null : _tapped,
          ),
        ],
      ),
    );
  }
}
