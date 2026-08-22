import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/supabase_goals_controller.dart';

Future<void> showAddGoalSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .68),
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    clipBehavior: Clip.antiAlias,
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
  final _title = TextEditingController();
  final _target = TextEditingController(text: '0');
  final _saved = TextEditingController(text: '0');

  String _type = 'Saving';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _saved.dispose();
    super.dispose();
  }

  double? _parse(String value) => double.tryParse(
        value.replaceAll('.', '').replaceAll(',', ''),
      );

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final target = _parse(_target.text);
    final saved = _parse(_saved.text);
    if (target == null || target <= 0 || saved == null || saved < 0 || saved > target) {
      _error('Nominal goal tidak valid.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(financialGoalsProvider.notifier).addGoal(
            FinancialGoalSnapshot(
              id: '',
              title: _title.text.trim(),
              type: _type,
              saved: saved,
              target: target,
              icon: _icon(_type),
            ),
          );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_title.text.trim()} berhasil ditambahkan.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _error('Goal gagal disimpan: $e');
    }
  }

  IconData _icon(String type) => switch (type) {
        'Wishlist' => LucideIcons.shoppingBag,
        'Debt' => LucideIcons.creditCard,
        _ => LucideIcons.target,
      };

  void _error(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E0B24), Color(0xFF08071A)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Color(0x332C214A))),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: .30),
                      borderRadius: AppRadius.radiusPill,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text('Tambah Goal', style: AppTypography.heading1.copyWith(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Simpan target di Supabase agar tetap ada setelah refresh atau restart.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 22),
                _Field(
                  controller: _title,
                  label: 'Nama goal',
                  hint: 'Contoh: Dana Darurat',
                  icon: LucideIcons.target,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nama goal wajib diisi.' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: _decoration('Tipe goal', LucideIcons.layers3),
                  dropdownColor: AppColors.space800,
                  borderRadius: AppRadius.radiusLG,
                  items: const [
                    DropdownMenuItem(value: 'Saving', child: Text('Saving')),
                    DropdownMenuItem(value: 'Wishlist', child: Text('Wishlist')),
                    DropdownMenuItem(value: 'Debt', child: Text('Debt')),
                  ],
                  onChanged: _saving ? null : (value) => setState(() => _type = value ?? 'Saving'),
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _target,
                  label: 'Target nominal',
                  hint: '1000000',
                  icon: LucideIcons.flag,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final amount = _parse(v ?? '');
                    return amount == null || amount <= 0 ? 'Target harus lebih dari 0.' : null;
                  },
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _saved,
                  label: 'Sudah tersimpan',
                  hint: '0',
                  icon: LucideIcons.walletCards,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final amount = _parse(v ?? '');
                    return amount == null || amount < 0 ? 'Nominal tidak valid.' : null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppGradients.aurora,
                      borderRadius: AppRadius.radiusXL,
                      boxShadow: [
                        BoxShadow(color: AppColors.brandPrimary.withValues(alpha: .30), blurRadius: 26, offset: const Offset(0, 12)),
                      ],
                    ),
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
                        minimumSize: const Size.fromHeight(58),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.bottomNav(context)),
              ],
            ),
          ),
        ),
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
      style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}
