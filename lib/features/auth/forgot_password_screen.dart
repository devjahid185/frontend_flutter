import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_manager.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthManager>();
    final ok = await auth.requestOtp(
      phone: _phone.text.trim(),
      purpose: 'reset',
    );
    if (!ok || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpScreen(phone: _phone.text.trim(), purpose: 'reset'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('পাসওয়ার্ড রিসেট')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OTP পাঠাতে আপনার মোবাইল নম্বর দিন',
                style: TextStyle(color: scheme.onSurface),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'মোবাইল নম্বর'),
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'সঠিক নম্বর দিন'
                      : null,
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
