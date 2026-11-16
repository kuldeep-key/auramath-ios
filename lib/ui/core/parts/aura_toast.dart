import 'dart:async';

import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/tokens.dart';

/// The prototype's `toast()`: a navy note that drops in at the top
/// ("Saved", "Passcode set", "Sent again"), stays, then slides back up.
///
/// - in: from 140 % above its place, 400 ms, the sheet curve (`toastIn`);
/// - out: [hold] after it was shown, to 150 % above, 300 ms, linear;
/// - calm motion: it appears and goes without moving.
///
/// It sits on the root overlay, so it stays while the screen under it
/// changes. A newer toast replaces an older one.
abstract final class AuraToast {
  static const inDuration = Duration(milliseconds: 400);
  static const outDuration = Duration(milliseconds: 300);
  static const hold = Duration(milliseconds: 2600);

  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String message, {
    IconData? icon = Icons.check_circle_rounded,
    Duration hold = AuraToast.hold,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _current?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Toast(
        message: message,
        icon: icon,
        hold: hold,
        onGone: () {
          if (_current == entry) _current = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  /// Takes the toast away now (tests, a screen that must start clean).
  static void clear() {
    final entry = _current;
    _current = null;
    if (entry != null && entry.mounted) entry.remove();
  }

  /// How far above its place the toast is at [elapsed] since it was shown,
  /// as a share of its own height: 1.4 at the start, 0 once in, 1.5 gone.
  static double liftAt(Duration elapsed, {Duration hold = AuraToast.hold}) {
    final ms = elapsed.inMicroseconds / 1000;
    final inMs = inDuration.inMilliseconds;
    final holdMs = hold.inMilliseconds;
    if (ms < inMs) return 1.4 * (1 - AuraCurves.sheet.transform(ms / inMs));
    if (ms < holdMs) return 0;
    final out = ((ms - holdMs) / outDuration.inMilliseconds).clamp(0.0, 1.0);
    return 1.5 * out;
  }
}

/// ExtraBold 17, white (`.toast`).
final _style = AuraText.body.copyWith(
  color: AuraColors.white,
  fontWeight: FontWeight.w800,
  fontVariations: const [FontVariation('wght', 800)],
);

class _Toast extends StatefulWidget {
  const _Toast({
    required this.message,
    required this.icon,
    required this.hold,
    required this.onGone,
  });

  final String message;
  final IconData? icon;
  final Duration hold;
  final VoidCallback onGone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: widget.hold + AuraToast.outDuration,
  );
  Timer? _still;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted || _still != null) return;
    if (calmMotion(context)) {
      _c.value = AuraToast.inDuration.inMicroseconds / _total;
      _still = Timer(widget.hold, widget.onGone);
    } else {
      _c.forward().whenComplete(() {
        if (mounted) widget.onGone();
      });
    }
  }

  int get _total => _c.duration!.inMicroseconds;

  @override
  void dispose() {
    _still?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 10;
    return Positioned(
      left: 16,
      right: 16,
      top: top,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 528),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) => FractionalTranslation(
              translation: Offset(
                0,
                calmMotion(context)
                    ? 0
                    : -AuraToast.liftAt(
                        Duration(microseconds: (_c.value * _total).round()),
                        hold: widget.hold,
                      ),
              ),
              child: child,
            ),
            child: Semantics(
              liveRegion: true,
              container: true,
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  key: const Key('auraToast'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AuraColors.navy,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        offset: Offset(0, 10),
                        blurRadius: 24,
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: AuraColors.white, size: 24),
                        const SizedBox(width: 10),
                      ],
                      Expanded(child: Text(widget.message, style: _style)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
