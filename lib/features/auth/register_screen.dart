import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_manager.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthManager>();
    final ok = await auth.requestOtp(phone: _phone.text.trim(), purpose: 'register');
    if (!ok || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          phone: _phone.text.trim(),
          purpose: 'register',
          registerPayload: {
            'name': _name.text.trim(),
            'phone': _phone.text.trim(),
            'email': _email.text.trim(),
            'password': _password.text.trim(),
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('রেজিস্টার')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Image.asset('assets/images/favicon_bholavashi.png', height: 100),
              const SizedBox(height: 12),
              Text('আপনার অ্যাকাউন্ট তৈরি করুন', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
              const SizedBox(height: 18),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'নাম'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'নাম দিন' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'মোবাইল নম্বর'),
                      validator: (v) => (v == null || v.trim().length < 10) ? 'সঠিক নম্বর দিন' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'ইমেইল (ঐচ্ছিক)'),
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscure,
                      decoration: const InputDecoration(labelText: 'পাসওয়ার্ড নিশ্চিত করুন'),
                      validator: (v) => (v != _password.text) ? 'ম্যাচ করছে না' : null,
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
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('OTP পাঠান'),
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
    );
  }
}
