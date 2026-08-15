import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_manager.dart';
import '../common/modern_app_bar.dart';

enum _PasswordStep { sendOtp, verifyOtp, setPassword }

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _otp = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  _PasswordStep _step = _PasswordStep.sendOtp;

  @override
  void dispose() {
    _currentPassword.dispose();
    _otp.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _sendOtp(AuthManager auth) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await auth.requestPasswordChangeOtp();
    if (!mounted) return;
    if (ok) {
      setState(() => _step = _PasswordStep.verifyOtp);
      messenger.showSnackBar(
        const SnackBar(content: Text('আপনার ফোনে OTP পাঠানো হয়েছে')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'OTP পাঠানো যায়নি')),
      );
    }
  }

  Future<void> _verifyOtp(AuthManager auth) async {
    if (!_otpFormKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final phone = '${auth.user?['phone'] ?? ''}'.trim();
    if (phone.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('আপনার অ্যাকাউন্টে ফোন নম্বর নেই')),
      );
      return;
    }

    final ok = await auth.verifyPasswordChangeOtp(
      phone: phone,
      otp: _otp.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _step = _PasswordStep.setPassword);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'OTP যাচাই করা যায়নি')),
      );
    }
  }

  Future<void> _changePassword(AuthManager auth) async {
    if (!_passwordFormKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await auth.changePassword(
      currentPassword: _currentPassword.text,
      otp: _otp.text.trim(),
      password: _newPassword.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      _currentPassword.clear();
      _otp.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      setState(() => _step = _PasswordStep.sendOtp);
      messenger.showSnackBar(
        const SnackBar(content: Text('পাসওয়ার্ড পরিবর্তন হয়েছে')),
      );
      Navigator.of(context).maybePop();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'পাসওয়ার্ড পরিবর্তন হয়নি')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthManager>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const ModernAppBar(
        title: 'পাসওয়ার্ড পরিবর্তন',
        subtitle: 'সুরক্ষিত ৩ ধাপের যাচাই',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProgressHeader(step: _step),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (_step) {
              _PasswordStep.sendOtp => _StepCard(
                  key: const ValueKey('send-otp'),
                  icon: Icons.sms_outlined,
                  title: 'OTP নিন',
                  subtitle:
                      'আপনার অ্যাকাউন্টের ফোন নম্বরে ৬ ডিজিট OTP পাঠানো হবে।',
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: auth.isLoading ? null : () => _sendOtp(auth),
                      icon: const Icon(Icons.send_to_mobile_outlined),
                      label: const Text('OTP পাঠান'),
                    ),
                  ),
                ),
              _PasswordStep.verifyOtp => _StepCard(
                  key: const ValueKey('verify-otp'),
                  icon: Icons.verified_user_outlined,
                  title: 'OTP যাচাই',
                  subtitle:
                      'ফোনে পাওয়া কোডটি দিন। সঠিক হলে পরের ধাপে পাসওয়ার্ড সেট করতে পারবেন।',
                  child: Form(
                    key: _otpFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _otp,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'OTP কোড',
                            counterText: '',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length != 6) {
                              return '৬ ডিজিট OTP দিন';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () => _sendOtp(auth),
                                child: const Text('আবার পাঠান'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () => _verifyOtp(auth),
                                child: const Text('যাচাই করুন'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              _PasswordStep.setPassword => _StepCard(
                  key: const ValueKey('set-password'),
                  icon: Icons.lock_reset_outlined,
                  title: 'নতুন পাসওয়ার্ড সেট',
                  subtitle:
                      'শেষ ধাপে বর্তমান পাসওয়ার্ড নিশ্চিত করে নতুন পাসওয়ার্ড দিন।',
                  child: Form(
                    key: _passwordFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _currentPassword,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'বর্তমান পাসওয়ার্ড',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'বর্তমান পাসওয়ার্ড দিন';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _newPassword,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'নতুন পাসওয়ার্ড',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'নতুন পাসওয়ার্ড দিন';
                            }
                            if (v.trim().length < 6) {
                              return 'কমপক্ষে ৬ অক্ষর দিন';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _confirmPassword,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'নতুন পাসওয়ার্ড নিশ্চিত করুন',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'পাসওয়ার্ড আবার লিখুন';
                            }
                            if (v.trim() != _newPassword.text.trim()) {
                              return 'দুইটি পাসওয়ার্ড মিলছে না';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: auth.isLoading
                                ? null
                                : () => _changePassword(auth),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('পাসওয়ার্ড পরিবর্তন করুন'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'পাসওয়ার্ড পরিবর্তনের পরে অন্য সব লগইন ডিভাইস নিরাপত্তার জন্য লগআউট হবে।',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step});

  final _PasswordStep step;

  @override
  Widget build(BuildContext context) {
    final activeIndex = _PasswordStep.values.indexOf(step);
    final items = [
      ('OTP', Icons.sms_outlined),
      ('যাচাই', Icons.verified_outlined),
      ('পাসওয়ার্ড', Icons.lock_reset_outlined),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: _ProgressItem(
              label: items[i].$1,
              icon: items[i].$2,
              active: i <= activeIndex,
            ),
          ),
          if (i != items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _ProgressItem extends StatelessWidget {
  const _ProgressItem({
    required this.label,
    required this.icon,
    required this.active,
  });

  final String label;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? scheme.primary.withValues(alpha: 0.1)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? scheme.primary.withValues(alpha: 0.45)
              : scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: active ? scheme.primary : scheme.outline),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? scheme.primary : scheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: scheme.primary.withValues(alpha: 0.1),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
