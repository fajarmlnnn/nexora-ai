import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

class NexoraCurrencyField extends StatefulWidget {
  const NexoraCurrencyField({super.key, required this.controller, this.label = 'Jumlah', this.helperText, this.errorText, this.semanticColor = NexoraCurrencySemantic.neutral, this.enabled = true});

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final String? errorText;
  final NexoraCurrencySemantic semanticColor;
  final bool enabled;

  @override
  State<NexoraCurrencyField> createState() => _NexoraCurrencyFieldState();
}

enum NexoraCurrencySemantic { neutral, income, expense, transfer }

class _NexoraCurrencyFieldState extends State<NexoraCurrencyField> {
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocus);
  bool _focused = false;

  void _onFocus() => setState(() => _focused = _focusNode.hasFocus);

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (widget.semanticColor) {
      NexoraCurrencySemantic.income => AppColors.success,
      NexoraCurrencySemantic.expense => AppColors.danger,
      NexoraCurrencySemantic.transfer => AppColors.info,
      NexoraCurrencySemantic.neutral => AppColors.brandPrimary,
    };
    final border = widget.errorText != null ? AppColors.danger.withValues(alpha: .6) : _focused ? AppColors.borderFocus : color.withValues(alpha: .2);

    return Semantics(
      label: 'Jumlah, rupiah',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: AppRadius.radiusXL,
          border: Border.all(color: border, width: _focused ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.label, style: AppTypography.moneyLabel),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Rp', style: AppTypography.secondaryAmount.copyWith(color: AppColors.textMuted)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    style: AppTypography.heroAmount,
                    cursorColor: AppColors.brandPrimary,
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    inputFormatters: [
                      _RupiahInputFormatter(),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.errorText != null || widget.helperText != null) ...[
              const SizedBox(height: 8),
              Text(widget.errorText ?? widget.helperText!, style: AppTypography.caption.copyWith(color: widget.errorText != null ? AppColors.danger : AppColors.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RupiahInputFormatter extends TextInputFormatter {
  final _formatter = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final formatted = _formatter.format(int.parse(digits));
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}
