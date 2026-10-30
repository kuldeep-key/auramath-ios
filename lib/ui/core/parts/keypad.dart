import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The number pad, drawn like the phone's own so it looks the same on iOS and
/// Android: 1–9, then Check (✓), 0, delete. Clears after every Check.
/// Figma: Prototype parts › Keypad.
class Keypad extends StatefulWidget {
  const Keypad({
    super.key,
    required this.onChanged,
    required this.onCheck,
    this.maxDigits = 4,
    this.keyHeight = 48,
  });

  final ValueChanged<String> onChanged;

  /// The digits as typed, so a code's leading 0 is kept; a lesson answer
  /// parses them.
  final ValueChanged<String> onCheck;
  final int maxDigits;

  /// 48 is the phone's own look; the grown-up's "Bigger number pad"
  /// setting and child screens use more.
  final double keyHeight;

  @override
  State<Keypad> createState() => _KeypadState();
}

class _KeypadState extends State<Keypad> {
  String _typed = '';

  void _set(String v) {
    if (v == _typed) return;
    _typed = v;
    widget.onChanged(v);
  }

  void _digit(String d) {
    if (_typed.length < widget.maxDigits) _set(_typed + d);
  }

  void _delete() {
    if (_typed.isNotEmpty) _set(_typed.substring(0, _typed.length - 1));
  }

  void _check() {
    if (_typed.isEmpty) return;
    final typed = _typed;
    _set('');
    widget.onCheck(typed);
  }

  @override
  Widget build(BuildContext context) {
    Widget key(
      Widget child,
      VoidCallback onTap, {
      String? label,
      bool blue = false,
    }) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3.5),
        child: Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: widget.keyHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: blue ? AuraColors.blue : AuraColors.white,
                borderRadius: BorderRadius.circular(AuraRadii.key),
                boxShadow: const [
                  BoxShadow(color: AuraColors.keyShadow, offset: Offset(0, 1)),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
    Widget digit(String d) => key(
      Text(d, style: const TextStyle(fontSize: 26, color: AuraColors.keyText)),
      () => _digit(d),
    );
    return Container(
      color: AuraColors.keypadBg,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(children: [for (final d in row) digit(d)]),
          Row(
            children: [
              key(
                const Icon(Icons.check_rounded, color: AuraColors.white),
                _check,
                label: 'Check',
                blue: true,
              ),
              digit('0'),
              key(
                const Icon(Icons.backspace_outlined),
                _delete,
                label: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
