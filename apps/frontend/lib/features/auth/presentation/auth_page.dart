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
              name: _nameController.text.trim().isEmpty
                  ? null
                  : _nameController.text.trim(),
            )
          : await _repository.login(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

      if (!mounted) return;
      if (response.session == null) {
        _showMessage(
          'Akun dibuat. Cek email untuk verifikasi sebelum login.',
        );
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
    return value != null && value.startsWith('/') && !value.startsWith('//')
        ? value
        : '/';
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.danger : AppColors.primary,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return const _SupabaseConfigurationPage();
    }

    return PremiumScaffold(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screen,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const NexoraRobot(size: 104),
                    AppSpacing.gapMD,
                    Text(
                      _registerMode ? 'Create your Nexora' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: AppTypography.heading1,
                    ),
                    AppSpacing.gapXS,
                    Text(
                      _registerMode
                          ? 'Mulai bangun kebiasaan finansial yang lebih terukur.'
                          : 'Masuk untuk melanjutkan ke ruang finansialmu.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapXL,
                    if (_registerMode) ...[
                      _field(
                        controller: _nameController,
                        label: 'Nama',
                        icon: Icons.person_outline,
                      ),
                      AppSpacing.gapMD,
                    ],
                    _field(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty || !email.contains('@')) {
                          return 'Masukkan email yang valid';
                        }
                        return null;
                      },
                    ),
                    AppSpacing.gapMD,
                    _field(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffix: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      validator: (value) => (value ?? '').length < 6
                          ? 'Password minimal 6 karakter'
                          : null,
                    ),
                    AppSpacing.gapLG,
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusXL,
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_registerMode ? 'Create account' : 'Sign in'),
                    ),
                    AppSpacing.gapMD,
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() => _registerMode = !_registerMode),
                      child: Text(
                        _registerMode
                            ? 'Sudah punya akun? Sign in'
                            : 'Belum punya akun? Create account',
                      ),
                    ),
                    AppSpacing.gapSM,
                    Text(
                      'Data finansial Nexora dilindungi oleh Supabase Auth + Row Level Security.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator ??
          (value) => (value?.trim().isEmpty ?? true)
              ? '$label wajib diisi'
              : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: AppRadius.radiusXL,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusXL,
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: .45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusXL,
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _SupabaseConfigurationPage extends StatelessWidget {
  const _SupabaseConfigurationPage();

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      child: Center(
        child: Padding(
          padding: AppSpacing.screen,
          child: Text(
            'Supabase belum dikonfigurasi. Jalankan aplikasi dengan NEXORA_SUPABASE_URL dan NEXORA_SUPABASE_PUBLISHABLE_KEY.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
        ),
      ),
    );
  }
}
