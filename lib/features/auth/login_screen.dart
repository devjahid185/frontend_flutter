import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/modern_app_bar.dart';
import 'auth_manager.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthManager>();
    final ok = await auth.login(
      identity: _identityController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    if (!ok && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(title: 'লগইন', subtitle: 'আপনার একাউন্টে প্রবেশ করুন'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Consumer<AuthManager>(
                builder: (context, auth, child) => Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.location_city, size: 52),
                      const SizedBox(height: 8),
                      Text('জেলা সুপার অ্যাপ', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 6),
                      const Text('ফোন বা ইমেইল দিয়ে লগইন করুন', textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _identityController,
                        decoration: const InputDecoration(labelText: 'ফোন নম্বর বা ইমেইল'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'এই ঘরটি পূরণ করুন' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'পাসওয়ার্ড'),
                        validator: (v) => (v == null || v.length < 6) ? 'কমপক্ষে ৬ অক্ষর দিন' : null,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: auth.isLoading ? null : _submit,
                        child: auth.isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('লগইন'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: const Text('নতুন অ্যাকাউন্ট তৈরি করুন'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
