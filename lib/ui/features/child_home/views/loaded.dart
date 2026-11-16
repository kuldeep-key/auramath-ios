import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/ribbon.dart';
import 'play_moment.dart';

/// Shows [builder]'s screen once [load] finishes, the blue background
/// meanwhile. A failed read is the prototype's ErrChild (16 Nov): the
/// detective, "That didn't work", "Let's have another go.", and Have
/// another go and Go home. Nothing red and no error words (NFR-03).
class Loaded<T> extends StatefulWidget {
  const Loaded({super.key, required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(T value) builder;

  @override
  State<Loaded<T>> createState() => _LoadedState<T>();
}

class _LoadedState<T> extends State<Loaded<T>> {
  late Future<T> _future = _read();

  /// The read; its failure is shown, never left uncaught (the screen may
  /// not be listening yet when it fails).
  Future<T> _read() => widget.load()..ignore();

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future,
    builder: (context, snap) {
      if (snap.hasError) {
        return ChildError(
          // a block, not an arrow: setState must not return the Future
          onRetry: () => setState(() {
            _future = _read();
          }),
        );
      }
      if (snap.connectionState != ConnectionState.done) {
        return const AuraPage(play: true, body: SizedBox());
      }
      return widget.builder(snap.data as T);
    },
  );
}

/// Something failed on the child's side (the prototype's ErrChild): one
/// warm line, a retry, and the way home (not on Home itself).
class ChildError extends StatelessWidget {
  const ChildError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final router = GoRouter.maybeOf(context);
    final atHome =
        router == null ||
        router.routerDelegate.currentConfiguration.uri.path == Paths.home;
    return PlayMoment(
      gap: 16,
      content: [
        const Portrait(size: 120),
        Ribbon(text: l.kidErrTitle),
        PlayLine(l.kidErrLine),
      ],
      bottom: ButtonStack([
        AuraButton(
          key: const Key('errRetry'),
          label: l.kidErrRetry,
          onPressed: onRetry,
        ),
        if (!atHome)
          AuraButton(
            key: const Key('errHome'),
            label: l.kidGoHome,
            color: AuraButtonColor.white,
            onPressed: () => context.go(Paths.home),
          ),
      ]),
    );
  }
}
