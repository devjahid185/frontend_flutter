import 'package:flutter/material.dart';

import '../common/modern_app_bar.dart';
import 'change_password_screen.dart';

class SecurityPrivacyScreen extends StatelessWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'অ্যাকাউন্ট ও সিকিউরিটি',
        subtitle: 'প্রাইভেসি ও নিরাপত্তা',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            context,
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('পাসওয়ার্ড পরিবর্তন'),
                subtitle: Text(
                  'আপনার একাউন্ট সুরক্ষিত রাখুন',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.devices_outlined),
                title: const Text('লগইন ডিভাইস'),
                subtitle: Text(
                  'সক্রিয় ডিভাইস তালিকা',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSnack(context, 'এই ফিচারটি শীঘ্রই আসছে'),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('প্রাইভেসি সেটিংস'),
                subtitle: Text(
                  'কে কী দেখবে নিয়ন্ত্রণ করুন',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSnack(context, 'এই ফিচারটি শীঘ্রই আসছে'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _sectionCard(BuildContext context, {required List<Widget> children}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(children: children),
    );
  }
}
