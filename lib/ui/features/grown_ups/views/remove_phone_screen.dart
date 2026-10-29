import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'parts.dart';

/// RemovePhone (653:159): are you sure? The phone's name comes from the
/// server, so a deep link to a phone already gone says so.
class RemovePhoneScreen extends StatelessWidget {
  const RemovePhoneScreen({
    super.key,
    required this.deviceId,
    required this.repo,
  });

  final String deviceId;
  final GrownUpRepository repo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Loaded<List<Device>>(
      load: repo.devices,
      fallback: Paths.family,
      builder: (context, devices, _) {
        final device = devices.where((d) => d.id == deviceId).firstOrNull;
        if (device == null) {
          return AuraPage(
            top: const AuraTopBar(fallback: Paths.family),
            body: AuraHeading(title: l.guRemoveGone),
          );
        }
        return ConfirmScreen(
          title: l.guRemoveTitle(device.label),
          body: l.guRemoveBody,
          action: l.guRemoveButton,
          fallback: Paths.family,
          onConfirm: () async {
            await repo.removeDevice(device.id);
            if (context.mounted) context.go(Paths.phoneRemoved);
          },
        );
      },
    );
  }
}

/// Removed (653:172), the grown-up's side: the phone is signed out.
class PhoneRemovedScreen extends StatelessWidget {
  const PhoneRemovedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      top: const AuraTopBar(fallback: Paths.family),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(title: l.guRemovedTitle, subtitle: l.guRemovedBody),
          const SizedBox(height: 22),
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 96,
            color: AuraColors.green,
          ),
        ],
      ),
      bottom: AuraButton(
        label: l.guDone,
        color: AuraButtonColor.blue,
        onPressed: () => context.go(Paths.family),
      ),
    );
  }
}
