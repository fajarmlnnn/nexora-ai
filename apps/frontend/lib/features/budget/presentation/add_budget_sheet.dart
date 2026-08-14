import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../dashboard/models/budget_item.dart';
import '../../dashboard/models/transaction_model.dart';
import '../controllers/budget_controller.dart';

Future<void> showAddBudgetSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    builder: (_) => const _AddBudgetSheet(),
  );
}

class _AddBudgetSheet extends ConsumerStatefulWidget {
  const _AddBudgetSheet();

  @override
  ConsumerState<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<_AddBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  TransactionCategory _category = TransactionCategory.food;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  double? _parseAmount(String value) {
    return double.tryParse(value.replaceAll('.', '').replaceAll(',', '').trim());
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final limit = _parseAmount(_limitController.text);
    if (limit == null || limit <= 0) {
      _showError('Batas budget harus lebih dari 0.');
      return;
    }

    final existing = ref.read(budgetItemsProvider).valueOrNull ?? const <BudgetItem>[];
    if (existing.any((item) => item.category == _category)) {
      _showError('Budget untuk kategori ini sudah ada.');
      return;
    }

    final name = _nameController.text.trim().isEmpty
        ? _categoryLabel(_category)
        : _nameController.text.trim();

    setState(() => _saving = true);
    final budget = BudgetItem(
      // Identity is intentionally independent from the financial category.
      id: 'budget-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      category: _category,
      spent: 0,
      limit: limit,
      color: budgetColorForCategory(_category.name),
    );

    final saved = await ref.read(budgetItemsProvider.notifier).addBudget(budget);
    if (!mounted) return;
    if (!saved) {
      setState(() => _saving = false);
      _showError('Budget gagal disimpan. Coba lagi.');
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${budget.name} berhasil ditambahkan.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _categoryLabel(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food:
        return 'Makan';
      case TransactionCategory.transport:
        return 'Transportasi';
      case TransactionCategory.shopping:
        return 'Belanja';
      case TransactionCategory.bills:
        return 'Tagihan';
      case TransactionCategory.entertainment:
        return 'Hiburan';
      case TransactionCategory.health:
        return 'Kesehatan';
      case TransactionCategory.education:
        return 'Pendidikan';
      case TransactionCategory.other:
        return 'Lainnya';
      case TransactionCategory.salary:
      case TransactionCategory.investment:
        return category.name;
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
    final categories = const [
      TransactionCategory.food,
      TransactionCategory.transport,
      TransactionCategory.shopping,
      TransactionCategory.bills,
      TransactionCategory.entertainment,
      TransactionCategory.health,
      TransactionCategory.education,
      TransactionCategory.other,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.radiusPill,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Tambah Budget', style: AppTypography.heading2),
              const SizedBox(height: 3),
              Text(
                'Tentukan batas pengeluaran bulanan untuk kategori tertentu.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 18),
              _Field(
                controller: _nameController,
                label: 'Nama budget',
                hint: 'Contoh: Makan',
                icon: LucideIcons.walletMinimal,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TransactionCategory>(
                initialValue: _category,
                decoration: _decoration('Kategori transaksi', LucideIcons.layers3),
                dropdownColor: AppColors.card,
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(_categoryLabel(category)),
                      ),
                    )
                    .toList(),
                onChanged: _saving ? null : (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _limitController,
                label: 'Batas budget per bulan',
                hint: 'Contoh: 1000000',
                icon: LucideIcons.flag,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                validator: (value) {
                  final amount = _parseAmount(value ?? '');
                  return amount == null || amount <= 0 ? 'Nominal harus lebih dari 0.' : null;
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: AppRadius.radiusLG,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(LucideIcons.plus),
                    label: Text(_saving ? 'Menyimpan...' : 'Simpan Budget'),
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
      border: OutlineInputBorder(
        borderRadius: AppRadius.radiusLG,
        borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusLG,
        borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusLG,
        borderSide: const BorderSide(color: AppColors.primaryLight),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType,
  });

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
        border: OutlineInputBorder(
          borderRadius: AppRadius.radiusLG,
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusLG,
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusLG,
          borderSide: const BorderSide(color: AppColors.primaryLight),
        ),
      ),
    );
  }
}
