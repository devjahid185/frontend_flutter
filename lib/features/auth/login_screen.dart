import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'auth_manager.dart';
import 'otp_screen.dart';
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

  @override
  void dispose() {
    _identity.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthManager>();
    final phone = _identity.text.trim();
    final ok = await auth.requestOtp(phone: phone, purpose: 'login');
    if (!ok || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpScreen(phone: phone, purpose: 'login'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const label =
        '\u09ae\u09cb\u09ac\u09be\u0987\u09b2 \u09a8\u09ae\u09cd\u09ac\u09b0';

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
                        'OTP দিয়ে নিরাপদে লগইন করুন',
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
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        decoration: InputDecoration(labelText: label),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) {
                            return '\u09ab\u09bf\u09b2\u09cd\u09a1\u099f\u09bf \u09aa\u09c2\u09b0\u09a3 \u0995\u09b0\u09c1\u09a8';
                          }
                          if (value.length != 11) {
                            return '\u09e7\u09e7 \u09a1\u09bf\u099c\u09bf\u099f\u09c7\u09b0 \u09ae\u09cb\u09ac\u09be\u0987\u09b2 \u09a6\u09bf\u09a8';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                          : const Text('OTP পাঠান'),
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
