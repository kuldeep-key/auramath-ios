import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/ui/core/theme/app_theme.dart';
import 'package:auramath/ui/features/pairing/views/code_wrong_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/shots.dart';

/// GetCode's side: push CodeWrong and show what it popped with.
Widget _pushedFrom({bool tooMany = false}) => MaterialApp.router(
  theme: buildAuraTheme(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  routerConfig: GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => _Caller(tooMany: tooMany),
      ),
      GoRoute(
        path: '/wrong',
        builder: (_, _) => CodeWrongScreen(tooMany: tooMany),
      ),
    ],
  ),
);

class _Caller extends StatefulWidget {
  const _Caller({required this.tooMany});

  final bool tooMany;

  @override
  State<_Caller> createState() => _CallerState();
}

class _CallerState extends State<_Caller> {
  String result = 'none';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      onPressed: () async {
        final r = await context.push<bool>('/wrong');
        setState(() => result = 'popped $r');
      },
      child: Text(result),
    ),
  );
}

void main() {
  testWidgets('fits every size', (tester) async {
    await shotAllSizes(tester, 'pairing_code_wrong', const CodeWrongScreen());
    expect(find.text("That code didn't work"), findsOneWidget);
  });

  testWidgets('too many tries fits every size', (tester) async {
    await shotAllSizes(
      tester,
      'pairing_code_wrong_too_many',
      const CodeWrongScreen(tooMany: true),
    );
    expect(find.text('Too many tries'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  for (final (tap, popped) in [
    ('Try again', false),
    ('Grown-up: new code', true),
  ]) {
    testWidgets('$tap pops back with $popped', (tester) async {
      await tester.pumpWidget(_pushedFrom());
      await tester.tap(find.text('none'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(tap));
      await tester.pumpAndSettle();
      expect(find.text('popped $popped'), findsOneWidget);
    });
  }

  testWidgets('too many tries: OK pops back asking for a new code', (
    tester,
  ) async {
    await tester.pumpWidget(_pushedFrom(tooMany: true));
    await tester.tap(find.text('none'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('popped true'), findsOneWidget);
  });
}
