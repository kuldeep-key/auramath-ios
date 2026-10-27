import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/repositories/session_repository.dart';
import 'data/services/voice.dart';
import 'l10n/app_localizations.dart';
import 'routing.dart';
import 'ui/core/theme/app_theme.dart';

class AuraApp extends StatefulWidget {
  const AuraApp({
    super.key,
    required this.sessions,
    required this.pack,
    required this.voice,
  });

  final SessionRepository sessions;
  final Pack pack;
  final Voice voice;

  @override
  State<AuraApp> createState() => _AuraAppState();
}

class _AuraAppState extends State<AuraApp> {
  late final GoRouter _router = buildRouter(
    sessions: widget.sessions,
    pack: widget.pack,
    voice: widget.voice,
  );

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back in the foreground: send anything the outbox is still holding.
    _lifecycle = AppLifecycleListener(onResume: widget.sessions.syncNow);
  }

  @override
  void dispose() {
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
  );
}
