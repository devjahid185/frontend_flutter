import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_manager.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.phone, required this.otp});

  final String phone;
  final String otp;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthManager>();
    final ok = await auth.resetPassword(phone: widget.phone, otp: widget.otp, password: _password.text.trim());
    if (ok && mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('নতুন পাসওয়ার্ড')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'নতুন পাসওয়ার্ড',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().length < 6) ? 'কমপক্ষে ৬ অক্ষর দিন' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  decoration: const InputDecoration(labelText: 'পাসওয়ার্ড নিশ্চিত করুন'),
                  validator: (v) => (v != _password.text) ? 'ম্যাচ করছে না' : null,
                ),
                const SizedBox(height: 16),
                Consumer<AuthManager>(
                  builder: (context, auth, child) => SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('পাসওয়ার্ড রিসেট'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Consumer<AuthManager>(
                  builder: (context, auth, child) =>
                      auth.errorMessage == null ? const SizedBox.shrink() : Text(auth.errorMessage!, style: TextStyle(color: scheme.error)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
