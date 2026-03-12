import 'package:flutter/material.dart';

import '../common/modern_app_bar.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _push = true;
  bool _sms = false;
  bool _email = false;
  bool _marketing = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(title: 'নোটিফিকেশন', subtitle: 'পুশ, এসএমএস, ইমেইল'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            context,
            children: [
              SwitchListTile(
                value: _push,
                onChanged: (v) => setState(() => _push = v),
                title: const Text('পুশ নোটিফিকেশন'),
                subtitle: Text('অ্যাপের আপডেট ও জরুরি বার্তা', style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
              SwitchListTile(
                value: _sms,
                onChanged: (v) => setState(() => _sms = v),
                title: const Text('এসএমএস নোটিফিকেশন'),
                subtitle: Text('ভেরিফিকেশন ও গুরুত্বপূর্ণ তথ্য', style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
              SwitchListTile(
                value: _email,
                onChanged: (v) => setState(() => _email = v),
                title: const Text('ইমেইল নোটিফিকেশন'),
                subtitle: Text('রিপোর্ট ও অ্যাকাউন্ট আপডেট', style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
              SwitchListTile(
                value: _marketing,
                onChanged: (v) => setState(() => _marketing = v),
                title: const Text('মার্কেটিং বার্তা'),
                subtitle: Text('প্রোমোশন ও অফার', style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required List<Widget> children}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(children: children),
    );
  }
}