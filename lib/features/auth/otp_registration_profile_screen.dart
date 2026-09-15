import 'package:flutter/material.dart';
import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:provider/provider.dart';

import 'auth_manager.dart';

class OtpRegistrationProfileScreen extends StatefulWidget {
  const OtpRegistrationProfileScreen({
    super.key,
    required this.phone,
    required this.otp,
    required this.purpose,
  });

  final String phone;
  final String otp;
  final String purpose;

  @override
  State<OtpRegistrationProfileScreen> createState() =>
      _OtpRegistrationProfileScreenState();
}

class _OtpRegistrationProfileScreenState
    extends State<OtpRegistrationProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final ok = await context.read<AuthManager>().registerWithOtp(
      name: _name.text.trim(),
      phone: widget.phone,
      email: _email.text.trim(),
      otp: widget.otp,
      purpose: widget.purpose,
    );
    if (!ok || !mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('প্রোফাইল তথ্য')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/favicon_bholavashi.png',
                  height: 96,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'অ্যাকাউন্ট তৈরি করতে তথ্য দিন',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.phone,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'নাম'),
                      validator: (value) =>
                          (value == null || value.trim().length < 2)
                          ? 'সঠিক নাম দিন'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'ইমেইল (ঐচ্ছিক)',
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null;
                        return text.contains('@') ? null : 'সঠিক ইমেইল দিন';
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
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
                        : const Text('অ্যাকাউন্ট তৈরি করুন'),
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
