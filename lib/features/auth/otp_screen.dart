import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'auth_manager.dart';
import 'reset_password_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.phone,
    required this.purpose,
    this.registerPayload,
  });

  final String phone;
  final String purpose; // register | reset
  final Map<String, dynamic>? registerPayload;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otp = TextEditingController();

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final auth = context.read<AuthManager>();
    final otp = _otp.text.trim();
    if (otp.length != 6) return;

    if (widget.purpose == 'register') {
      final payload = widget.registerPayload ?? {};
      final ok = await auth.registerWithOtp(
        name: payload['name'] ?? '',
        phone: payload['phone'] ?? widget.phone,
        email: payload['email'],
        password: payload['password'] ?? '',
        otp: otp,
      );
      if (ok && mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
      return;
    }

    final verified = await auth.verifyOtp(phone: widget.phone, purpose: widget.purpose, otp: otp);
    if (!verified || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(phone: widget.phone, otp: otp),
      ),
    );
  }

  Future<void> _resend() async {
    await context.read<AuthManager>().requestOtp(phone: widget.phone, purpose: widget.purpose);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('OTP যাচাই')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('৬ ডিজিট OTP দিন', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _otp,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                decoration: const InputDecoration(labelText: 'OTP'),
              ),
              const SizedBox(height: 16),
              Consumer<AuthManager>(
                builder: (context, auth, child) => SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: auth.isLoading ? null : _verify,
                    child: auth.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('ভেরিফাই'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _resend, child: const Text('OTP আবার পাঠান')),
              const SizedBox(height: 8),
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
