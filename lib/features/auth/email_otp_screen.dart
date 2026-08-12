import 'dart:async';

import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'auth_manager.dart';
import 'email_reset_password_screen.dart';

class EmailOtpScreen extends StatefulWidget {
  const EmailOtpScreen({super.key, required this.email});

  final String email;

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
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
    final otp = _otp.text.trim();
    if (otp.length != 6) return;

    final verified = await context.read<AuthManager>().verifyEmailPasswordReset(
      email: widget.email,
      otp: otp,
    );
    if (!verified || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmailResetPasswordScreen(email: widget.email, otp: otp),
      ),
    );
  }

  Future<void> _resend() async {
    if (_resendSeconds > 0) return;
    final ok = await context.read<AuthManager>().requestEmailPasswordReset(
      email: widget.email,
    );
    if (ok && mounted) _startResendCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('ইমেইল OTP যাচাই')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ইমেইলে পাঠানো ৬ ডিজিট কোড দিন',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.email,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _otp,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(labelText: 'OTP'),
              ),
              const SizedBox(height: 16),
              _EmailOtpTimerCard(seconds: _resendSeconds, onResend: _resend),
              const SizedBox(height: 16),
              Consumer<AuthManager>(
                builder: (context, auth, child) => SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: auth.isLoading ? null : _verify,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: LogoLoader(size: 20),
                          )
                        : const Text('ভেরিফাই'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
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

class _EmailOtpTimerCard extends StatelessWidget {
  const _EmailOtpTimerCard({required this.seconds, required this.onResend});

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
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: canResend ? 1 : progress,
                  strokeWidth: 4,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: canResend ? Colors.green.shade700 : scheme.primary,
                ),
                Text(
                  canResend ? '✓' : '$seconds',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canResend
                      ? 'OTP আবার পাঠানো যাবে'
                      : 'OTP আবার পাঠাতে অপেক্ষা করুন',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  canResend
                      ? 'নতুন OTP নিতে পারবেন।'
                      : '$seconds সেকেন্ড পর resend চালু হবে।',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: canResend ? onResend : null,
            child: const Text('Resend'),
          ),
        ],
      ),
    );
  }
}
