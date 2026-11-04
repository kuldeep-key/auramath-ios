import 'dart:async';

import 'package:auramath/ui/core/motion/motion.dart';

/// Runs before every test file: motion rests, so screens settle (a bobbing
/// piece never would) and words read whole at once.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AuraMotion.still = true;
  await testMain();
}
