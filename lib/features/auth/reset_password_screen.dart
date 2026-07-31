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
    if (!ok || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            '\u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1 \u09b0\u09bf\u09b8\u09c7\u099f \u09b8\u09ab\u09b2',
            style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w900),
          ),
          content: Text(
            '\u0986\u09aa\u09a8\u09be\u09b0 \u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1 \u09aa\u09b0\u09bf\u09ac\u09b0\u09cd\u09a4\u09a8 \u09b9\u09df\u09c7\u099b\u09c7\u0964 \u098f\u0996\u09a8 \u09a8\u09a4\u09c1\u09a8 \u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1 \u09a6\u09bf\u09df\u09c7 \u09b2\u0997\u0987\u09a8 \u0995\u09b0\u09c1\u09a8\u0964',
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('\u09b2\u0997\u0987\u09a8\u09c7 \u09af\u09be\u09a8'),
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
      appBar: AppBar(title: const Text('\u09a8\u09a4\u09c1\u09a8 \u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1')),
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
                    labelText: '\u09a8\u09a4\u09c1\u09a8 \u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().length < 6) ? '\u0995\u09ae\u09aa\u0995\u09cd\u09b7\u09c7 \u09ec \u0985\u0995\u09cd\u09b7\u09b0 \u09a6\u09bf\u09a8' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  decoration: const InputDecoration(labelText: '\u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1 \u09a8\u09bf\u09b6\u09cd\u099a\u09bf\u09a4 \u0995\u09b0\u09c1\u09a8'),
                  validator: (v) => (v != _password.text) ? '\u09ae\u09cd\u09af\u09be\u099a \u0995\u09b0\u099b\u09c7 \u09a8\u09be' : null,
                ),
                const SizedBox(height: 16),
                Consumer<AuthManager>(
                  builder: (context, auth, child) => SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('\u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1 \u09b0\u09bf\u09b8\u09c7\u099f'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Consumer<AuthManager>(
                  builder: (context, auth, child) => auth.errorMessage == null
                      ? const SizedBox.shrink()
                      : Text(auth.errorMessage!, style: TextStyle(color: scheme.error)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
