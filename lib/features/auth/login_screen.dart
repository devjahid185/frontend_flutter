import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'auth_manager.dart';
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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/favicon_bholavashi.png',
                        height: 150,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '\u09b8\u09cd\u09ac\u09be\u0997\u09a4\u09ae',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '\u09b2\u0997\u0987\u09a8 \u0995\u09b0\u09c7 \u09b6\u09c1\u09b0\u09c1 \u0995\u09b0\u09c1\u09a8',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
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
                          if (value.isEmpty) {
                            return '\u09ab\u09bf\u09b2\u09cd\u09a1\u099f\u09bf \u09aa\u09c2\u09b0\u09a3 \u0995\u09b0\u09c1\u09a8';
                          }
                          if (isPhone && value.length != 11) {
                            return '\u09e7\u09e7 \u09a1\u09bf\u099c\u09bf\u099f\u09c7\u09b0 \u09ae\u09cb\u09ac\u09be\u0987\u09b2 \u09a6\u09bf\u09a8';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText:
                              '\u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().length < 6)
                            ? '\u0995\u09ae\u09aa\u0995\u09cd\u09b7\u09c7 \u09ec \u0985\u0995\u09cd\u09b7\u09b0 \u09a6\u09bf\u09a8'
                            : null,
                      ),
                    ],
                  ),
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
                    child: const Text(
                      '\u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1 \u09ad\u09c1\u09b2\u09c7 \u0997\u09c7\u099b\u09c7\u09a8?',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                          : const Text('\u09b2\u0997\u0987\u09a8'),
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
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '\u09a8\u09a4\u09c1\u09a8 \u09ac\u09cd\u09af\u09ac\u09b9\u09be\u09b0\u0995\u09be\u09b0\u09c0? ',
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                      child: const Text(
                        '\u09b0\u09c7\u099c\u09bf\u09b8\u09cd\u099f\u09be\u09b0 \u0995\u09b0\u09c1\u09a8',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
