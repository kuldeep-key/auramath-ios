import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/choice_tile.dart';
import '../../../core/parts/ribbon.dart';
import 'play_message.dart';

/// A newly paired phone asks which of the family's children it's for.
/// Figma: WhichChild · Whose phone is it? (653:115).
class WhichChildScreen extends StatefulWidget {
  const WhichChildScreen({super.key, required this.family});

  final FamilyRepository family;

  @override
  State<WhichChildScreen> createState() => _WhichChildScreenState();
}

class _WhichChildScreenState extends State<WhichChildScreen> {
  late Future<List<Child>> _children = widget.family.children();

  void _reload() => setState(() {
    _children = widget.family.children();
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      top: const AuraTopBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(title: l.pairWhichChild),
          FutureBuilder(
            future: _children,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return LoadError(
                  message: failureText(l, snap.error!),
                  retryLabel: l.pairTryAgain,
                  onRetry: _reload,
                );
              }
              final children = snap.data!;
              if (children.isEmpty) {
                return LoadError(
                  message: l.pairNoChildren,
                  retryLabel: l.pairTryAgain,
                  onRetry: _reload,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final c in children)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ChoiceTile(
                        label: c.name,
                        selected: false,
                        leading: const ExcludeSemantics(
                          child: Portrait(size: 48),
                        ),
                        onTap: () => context.push(
                          Uri(
                            path: Paths.pairIsThisYou,
                            queryParameters: {'id': c.id, 'name': c.name},
                          ).toString(),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
