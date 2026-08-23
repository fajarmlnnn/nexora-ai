import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

class NexoraInput extends StatelessWidget {
  const NexoraInput({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.enabled = true,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final bool enabled;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          obscureText: obscureText,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w500),
          cursorColor: AppColors.brandPrimary,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            prefixIcon: prefix == null ? null : Padding(padding: const EdgeInsets.only(left: 16, right: 8), child: prefix),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            suffixIcon: suffix,
            errorText: errorText,
            helperText: errorText == null ? helperText : null,
            filled: true,
            fillColor: AppColors.space800,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: AppRadius.radiusMD, borderSide: const BorderSide(color: AppColors.borderGlass)),
            enabledBorder: OutlineInputBorder(borderRadius: AppRadius.radiusMD, borderSide: const BorderSide(color: AppColors.borderGlass)),
            focusedBorder: OutlineInputBorder(borderRadius: AppRadius.radiusMD, borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: AppRadius.radiusMD, borderSide: const BorderSide(color: AppColors.danger, width: 1)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: AppRadius.radiusMD, borderSide: const BorderSide(color: AppColors.danger, width: 1.5)),
            helperStyle: AppTypography.caption,
            errorStyle: AppTypography.caption.copyWith(color: AppColors.danger),
          ),
        ),
      ],
    );
  }
}

/// Small shared focus wrapper for custom inputs that need the same 2.0 ring.
class NexoraFocusRing extends StatelessWidget {
  const NexoraFocusRing({super.key, required this.focusNode, required this.child});
  final FocusNode focusNode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) => AnimatedContainer(
        duration: AppMotion.fast,
        padding: focusNode.hasFocus ? const EdgeInsets.all(1.5) : EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusMD,
          border: Border.all(color: focusNode.hasFocus ? AppColors.borderFocus : Colors.transparent),
        ),
        child: child,
      ),
    );
  }
}
