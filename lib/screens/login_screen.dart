import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/login_form_dialog.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _enter(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  Future<void> _loginWithEmail(BuildContext context) async {
    final isValid = await showDialog<bool>(
      context: context,
      builder: (_) => const LoginFormDialog(),
    );
    if (!context.mounted) return;
    if (isValid == true) _enter(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _Branding(),
                        const SizedBox(height: 48),
                        _LoginButton(
                          label: 'Lanjutkan dengan Google',
                          icon: const Text(
                            'G',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          background: Colors.white,
                          foreground: const Color(0xFF1F2937),
                          border: const BorderSide(color: Color(0xFFE5E7EB)),
                          onTap: () => _enter(context),
                        ),
                        const SizedBox(height: 16),
                        _LoginButton(
                          label: 'Gunakan Nomor Telepon',
                          icon: const Icon(Icons.smartphone,
                              size: 20, color: Colors.white),
                          background: AppColors.primary,
                          foreground: Colors.white,
                          onTap: () => _enter(context),
                        ),
                        const SizedBox(height: 16),
                        _LoginButton(
                          label: 'Masuk dengan Email',
                          icon: const Icon(Icons.mail_outline,
                              size: 20, color: Color(0xFF374151)),
                          background: const Color(0xFFF3F4F6),
                          foreground: const Color(0xFF374151),
                          onTap: () => _loginWithEmail(context),
                        ),
                        const SizedBox(height: 24),
                        const _OrDivider(),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () => _enter(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textMuted,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Masuk sebagai Tamu (Guest)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Branding extends StatelessWidget {
  const _Branding();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(Icons.route_rounded, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 24),
        const Text(
          'ASPAL',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 280),
  child: const Text(
            'Aplikasi Survei Pelaporan Akses Lalu-lintas',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.border,
  });

  final String label;
  final Widget icon;
  final Color background;
  final Color foreground;
  final BorderSide? border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: StadiumBorder(side: border ?? BorderSide.none),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFE5E7EB))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ATAU',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFE5E7EB))),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    const link = TextStyle(color: AppColors.primary);
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            fontSize: 12,
            height: 1.6,
            color: AppColors.textMuted,
          ),
          children: [
            TextSpan(text: 'Dengan masuk, Anda menyetujui\n'),
            TextSpan(text: 'Syarat & Ketentuan', style: link),
            TextSpan(text: ' serta '),
            TextSpan(text: 'Kebijakan Privasi', style: link),
            TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
