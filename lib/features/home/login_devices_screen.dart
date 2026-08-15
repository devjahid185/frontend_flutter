import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/logo_loader.dart';
import '../auth/auth_manager.dart';
import '../common/modern_app_bar.dart';

class LoginDevicesScreen extends StatefulWidget {
  const LoginDevicesScreen({super.key});

  @override
  State<LoginDevicesScreen> createState() => _LoginDevicesScreenState();
}

class _LoginDevicesScreenState extends State<LoginDevicesScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AuthManager>().loginDevices();
  }

  void _reload() {
    setState(() => _future = context.read<AuthManager>().loginDevices());
  }

  Future<void> _revoke(int id, bool isCurrent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCurrent ? 'এই ডিভাইস লগআউট?' : 'ডিভাইস লগআউট?'),
        content: Text(
          isCurrent
              ? 'এই ডিভাইস লগআউট করলে আপনাকে আবার লগইন করতে হবে।'
              : 'এই ডিভাইস থেকে আপনার অ্যাকাউন্ট লগআউট হয়ে যাবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('না'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('লগআউট করুন'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final auth = context.read<AuthManager>();
    final ok = await auth.revokeLoginDevice(id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ডিভাইস লগআউট হয়েছে')));
      if (auth.isLoggedIn) {
        _reload();
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'ডিভাইস লগআউট করা যায়নি')),
      );
    }
  }

  Future<void> _revokeOthers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('অন্য সব ডিভাইস লগআউট?'),
        content: const Text(
          'বর্তমান ডিভাইস ছাড়া আপনার অ্যাকাউন্ট অন্য সব ডিভাইস থেকে লগআউট হবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('না'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('লগআউট করুন'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final auth = context.read<AuthManager>();
    final ok = await auth.revokeOtherLoginDevices();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'অন্য সব ডিভাইস লগআউট হয়েছে'
              : auth.errorMessage ?? 'কাজটি করা যায়নি',
        ),
      ),
    );
    if (ok) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ModernAppBar(
        title: 'লগইন ডিভাইস',
        subtitle: 'যেখানে আপনার অ্যাকাউন্ট চালু আছে',
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'রিফ্রেশ',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LogoLoader(showLabel: true));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'ডিভাইস তালিকা লোড করা যায়নি',
                  style: TextStyle(color: scheme.error),
                ),
              ),
            );
          }

          final devices = snapshot.data ?? [];
          if (devices.isEmpty) {
            return const Center(child: Text('কোনো লগইন ডিভাইস পাওয়া যায়নি'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'অপরিচিত ডিভাইস দেখলে সঙ্গে সঙ্গে লগআউট করে পাসওয়ার্ড পরিবর্তন করুন।',
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: context.watch<AuthManager>().isLoading
                      ? null
                      : _revokeOthers,
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text('অন্য সব ডিভাইস লগআউট করুন'),
                ),
                const SizedBox(height: 12),
                ...devices.map(
                  (device) => _DeviceCard(
                    device: device,
                    onLogout: () => _revoke(
                      int.tryParse('${device['id']}') ?? 0,
                      device['is_current'] == true,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, required this.onLogout});

  final Map<String, dynamic> device;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCurrent = device['is_current'] == true;
    final name = '${device['name'] ?? 'Bholavashi App'}';
    final lastUsed = _formatTime(
      device['last_used_at'] ?? device['created_at'],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent
              ? scheme.primary.withValues(alpha: 0.45)
              : scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isCurrent
                ? scheme.primary.withValues(alpha: 0.12)
                : scheme.surfaceContainerHighest,
            child: Icon(
              Icons.devices_outlined,
              color: isCurrent ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'বর্তমান',
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'শেষ ব্যবহার: $lastUsed',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'লগআউট',
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic raw) {
    final value = raw?.toString();
    if (value == null || value.isEmpty || value == 'null') return 'অজানা';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    return '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
