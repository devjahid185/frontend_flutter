import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_manager.dart';
import 'email_otp_screen.dart';

class EmailForgotPasswordScreen extends StatefulWidget {
  const EmailForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<EmailForgotPasswordScreen> createState() =>
      _EmailForgotPasswordScreenState();
}

class _EmailForgotPasswordScreenState extends State<EmailForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final email = _email.text.trim();
    final ok = await context.read<AuthManager>().requestEmailPasswordReset(
      email: email,
    );
    if (!ok || !mounted) return;

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => EmailOtpScreen(email: email)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('ইমেইল পাসওয়ার্ড রিসেট')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'রিসেট কোড পাঠাতে আপনার অ্যাকাউন্টের ইমেইল দিন',
                style: TextStyle(color: scheme.onSurface),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
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
                        : const Text('কোড পাঠান'),
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
    );
  }
}
