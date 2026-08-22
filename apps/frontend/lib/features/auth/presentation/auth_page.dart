import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_auth_repository.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.redirect});
  final String? redirect;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repository = SupabaseAuthRepository();

  bool _registerMode = false;
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _loading = true);
    try {
      final response = _registerMode
          ? await _repository.register(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
            )
          : await _repository.login(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      if (!mounted) return;
      if (response.session == null) {
        _showMessage('Akun dibuat. Cek email untuk verifikasi sebelum login.');
        setState(() => _registerMode = false);
        return;
      }
      context.go(_safeRedirect);
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message, error: true);
    } catch (_) {
      if (mounted) _showMessage('Terjadi kesalahan. Coba lagi.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _safeRedirect {
    final value = widget.redirect;
    return value != null && value.startsWith('/') && !value.startsWith('//') ? value : '/';
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: error ? AppColors.danger : AppColors.primary));
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) return const _SupabaseConfigurationPage();
    final isRegister = _registerMode;

    return PremiumScaffold(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(alignment: Alignment.centerLeft, child: _BrandMark()),
                    const SizedBox(height: 30),
                    Center(child: NexoraRobot(size: isRegister ? 112 : 126)),
                    const SizedBox(height: 22),
                    Text(isRegister ? 'Create your Nexora' : 'Welcome back', textAlign: TextAlign.center, style: AppTypography.heading1.copyWith(fontSize: 30, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      isRegister ? 'Bangun kebiasaan finansial yang lebih cerdas bersama Nexora.' : 'Ruang finansial personalmu, sekarang lebih cerdas.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.45),
                    ),
                    const SizedBox(height: 28),
                    if (isRegister) ...[
                      _field(controller: _nameController, label: 'Nama', icon: Icons.person_outline),
                      AppSpacing.gapMD,
                    ],
                    _field(controller: _emailController, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (value) {
                      final email = value?.trim() ?? '';
                      return email.isEmpty || !email.contains('@') ? 'Masukkan email yang valid' : null;
                    }),
                    AppSpacing.gapMD,
                    _field(controller: _passwordController, label: 'Password', icon: Icons.lock_outline, obscureText: _obscurePassword, suffix: IconButton(onPressed: () => setState(() => _obscurePassword = !_obscurePassword), icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined)), validator: (value) => (value ?? '').length < 6 ? 'Password minimal 6 karakter' : null),
                    const SizedBox(height: 20),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1), Color(0xFF22D3EE)]),
                        borderRadius: AppRadius.radiusXL,
                        boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: .24), blurRadius: 24, offset: const Offset(0, 10))],
                      ),
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL)),
                        child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isRegister ? 'Create account' : 'Sign in', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(onPressed: _loading ? null : () => setState(() => _registerMode = !_registerMode), child: Text(isRegister ? 'Sudah punya akun? Sign in' : 'Belum punya akun? Create account')),
                    const SizedBox(height: 18),
                    Row(children: [Expanded(child: Divider(color: AppColors.border.withValues(alpha: .7))), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('SECURE BY DESIGN', style: AppTypography.caption.copyWith(letterSpacing: 1.2, color: AppColors.textMuted, fontWeight: FontWeight.w700))), Expanded(child: Divider(color: AppColors.border.withValues(alpha: .7)))]),
                    const SizedBox(height: 14),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shield_outlined, size: 16, color: AppColors.success), const SizedBox(width: 7), Flexible(child: Text('Data finansialmu dilindungi dengan Supabase Auth + Row Level Security.', textAlign: TextAlign.center, style: AppTypography.caption.copyWith(color: AppColors.textMuted, height: 1.35)))]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType, bool obscureText = false, Widget? suffix, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator ?? (value) => (value?.trim().isEmpty ?? true) ? '$label wajib diisi' : null,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), suffixIcon: suffix, filled: true, fillColor: AppColors.surface.withValues(alpha: .78), border: OutlineInputBorder(borderRadius: AppRadius.radiusXL, borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5))), enabledBorder: OutlineInputBorder(borderRadius: AppRadius.radiusXL, borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5))), focusedBorder: OutlineInputBorder(borderRadius: AppRadius.radiusXL, borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17)),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 36, height: 36, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)])), child: const Center(child: Text('N', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),), const SizedBox(width: 10), Text('NEXORA', style: AppTypography.labelLarge.copyWith(letterSpacing: 2.4, fontWeight: FontWeight.w900))]);
}

class _SupabaseConfigurationPage extends StatelessWidget {
  const _SupabaseConfigurationPage();
  @override
  Widget build(BuildContext context) => PremiumScaffold(child: Center(child: Padding(padding: AppSpacing.screen, child: Text('Supabase belum dikonfigurasi. Jalankan aplikasi dengan NEXORA_SUPABASE_URL dan NEXORA_SUPABASE_PUBLISHABLE_KEY.', textAlign: TextAlign.center, style: AppTypography.bodyMedium))));
}
