import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_auth_repository.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nexora/nexora.dart';
import '../../../core/widgets/nexora_mascot.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.redirect});
  final String? redirect;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
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
    FocusManager.instance.primaryFocus?.unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || !email.contains('@')) {
      NexoraToast.show(context, 'Masukkan email yang valid.', error: true);
      return;
    }
    if (password.length < 6) {
      NexoraToast.show(context, 'Kata sandi minimal 6 karakter.', error: true);
      return;
    }
    if (_registerMode && _nameController.text.trim().isEmpty) {
      NexoraToast.show(context, 'Nama wajib diisi.', error: true);
      return;
    }
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
        NexoraToast.show(context, 'Akun dibuat. Cek email untuk verifikasi sebelum masuk.');
        setState(() => _registerMode = false);
        return;
      }
      context.go(_safeRedirect);
    } on AuthException catch (error) {
      if (mounted) NexoraToast.show(context, error.message, error: true);
    } catch (_) {
      if (mounted) NexoraToast.show(context, 'Terjadi kesalahan. Coba lagi.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _safeRedirect {
    final value = widget.redirect;
    return value != null && value.startsWith('/') && !value.startsWith('//') ? value : '/';
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return const NexoraScaffold(
        body: Center(
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

    final isRegister = _registerMode;
    return NexoraScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('NEXORA', style: AppTypography.overline.copyWith(letterSpacing: 2.4, color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.xl),
                    Center(child: NexoraMascot(size: isRegister ? 112 : 126, state: NexoraMascotState.welcome)),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      isRegister ? 'Buat akun Nexora' : 'Masuk ke Nexora',
                      textAlign: TextAlign.center,
                      style: AppTypography.heading1,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isRegister
                          ? 'Nama yang kamu daftarkan akan muncul di beranda.'
                          : 'Catat uang, wallet, tujuan, dan anggaran di satu tempat.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    if (isRegister) ...[
                      NexoraInput(controller: _nameController, label: 'Nama', hintText: 'Nama tampilan'),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    NexoraInput(
                      controller: _emailController,
                      label: 'Email',
                      hintText: 'nama@email.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    NexoraInput(
                      controller: _passwordController,
                      label: 'Kata sandi',
                      hintText: 'Minimal 6 karakter',
                      obscureText: _obscurePassword,
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(_obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff, color: AppColors.textMuted, size: 18),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    NexoraButton(
                      label: isRegister ? 'Daftar' : 'Masuk',
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    NexoraButton(
                      label: isRegister ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar',
                      variant: NexoraButtonVariant.ghost,
                      onPressed: _loading ? null : () => setState(() => _registerMode = !_registerMode),
                    ),
                  ],
                ),
            ),
          ),
        ),
      ),
    );
  }
}
