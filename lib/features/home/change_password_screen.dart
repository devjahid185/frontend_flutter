import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_manager.dart';
import '../common/modern_app_bar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthManager>();
    final scheme = Theme.of(context).colorScheme;

    Future<void> submit() async {
      if (!_formKey.currentState!.validate()) return;

      final ok = await auth.updateProfile(
        password: _newPassword.text.trim(),
      );

      if (!mounted) return;
      if (ok) {
        _newPassword.clear();
        _confirmPassword.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('পাসওয়ার্ড আপডেট হয়েছে')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage ?? 'পাসওয়ার্ড আপডেট করা যায়নি')));
      }
    }

    return Scaffold(
      appBar: const ModernAppBar(title: 'পাসওয়ার্ড পরিবর্তন', subtitle: 'নতুন পাসওয়ার্ড সেট করুন'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _newPassword,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'নতুন পাসওয়ার্ড'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'নতুন পাসওয়ার্ড দিন';
                      if (v.trim().length < 6) return 'কমপক্ষে ৬ অক্ষর দিন';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _confirmPassword,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'পাসওয়ার্ড নিশ্চিত করুন'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'পাসওয়ার্ড আবার লিখুন';
                      if (v.trim() != _newPassword.text.trim()) return 'দুইটি পাসওয়ার্ড মিলছে না';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: auth.isLoading ? null : submit,
                icon: const Icon(Icons.lock_reset),
                label: const Text('পাসওয়ার্ড আপডেট করুন'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}