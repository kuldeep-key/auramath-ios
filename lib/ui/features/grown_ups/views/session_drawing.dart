import 'package:flutter/material.dart';

import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';

/// PAR-09: the child's board from a lesson, its key move ringed, the
/// picture the report email carries, under the lesson's note; its caption
/// says what it shows (and is what a screen reader reads). Nothing while
/// it loads, when nothing was placed, or when it can't be fetched: the
/// note stands on its own.
class SessionDrawingView extends StatefulWidget {
  const SessionDrawingView({super.key, required this.load});

  final Future<SessionDrawing?> Function() load;

  @override
  State<SessionDrawingView> createState() => _SessionDrawingViewState();
}

class _SessionDrawingViewState extends State<SessionDrawingView> {
  late final Future<SessionDrawing?> _drawing = widget.load().catchError((
    Object e,
  ) {
    debugPrint('drawing not fetched: $e');
    return null;
  });

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _drawing,
    builder: (context, snap) {
      final d = snap.data;
      if (d == null) return const SizedBox.shrink();
      final caption = d.caption;
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AuraRadii.small),
              child: Image.memory(
                d.png,
                key: const Key('sessionDrawing'),
                fit: BoxFit.contain,
                semanticLabel:
                    caption ?? AppLocalizations.of(context)!.guDrawingLabel,
              ),
            ),
            if (caption != null)
              ExcludeSemantics(
                child: Text(
                  caption,
                  style: AuraText.caption.copyWith(color: AuraColors.mute),
                ),
              ),
          ],
        ),
      );
    },
  );
}
