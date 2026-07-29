import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_manager.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  Future<void> _googleLogin(BuildContext context) async {
    final auth = context.read<AuthManager>();
    final ok = await auth.loginWithGoogle();
    if (ok && context.mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Image.asset('assets/images/favicon_bholavashi.png', height: 140),
                const SizedBox(height: 12),
                Text(
                  'ভোলাবাসীতে স্বাগতম',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: scheme.onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  'আপনার একাউন্টে প্রবেশ করুন',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 22),
                _AuthCard(
                  title: 'মোবাইল নম্বর দিয়ে লগইন',
                  subtitle: 'OTP নয়, আপনার পাসওয়ার্ড দিয়ে লগইন হবে',
                  icon: Icons.phone_iphone_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen(mode: LoginMode.phone)),
                  ),
                ),
                const SizedBox(height: 12),
                _AuthCard(
                  title: 'ইমেইল দিয়ে লগইন',
                  subtitle: 'ইমেইল ও পাসওয়ার্ড ব্যবহার করুন',
                  icon: Icons.alternate_email_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen(mode: LoginMode.email)),
                  ),
                ),
                const SizedBox(height: 12),
                Consumer<AuthManager>(
                  builder: (context, auth, child) => _AuthCard(
                    title: 'গুগল দিয়ে লগইন',
                    subtitle: 'দ্রুত ও নিরাপদ',
                    icon: Icons.account_circle_rounded,
                    onTap: auth.isLoading ? null : () => _googleLogin(context),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (auth.isLoading)
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('Google', style: TextStyle(color: scheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: scheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<AuthManager>(
                  builder: (context, auth, child) => auth.errorMessage == null
                      ? const SizedBox.shrink()
                      : Text(auth.errorMessage!, style: TextStyle(color: scheme.error)),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('নতুন ব্যবহারকারী? '),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text('রেজিস্টার করুন'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ভোলাবাসী ব্যবহার করে আপনি আমাদের নীতিমালা মেনে নিচ্ছেন।',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else ...[
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: scheme.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
  }
}
