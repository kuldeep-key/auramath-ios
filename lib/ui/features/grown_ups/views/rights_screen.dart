import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'parts.dart';

/// Rights (667:66): what is kept, the export (a job: start, poll, save),
/// and deleting the account behind its own confirmation.
class RightsScreen extends StatefulWidget {
  const RightsScreen({
    super.key,
    required this.repo,
    required this.deletePath,
    this.poll = const Duration(seconds: 2),
  });

  final GrownUpRepository repo;

  /// The delete confirmation's address.
  final String deletePath;
  final Duration poll;

  @override
  State<RightsScreen> createState() => _RightsScreenState();
}

class _RightsScreenState extends State<RightsScreen> {
  ExportJob? _job;
  String? _savedAs;
  Object? _error;
  bool _busy = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() step) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await step();
    } on ApiException catch (e) {
      _timer?.cancel();
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _tapExport() {
    final job = _job;
    if (job != null && job.status == 'ready') {
      _run(() async {
        final file = await widget.repo.saveExport(job.id);
        if (mounted) setState(() => _savedAs = file.path.split('/').last);
      });
      return;
    }
    if (job != null && !job.done) return;
    _run(() async {
      final started = await widget.repo.startExport();
      if (!mounted) return;
      setState(() {
        _job = started;
        _savedAs = null;
      });
      _timer?.cancel();
      if (!started.done) {
        _timer = Timer.periodic(widget.poll, (_) => _check(started.id));
      }
    });
  }

  Future<void> _check(String id) async {
    try {
      final job = await widget.repo.exportStatus(id);
      if (job.done) _timer?.cancel();
      if (mounted) setState(() => _job = job);
    } on ApiException catch (e) {
      _timer?.cancel();
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final job = _job;
    final exportLine = _savedAs != null
        ? l.guExportSaved(_savedAs!)
        : switch (job?.status) {
            null => l.guDownloadBody,
            'ready' => l.guExportReady,
            'failed' => l.guExportFailed,
            'expired' => l.guExportExpired,
            _ => l.guExportPending,
          };
    final stored = [l.guStored1, l.guStored2, l.guStored3, l.guStored4];
    return AuraPage(
      top: const AuraTopBar(fallback: Paths.settings),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          Semantics(
            header: true,
            child: Text(l.guRightsTitle, style: AuraText.heading),
          ),
          const SizedBox(height: 10),
          GuCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.guStoredTitle, style: AuraText.option),
                const SizedBox(height: 6),
                for (final s in stored)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('•  $s', style: AuraText.small),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: NavRow(
              icon: Icons.download_rounded,
              label: l.guDownload,
              detail: exportLine,
              chevron: false,
              onTap: _busy ? null : _tapExport,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            ErrorNote(_error!),
          ],
          const SizedBox(height: 12),
          NavRow(
            icon: Icons.delete_outline_rounded,
            iconColor: AuraColors.coral,
            label: l.guDeleteAccount,
            detail: l.guDeleteAccountBody,
            chevron: false,
            onTap: () => context.push(widget.deletePath),
          ),
        ],
      ),
    );
  }
}
