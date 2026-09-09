import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'auth_manager.dart';
import 'auth_form_shell.dart';
import 'email_forgot_password_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

enum LoginMode { any, phone, email }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.mode = LoginMode.any});

  final LoginMode mode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identity = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _identity.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthManager>();
    final ok = await auth.login(
      identity: _identity.text.trim(),
      password: _password.text.trim(),
    );
    if (!ok || !mounted) return;

    // LoginScreen is opened as a pushed route from AuthLandingScreen.
    // After AuthManager becomes logged-in, return to root so MaterialApp can show MainShell.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPhone = widget.mode == LoginMode.phone;
    final isEmail = widget.mode == LoginMode.email;
    final label = isPhone
        ? '\u09ae\u09cb\u09ac\u09be\u0987\u09b2 \u09a8\u09ae\u09cd\u09ac\u09b0'
        : isEmail
        ? '\u0987\u09ae\u09c7\u0987\u09b2'
        : '\u09ae\u09cb\u09ac\u09be\u0987\u09b2 \u09a8\u09ae\u09cd\u09ac\u09b0 \u09ac\u09be \u0987\u09ae\u09c7\u0987\u09b2';

    return AuthFormShell(
      title: 'স্বাগতম ফিরে এসেছেন!',
      subtitle: 'আপনার ফোন নম্বর এবং পাসওয়ার্ড দিয়ে লগইন করুন',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _identity,
              keyboardType: isPhone
                  ? TextInputType.phone
                  : TextInputType.emailAddress,
              inputFormatters: isPhone
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ]
                  : null,
              decoration: InputDecoration(labelText: label),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'ফিল্ডটি পূরণ করুন';
                if (isPhone && value.length != 11) {
                  return '১১ ডিজিটের মোবাইল দিন';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'পাসওয়ার্ড',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.trim().length < 6)
                  ? 'কমপক্ষে ৬ অক্ষর দিন'
                  : null,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => isEmail
                        ? EmailForgotPasswordScreen(
                            initialEmail: _identity.text.trim(),
                          )
                        : const ForgotPasswordScreen(),
                  ),
                ),
                child: const Text('পাসওয়ার্ড ভুলে গেছেন?'),
              ),
            ),
            const SizedBox(height: 18),
            Consumer<AuthManager>(
              builder: (context, auth, child) => SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: LogoLoader(size: 20),
                        )
                      : const Text('লগইন'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Consumer<AuthManager>(
              builder: (context, auth, child) => auth.errorMessage == null
                  ? const SizedBox.shrink()
                  : Text(
                      auth.errorMessage!,
                      style: TextStyle(color: scheme.error),
                    ),
            ),
            const SizedBox(height: 24),
            const _AuthDivider(),
            const SizedBox(height: 24),
            Consumer<AuthManager>(
              builder: (context, auth, child) => SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          final ok = await auth.loginWithGoogle();
                          if (ok && context.mounted) {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xff1f2937),
                    side: const BorderSide(color: Color(0xffe5e7eb)),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.account_circle_rounded, size: 18),
                  label: const Text(
                    'গুগল',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'নতুন ব্যবহারকারী? ',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text('এখানে চাপুন'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xffe5e7eb))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'অথবা',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xffe5e7eb))),
      ],
    );
  }
}
