import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/modern_app_bar.dart';
import 'change_password_screen.dart';
import 'login_devices_screen.dart';

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
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginDevicesScreen()),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: scheme.error,
                ),
                title: Text(
                  'ডিলিট একাউন্ট',
                  style: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'সাপোর্টের মাধ্যমে একাউন্ট ডিলিটের অনুরোধ করুন',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account request'),
        content: const Text(
          'You will be redirected to the official Bholavashi account deletion request page. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final uri = Uri.parse('https://bholavashi.site/delete-account/');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
