import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_manager.dart';

class EmailResetPasswordScreen extends StatefulWidget {
  const EmailResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  final String email;
  final String otp;

  @override
  State<EmailResetPasswordScreen> createState() =>
      _EmailResetPasswordScreenState();
}

class _EmailResetPasswordScreenState extends State<EmailResetPasswordScreen> {
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
    final ok = await auth.resetPasswordWithEmail(
      email: widget.email,
      otp: widget.otp,
      password: _password.text.trim(),
    );
    if (!ok || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'পাসওয়ার্ড রিসেট সফল',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'আপনার পাসওয়ার্ড পরিবর্তন হয়েছে। এখন নতুন পাসওয়ার্ড দিয়ে লগইন করুন।',
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('লগইনে যান'),
            ),
          ],
        );
      },
    );

    if (mounted) {
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
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().length < 6)
                      ? 'কমপক্ষে ৬ অক্ষর দিন'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'পাসওয়ার্ড নিশ্চিত করুন',
                  ),
                  validator: (value) =>
                      (value != _password.text) ? 'ম্যাচ করছে না' : null,
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
                          : const Text('পাসওয়ার্ড রিসেট'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Consumer<AuthManager>(
                  builder: (context, auth, child) => auth.errorMessage == null
                      ? const SizedBox.shrink()
                      : Text(
                          auth.errorMessage!,
                          style: TextStyle(color: scheme.error),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
