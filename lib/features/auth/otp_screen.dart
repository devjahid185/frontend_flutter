import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
  Timer? _cooldownTimer;
  int _resendSeconds = 60;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otp.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
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
    if (_resendSeconds > 0) return;
    final ok = await context.read<AuthManager>().requestOtp(phone: widget.phone, purpose: widget.purpose);
    if (ok && mounted) _startResendCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('OTP \u09af\u09be\u099a\u09be\u0987')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\u09ec \u09a1\u09bf\u099c\u09bf\u099f OTP \u09a6\u09bf\u09a8', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _otp,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                decoration: const InputDecoration(labelText: 'OTP'),
              ),
              const SizedBox(height: 16),
              _OtpTimerCard(seconds: _resendSeconds, onResend: _resend),
              const SizedBox(height: 16),
              Consumer<AuthManager>(
                builder: (context, auth, child) => SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: auth.isLoading ? null : _verify,
                    child: auth.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('\u09ad\u09c7\u09b0\u09bf\u09ab\u09be\u0987'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Consumer<AuthManager>(
                builder: (context, auth, child) => auth.errorMessage == null
                    ? const SizedBox.shrink()
                    : Text(auth.errorMessage!, style: TextStyle(color: scheme.error)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpTimerCard extends StatelessWidget {
  const _OtpTimerCard({required this.seconds, required this.onResend});

  final int seconds;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (seconds / 60).clamp(0.0, 1.0);
    final canResend = seconds <= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Row(children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: canResend ? 1 : progress,
              strokeWidth: 4,
              backgroundColor: scheme.surfaceContainerHighest,
              color: canResend ? Colors.green.shade700 : scheme.primary,
            ),
            Text(canResend ? '\u2713' : '$seconds', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              canResend ? 'OTP \u0986\u09ac\u09be\u09b0 \u09aa\u09be\u09a0\u09be\u09a8\u09cb \u09af\u09be\u09ac\u09c7' : 'OTP \u0986\u09ac\u09be\u09b0 \u09aa\u09be\u09a0\u09be\u09a4\u09c7 \u0985\u09aa\u09c7\u0995\u09cd\u09b7\u09be \u0995\u09b0\u09c1\u09a8',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              canResend ? '\u09a8\u09a4\u09c1\u09a8 OTP \u09a8\u09bf\u09a4\u09c7 \u09aa\u09be\u09b0\u09ac\u09c7\u09a8\u0964' : '$seconds \u09b8\u09c7\u0995\u09c7\u09a8\u09cd\u09a1 \u09aa\u09b0 resend \u099a\u09be\u09b2\u09c1 \u09b9\u09ac\u09c7\u0964',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ]),
        ),
        TextButton(
          onPressed: canResend ? onResend : null,
          child: const Text('Resend'),
        ),
      ]),
    );
  }
}
