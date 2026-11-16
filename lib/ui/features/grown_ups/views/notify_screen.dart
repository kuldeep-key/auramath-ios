import 'package:flutter/material.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import '../../setup/views/setup_parts.dart' show ConsentCheck;
import 'parts.dart';

/// Notify (659:52, the prototype's Notify): the report EMAIL after each
/// session (PAR-01/06), not a push notification; there is no push
/// service. Continue with the tick on turns it on; with the tick off it
/// changes nothing.
class NotifyScreen extends StatefulWidget {
  const NotifyScreen({super.key, required this.family, required this.repo});

  final FamilyRepository family;
  final GrownUpRepository repo;

  @override
  State<NotifyScreen> createState() => _NotifyScreenState();
}

class _NotifyScreenState extends State<NotifyScreen> {
  bool _busy = false;
  Object? _error;

  /// "Email me after each session", ticked to begin with.
  bool _on = true;

  Future<void> _yes() async {
    if (!_on) {
      popOr(context, Paths.grownUps);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repo.setReportFrequency('each');
      if (mounted) popOr(context, Paths.grownUps);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Loaded<List<Child>>(
      load: widget.family.children,
      fallback: Paths.grownUps,
      builder: (context, children, _) => AuraPage(
        top: const AuraTopBar(fallback: Paths.grownUps),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuraHeading(title: l.guNotifyTitle, subtitle: l.guNotifyBody),
            const SizedBox(height: 8),
            GuCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AuraColors.yellowTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.mail_rounded,
                      size: 22,
                      color: AuraColors.yellowInk,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.guNotifyCard, style: AuraText.infoTitle),
                        Text(
                          l.guNotifyCardBody(childName(context, children)),
                          style: AuraText.optionDetail,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ConsentCheck(
              value: _on,
              label: l.guNotifyCheck,
              onChanged: (v) => setState(() => _on = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              ErrorNote(_error!),
            ],
          ],
        ),
        bottom: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuraButton(
              label: l.guNotifyYes,
              color: AuraButtonColor.blue,
              onPressed: _busy ? null : _yes,
            ),
          ],
        ),
      ),
    );
  }
}
