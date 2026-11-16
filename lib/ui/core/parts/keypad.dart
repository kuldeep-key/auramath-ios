import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../motion/motion.dart';
import '../theme/tokens.dart';

/// The number pad, drawn like the phone's own so it looks the same on iOS and
/// Android: 1–9, then Check (✓), 0, delete. Clears after every Check.
/// Figma: Prototype parts › Keypad.
///
/// [ours] is the child's own pad (the prototype's `.pad.ours`, LES-11,
/// D-41): white 56 pt keys with navy Black 28 digits on a blue tint, delete
/// bottom left and a blue "Check" bottom right.
class Keypad extends StatefulWidget {
  const Keypad({
    super.key,
    required this.onChanged,
    required this.onCheck,
    this.maxDigits = 4,
    this.keyHeight = 56,
    this.ours = false,
  });

  /// The child's pad, not the phone's: see the class note.
  final bool ours;

  final ValueChanged<String> onChanged;

  /// The digits as typed, so a code's leading 0 is kept; a lesson answer
  /// parses them.
  final ValueChanged<String> onCheck;
  final int maxDigits;

  /// 56 pt, the minimum for a child (LES-11); the grown-up's "Bigger number pad"
  /// setting makes the lesson's keys 64.
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
  Widget build(BuildContext context) => widget.ours ? _ours(context) : _phone();

  Widget _ours(BuildContext context) {
    final check = AppLocalizations.of(context)?.check ?? 'Check';
    Widget key(
      Widget child,
      VoidCallback onTap, {
      String? label,
      Key? key,
      bool blue = false,
    }) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: label != null,
          child: GestureDetector(
            key: key,
            onTap: onTap,
            child: PressScale(
              scale: 0.94,
              child: Container(
                height: widget.keyHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: blue ? AuraColors.blue : AuraColors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: blue ? AuraColors.blueLip : _oursShadow,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
    Widget digit(String d) =>
        key(Text(d, style: AuraText.key), () => _digit(d));
    return Container(
      color: AuraColors.blueTint,
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
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
                const Icon(
                  Icons.backspace_rounded,
                  color: AuraColors.mute,
                  size: 24,
                ),
                _delete,
                label: 'Delete',
              ),
              digit('0'),
              key(
                Text(
                  check,
                  style: AuraText.key.copyWith(
                    fontSize: 20,
                    color: AuraColors.white,
                  ),
                ),
                _check,
                label: check,
                key: const Key('keypadCheck'),
                blue: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _oursShadow = Color(0xFFC9D4F2);

  Widget _phone() {
    Widget key(
      Widget child,
      VoidCallback onTap, {
      String? label,
      bool blue = false,
      Key? id,
    }) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3.5),
        child: Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            key: id,
            onTap: onTap,
            child: PressScale(
              scale: 0.94,
              child: Container(
                height: widget.keyHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: blue ? AuraColors.blue : AuraColors.white,
                  borderRadius: BorderRadius.circular(AuraRadii.key),
                  boxShadow: const [
                    BoxShadow(
                      color: AuraColors.keyShadow,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: child,
              ),
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
                id: const Key('keypadCheck'),
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
