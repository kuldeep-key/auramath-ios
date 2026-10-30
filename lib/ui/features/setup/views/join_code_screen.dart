import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/setup_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/code_boxes.dart';
import '../../../core/theme/tokens.dart';
import 'setup_parts.dart';

/// JoinCode (644:75): a one-time code for the child's own phone. Watches
/// the family's phones and moves on when a new one joins.
class JoinCodeScreen extends StatefulWidget {
  const JoinCodeScreen({
    super.key,
    required this.repo,
    required this.name,
    this.now = DateTime.now,
    this.pollEvery = const Duration(seconds: 3),
  });

  final SetupRepository repo;
  final String name;
  final DateTime Function() now;
  final Duration pollEvery;

  @override
  State<JoinCodeScreen> createState() => _JoinCodeScreenState();
}

class _JoinCodeScreenState extends State<JoinCodeScreen> {
  ({String code, DateTime expiresAt})? _code;
  Set<String>? _known;
  String? _error;
  String? _pollError;
  bool _loading = false;
  bool _polling = false;
  late final Timer _tick;
  late final Timer _poll;

  @override
  void initState() {
    super.initState();
    _newCode();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    _poll = Timer.periodic(widget.pollEvery, (_) => _checkJoined());
  }

  @override
  void dispose() {
    _tick.cancel();
    _poll.cancel();
    super.dispose();
  }

  Future<void> _newCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // the phones before this code, so a new one stands out
      _known ??= await widget.repo.deviceIds();
      final code = await widget.repo.newPairingCode();
      if (mounted) setState(() => _code = code);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkJoined() async {
    final known = _known;
    if (known == null || _polling) return;
    _polling = true;
    try {
      final ids = await widget.repo.deviceIds();
      if (!mounted) return;
      if (ids.difference(known).isNotEmpty) {
        context.go(Paths.kids);
      } else if (_pollError != null) {
        setState(() => _pollError = null);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _pollError = e.message);
    } finally {
      _polling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final code = _code;
    final left = code?.expiresAt.difference(widget.now());
    final expired = left != null && left <= Duration.zero;
    return AuraPage(
      top: const AuraTopBar(fallback: Paths.kids),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(
            title: l.setupJoinTitle(widget.name),
            subtitle: l.setupJoinBody(widget.name),
          ),
          const SizedBox(height: 16),
          if (code == null && _loading)
            const Center(child: CircularProgressIndicator())
          else if (code != null) ...[
            Opacity(
              opacity: expired ? 0.4 : 1,
              child: SizedBox(
                height: codeBoxesHeight,
                child: CodeBoxes(length: code.code.length, value: code.code),
              ),
            ),
            const SizedBox(height: 14),
            if (expired)
              Text(
                l.setupCodeExpired,
                textAlign: TextAlign.center,
                style: AuraText.subtitle,
              )
            else
              _WorksFor(left: left!),
          ],
          if (_error != null) ErrorNote(_error!),
          if (_pollError != null) ErrorNote(_pollError!),
          const SizedBox(height: 16),
          InfoCard(
            rows: [
              (
                Icons.sync_rounded,
                l.setupProgressFollows(widget.name),
                l.setupProgressFollowsDetail,
              ),
            ],
          ),
        ],
      ),
      bottom: AuraButton(
        label: _error != null && code == null
            ? l.setupTryAgain
            : l.setupNewCode,
        color: AuraButtonColor.white,
        onPressed: _loading ? null : _newCode,
      ),
    );
  }
}

/// "Works once, for 9:59", the time in bold.
class _WorksFor extends StatelessWidget {
  const _WorksFor({required this.left});

  final Duration left;

  @override
  Widget build(BuildContext context) {
    final s = left.inSeconds;
    final time = '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    final text = AppLocalizations.of(context)!.setupWorksOnce(time);
    final at = text.indexOf(time);
    return Text.rich(
      TextSpan(
        style: AuraText.subtitle,
        children: [
          TextSpan(text: text.substring(0, at)),
          TextSpan(text: time, style: AuraText.subtitleBold),
          TextSpan(text: text.substring(at + time.length)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
