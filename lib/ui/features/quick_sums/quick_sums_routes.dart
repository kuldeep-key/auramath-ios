import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/account_repository.dart';
import '../../../deps.dart';
import '../../../routing/paths.dart';
import 'view_models/quick_sums_view_model.dart';
import 'views/quick_sums_screen.dart';

/// Quick sums (LES-16), behind the flag `quick_sums`. `?ms=` is the time
/// the child spent on Choose today before picking it (LES-14).
List<RouteBase> quickSumsRoutes(Deps deps) => [
  GoRoute(
    path: Paths.quickSums,
    redirect: (_, _) => deps.flags.on('quick_sums') ? null : Paths.home,
    builder: (context, state) => _QuickSumsRoute(
      key: ValueKey(state.uri.toString()),
      deps: deps,
      chosenMs: int.tryParse(state.uri.queryParameters['ms'] ?? ''),
    ),
  ),
];

class _QuickSumsRoute extends StatefulWidget {
  const _QuickSumsRoute({super.key, required this.deps, this.chosenMs});

  final Deps deps;
  final int? chosenMs;

  @override
  State<_QuickSumsRoute> createState() => _QuickSumsRouteState();
}

class _QuickSumsRouteState extends State<_QuickSumsRoute> {
  late final _vm = QuickSumsViewModel(
    sessions: widget.deps.sessions,
    childId: widget.deps.account.childId,
    launchSource: widget.deps.account.role == Role.parent
        ? 'parent_handover'
        : 'child_opened',
    chosenToday: widget.chosenMs == null
        ? null
        : (optionId: 'quick_sums', ms: widget.chosenMs!),
  );

  @override
  void initState() {
    super.initState();
    _vm.start();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => QuickSumsScreen(
    vm: _vm,
    onSay: widget.deps.voice.say,
    onHome: () => context.go(Paths.home),
    onStory: () => context.go(Paths.lessonNext),
  );
}
