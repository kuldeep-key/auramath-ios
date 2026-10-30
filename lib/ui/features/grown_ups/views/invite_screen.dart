import 'package:flutter/material.dart';

import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/aura_text_field.dart';
import 'parts.dart';

/// Invite (652:251): a second grown-up by email (ACC-08). Once sent, the
/// same screen says so; Done goes back to Family.
class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key, required this.repo});

  final GrownUpRepository repo;

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context)!;
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = l.guInviteBadEmail);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repo.invite(email);
      if (mounted) setState(() => _sent = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      top: const AuraTopBar(fallback: Paths.family),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(
            title: _sent ? l.guInviteSentTitle : l.guInviteTitle,
            subtitle: _sent
                ? l.guInviteSentBody(_email.text.trim())
                : l.guInviteBody,
          ),
          if (!_sent) ...[
            const Spacer(),
            AuraTextField(
              label: l.guInviteEmail,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _send(),
              error: _error,
            ),
            const Spacer(),
          ],
        ],
      ),
      bottom: AuraButton(
        label: _sent ? l.guDone : l.guInviteSend,
        color: AuraButtonColor.blue,
        onPressed: _busy
            ? null
            : _sent
            ? () => popOr(context, Paths.family)
            : _send,
      ),
    );
  }
}
