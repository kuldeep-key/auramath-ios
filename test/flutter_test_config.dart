import 'dart:async';

import 'package:auramath/ui/core/motion/motion.dart';

/// Runs before every test file: looping motion (a bobbing piece, the
/// turning rays) never settles, so tests hold it still.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Loop.still = true;
  await testMain();
}
