import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import 'play_moment.dart';

/// Shows [builder]'s screen once [load] finishes, the blue background
/// meanwhile. A failed read says what went wrong, with Try again.
class Loaded<T> extends StatefulWidget {
  const Loaded({super.key, required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(T value) builder;

  @override
  State<Loaded<T>> createState() => _LoadedState<T>();
}

class _LoadedState<T> extends State<Loaded<T>> {
  late Future<T> _future = widget.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future,
    builder: (context, snap) {
      if (snap.hasError) {
        return PlayMoment(
          content: [PlayLine('${snap.error}')],
          bottom: AuraButton(
            label: AppLocalizations.of(context)!.kidTryAgain,
            color: AuraButtonColor.white,
            onPressed: () => setState(() => _future = widget.load()),
          ),
        );
      }
      if (snap.connectionState != ConnectionState.done) {
        return const AuraPage(play: true, body: SizedBox());
      }
      return widget.builder(snap.data as T);
    },
  );
}
