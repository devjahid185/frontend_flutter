import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_manager.dart';
import 'auth_form_shell.dart';
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
    return AuthFormShell(
      title: 'ইমেইল দিয়ে পাসওয়ার্ড রিসেট',
      subtitle: 'আপনার অ্যাকাউন্টের ইমেইলে নিরাপত্তা কোড যাবে',
      centerHeader: true,
      headerIcon: Icons.mark_email_unread_outlined,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
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
            const SizedBox(height: 22),
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
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('লগইন পেজে ফিরে যেতে এখানে চাপুন'),
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
    );
  }
}
