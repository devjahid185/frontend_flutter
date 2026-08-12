import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'auth_manager.dart';

class EmailForgotPasswordScreen extends StatefulWidget {
  const EmailForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<EmailForgotPasswordScreen> createState() =>
      _EmailForgotPasswordScreenState();
}

class _EmailForgotPasswordScreenState extends State<EmailForgotPasswordScreen> {
  final _emailKey = GlobalKey<FormState>();
  final _resetKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _codeSent = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_emailKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final ok = await context.read<AuthManager>().requestEmailPasswordReset(
      email: _email.text.trim(),
    );
    if (!ok || !mounted) return;

    setState(() => _codeSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('রিসেট কোড ইমেইলে পাঠানো হয়েছে।')),
    );
  }

  Future<void> _resetPassword() async {
    if (!(_resetKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final ok = await context.read<AuthManager>().resetPasswordWithEmail(
      email: _email.text.trim(),
      otp: _otp.text.trim(),
      password: _password.text.trim(),
    );
    if (!ok || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('পাসওয়ার্ড রিসেট হয়েছে। এখন লগইন করুন।')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('ইমেইল দিয়ে পাসওয়ার্ড রিসেট')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              _codeSent
                  ? 'ইমেইলে পাওয়া ৬ ডিজিট কোড ও নতুন পাসওয়ার্ড দিন'
                  : 'আপনার অ্যাকাউন্টের ইমেইল দিন, আমরা রিসেট কোড পাঠাবো',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            Form(
              key: _emailKey,
              child: TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                enabled: !_codeSent,
                decoration: const InputDecoration(labelText: 'ইমেইল'),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'ইমেইল দিন';
                  if (!email.contains('@')) return 'সঠিক ইমেইল দিন';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            if (!_codeSent)
              _SubmitButton(label: 'রিসেট কোড পাঠান', onTap: _sendCode),
            if (_codeSent) ...[
              Form(
                key: _resetKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        labelText: '৬ ডিজিট কোড',
                      ),
                      validator: (value) => (value?.trim().length ?? 0) == 6
                          ? null
                          : '৬ ডিজিট কোড দিন',
                    ),
                    const SizedBox(height: 12),
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
                      validator: (value) => (value?.trim().length ?? 0) >= 6
                          ? null
                          : 'কমপক্ষে ৬ অক্ষর দিন',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscure,
                      decoration: const InputDecoration(
                        labelText: 'পাসওয়ার্ড নিশ্চিত করুন',
                      ),
                      validator: (value) =>
                          value == _password.text ? null : 'পাসওয়ার্ড মিলছে না',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SubmitButton(
                label: 'পাসওয়ার্ড রিসেট করুন',
                onTap: _resetPassword,
              ),
              TextButton(
                onPressed: () {
                  setState(() => _codeSent = false);
                  _otp.clear();
                  _password.clear();
                  _confirm.clear();
                },
                child: const Text('ইমেইল পরিবর্তন করুন'),
              ),
            ],
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
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthManager>(
      builder: (context, auth, child) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: auth.isLoading ? null : onTap,
          child: auth.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: LogoLoader(size: 20),
                )
              : Text(label),
        ),
      ),
    );
  }
}
