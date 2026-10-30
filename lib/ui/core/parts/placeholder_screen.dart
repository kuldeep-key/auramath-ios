import 'package:flutter/material.dart';

import 'aura_page.dart';

/// Holds a route's place until its screen is built. No route should still
/// use it at release; `test/routing/router_test.dart` lists any that do.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) => AuraPage(
    top: const AuraTopBar(fallback: '/'),
    body: Center(child: Text(name)),
  );
}
