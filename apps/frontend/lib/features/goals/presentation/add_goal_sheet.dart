import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../dashboard/controllers/financial_overview_controller.dart';

Future<void> showAddGoalSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    builder: (_) => const _AddGoalSheet(),
  );
}

class _AddGoalSheet extends ConsumerStatefulWidget {
  const _AddGoalSheet();

  @override
  ConsumerState<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<_AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController(text: '0');
  final _savedController = TextEditingController(text: '0');

  String _type = 'Saving';
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  double? _parseAmount(String value) {
    return double.tryParse(value.replaceAll('.', '').replaceAll(',', ''));
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final target = _parseAmount(_targetController.text);
    final saved = _parseAmount(_savedController.text);
    if (target == null || target <= 0 || saved == null || saved < 0) {
      _showError('Nominal goal tidak valid.');
      return;
    }
    if (saved > target) {
      _showError('Saldo awal tidak boleh lebih besar dari target.');
      return;
    }

    setState(() => _saving = true);

    final id = 'goal_${DateTime.now().microsecondsSinceEpoch}';
    final goal = FinancialGoalSnapshot(
      id: id,
      title: _titleController.text.trim(),
      type: _type,
      saved: saved,
      target: target,
      icon: _iconForType(_type),
    );

    try {
      await ref.read(financialGoalsProvider.notifier).addGoal(goal);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('Goal gagal disimpan. Coba lagi.');
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${goal.title} berhasil ditambahkan.'), behavior: SnackBarBehavior.floating),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Wishlist':
        return LucideIcons.shoppingBag;
      case 'Debt':
        return LucideIcons.creditCard;
      default:
        return LucideIcons.target;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: AppRadius.radiusPill)),
              ),
              const SizedBox(height: 18),
              Text('Tambah Goal', style: AppTypography.heading2),
              const SizedBox(height: 3),
              Text('Tentukan target dan pantau progresnya dari halaman Goals.', style: AppTypography.bodySmall),
              const SizedBox(height: 18),
              _Field(
                controller: _titleController,
                label: 'Nama goal',
                hint: 'Contoh: Dana Darurat',
                icon: LucideIcons.target,
                validator: (value) => value == null || value.trim().isEmpty ? 'Nama goal wajib diisi.' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: _decoration('Tipe goal', LucideIcons.layers3),
                dropdownColor: AppColors.card,
                items: const [
                  DropdownMenuItem(value: 'Saving', child: Text('Saving')),
                  DropdownMenuItem(value: 'Wishlist', child: Text('Wishlist')),
                  DropdownMenuItem(value: 'Debt', child: Text('Debt')),
                ],
                onChanged: _saving ? null : (value) => setState(() => _type = value ?? 'Saving'),
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _targetController,
                label: 'Target nominal',
                hint: 'Contoh: 10000000',
                icon: LucideIcons.flag,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                validator: (value) {
                  final amount = _parseAmount(value ?? '');
                  return amount == null || amount <= 0 ? 'Target harus lebih dari 0.' : null;
                },
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _savedController,
                label: 'Sudah tersimpan',
                hint: '0',
                icon: LucideIcons.walletCards,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                validator: (value) {
                  final amount = _parseAmount(value ?? '');
                  return amount == null || amount < 0 ? 'Nominal tidak valid.' : null;
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: AppRadius.radiusLG),
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.plus),
                    label: Text(_saving ? 'Menyimpan...' : 'Simpan Goal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.bottomNav(context)),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5))),
      enabledBorder: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5))),
      focusedBorder: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: const BorderSide(color: AppColors.primaryLight)),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, required this.hint, required this.icon, this.validator, this.keyboardType});

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: AppTypography.bodySmall.copyWith(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 19),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5))),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5))),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: const BorderSide(color: AppColors.primaryLight)),
      ),
    );
  }
}
