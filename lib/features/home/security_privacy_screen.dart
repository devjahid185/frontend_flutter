import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'change_password_screen.dart';
import 'login_devices_screen.dart';

class SecurityPrivacyScreen extends StatelessWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const _SecurityHeader(title: 'অ্যাকাউন্ট ও সিকিউরিটি'),
          const SizedBox(height: 16),
          _sectionCard(
            context,
            children: [
              _securityTile(
                icon: Icons.lock_outline,
                title: 'পাসওয়ার্ড পরিবর্তন',
                subtitle: 'আপনার একাউন্ট সুরক্ষিত রাখুন',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                ),
              ),
              _securityTile(
                icon: Icons.devices_outlined,
                title: 'লগইন ডিভাইস',
                subtitle: 'সক্রিয় ডিভাইস তালিকা',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginDevicesScreen()),
                ),
              ),
              _securityTile(
                icon: Icons.delete_outline_rounded,
                title: 'ডিলিট একাউন্ট',
                subtitle: 'সাপোর্টের মাধ্যমে একাউন্ট ডিলিটের অনুরোধ করুন',
                danger: true,
                trailing: Icons.open_in_new_rounded,
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
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xffe5e7eb)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, indent: 72, color: Color(0xffe5e7eb)),
          ],
        ],
      ),
    );
  }

  Widget _securityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
    IconData trailing = Icons.chevron_right_rounded,
  }) {
    final color = danger ? const Color(0xffdc2626) : const Color(0xff006a4e);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: danger ? const Color(0xffffeeee) : const Color(0xffe6f1ee),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: danger ? color : const Color(0xff1f2937),
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xff4b5563), fontSize: 12),
      ),
      trailing: Icon(trailing, color: const Color(0xff9ca3af), size: 20),
      onTap: onTap,
    );
  }
}

class _SecurityHeader extends StatelessWidget {
  const _SecurityHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.chevron_left_rounded),
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xff1f2937),
            padding: EdgeInsets.zero,
            minimumSize: const Size(28, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff1f2937),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
