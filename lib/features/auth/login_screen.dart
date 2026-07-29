import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'auth_manager.dart';
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
    final auth = context.read<AuthManager>();
    final ok = await auth.login(identity: _identity.text.trim(), password: _password.text.trim());
    if (ok && mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPhone = widget.mode == LoginMode.phone;
    final isEmail = widget.mode == LoginMode.email;
    final label = isPhone
        ? 'মোবাইল নম্বর'
        : isEmail
            ? 'ইমেইল'
            : 'মোবাইল নম্বর বা ইমেইল';
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
                      Image.asset('assets/images/favicon_bholavashi.png', height: 150),
                      const SizedBox(height: 10),
                      Text('স্বাগতম', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: scheme.onSurface)),
                      const SizedBox(height: 6),
                      Text('লগইন করে শুরু করুন', style: TextStyle(color: scheme.onSurfaceVariant)),
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
                        keyboardType: isPhone ? TextInputType.phone : TextInputType.emailAddress,
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
                          if (isPhone && value.length != 11) return '১১ ডিজিটের মোবাইল দিন';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'পাসওয়ার্ড',
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().length < 6) ? 'কমপক্ষে ৬ অক্ষর দিন' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                    child: const Text('পাসওয়ার্ড ভুলে গেছেন?'),
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<AuthManager>(
                  builder: (context, auth, child) => SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('লগইন'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Consumer<AuthManager>(
                  builder: (context, auth, child) =>
                      auth.errorMessage == null ? const SizedBox.shrink() : Text(auth.errorMessage!, style: TextStyle(color: scheme.error)),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
