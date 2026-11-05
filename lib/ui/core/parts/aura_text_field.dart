import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The rounded input box. Figma draws it empty; the label stays visible
/// above it so the field is never unnamed (WCAG 3.3.2).
class AuraTextField extends StatelessWidget {
  const AuraTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.autofocus = false,
    this.capitalization = TextCapitalization.none,
    this.error,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final TextCapitalization capitalization;

  /// Shown under the field, with an icon, never only as a colour.
  final String? error;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AuraRadii.button),
      borderSide: BorderSide(color: c, width: 2),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AuraText.caption),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          textCapitalization: capitalization,
          onSubmitted: onSubmitted,
          autofocus: autofocus,
          autocorrect: false,
          style: AuraText.option,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AuraText.body.copyWith(color: AuraColors.tickOff),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            enabledBorder: border(AuraColors.line),
            focusedBorder: border(AuraColors.blue),
            errorBorder: border(AuraColors.coral),
            focusedErrorBorder: border(AuraColors.coral),
            errorText: error,
            errorStyle: AuraText.small,
            errorMaxLines: 3,
            prefixIconConstraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }
}
