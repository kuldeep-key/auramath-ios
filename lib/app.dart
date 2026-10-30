import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'deps.dart';
import 'l10n/app_localizations.dart';
import 'routing/paths.dart';
import 'routing/router.dart';
import 'ui/core/theme/app_theme.dart';

class AuraApp extends StatefulWidget {
  const AuraApp({super.key, required this.deps, this.initialLocation});

  final Deps deps;

  /// For tests: start somewhere other than `/`.
  final String? initialLocation;

  @override
  State<AuraApp> createState() => _AuraAppState();
}

class _AuraAppState extends State<AuraApp> {
  late final GoRouter _router = buildRouter(
    widget.deps,
    initialLocation: widget.initialLocation,
  );

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back in the foreground: send anything the outbox is still holding.
    _lifecycle = AppLifecycleListener(onResume: widget.deps.sessions.syncNow);
    _router.routerDelegate.addListener(_lockOnLeave);
  }

  /// Leaving the grown-up area locks it again (ACC-07).
  void _lockOnLeave() {
    final loc = _router.routerDelegate.currentConfiguration.uri.path;
    if (!Paths.isGrownUp(loc)) widget.deps.account.lockGrownUps();
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_lockOnLeave);
    _lifecycle.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Auramath',
    theme: buildAuraTheme(),
    routerConfig: _router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    debugShowCheckedModeBanner: false,
    // Large text is honoured up to 1.3×; past that the child's screens stop
    // fitting. Every screen still scrolls rather than clips.
    builder: (context, child) =>
        MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: child!),
  );
}
