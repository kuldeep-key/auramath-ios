import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/recent_notes_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'parts.dart';

/// A child's last five session notes (PAR-12), the same words the report
/// email carries, newest first. Shown only while `recent_notes_in_app` is
/// on. Not designed in Figma: built as the Book's session cards.
class RecentNotesScreen extends StatelessWidget {
  const RecentNotesScreen({
    super.key,
    required this.childId,
    required this.family,
    required this.notes,
  });

  final String childId;
  final FamilyRepository family;
  final RecentNotesRepository notes;

  @override
  Widget build(BuildContext context) => Loaded<(Child, List<SessionNote>)>(
    load: () => withChild(family, childId, () => notes.recent(childId)),
    fallback: Paths.grownUps,
    builder: (context, data, _) {
      final (child, list) = data;
      final l = AppLocalizations.of(context)!;
      final locale = Localizations.localeOf(context).toString();
      return AuraPage(
        top: TitleBar(
          title: l.guNotesTitle(child.name),
          fallback: Paths.grownUps,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (list.isEmpty)
              GuCard(
                child: Text(
                  l.guNotesNone(child.name),
                  style: AuraText.note.copyWith(color: AuraColors.mute),
                ),
              ),
            for (final n in list) ...[
              GuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (n.at != null) ...[
                      Text(
                        DateFormat.MMMEd(locale).format(n.at!),
                        style: AuraText.option,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(n.sentences.join(' '), style: AuraText.note),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      );
    },
  );
}
