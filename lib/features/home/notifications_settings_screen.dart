import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import '../auth/auth_manager.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _push = true;
  bool _sms = false;
  bool _email = false;
  bool _marketing = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final auth = context.read<AuthManager>();
      if (!auth.isLoggedIn) {
        final enabled = await NotificationService.isPushEnabled();
        if (!mounted) return;
        setState(() {
          _push = enabled;
          _loading = false;
        });
        return;
      }

      final res = await _api.get('/notifications/preferences');
      if (res is Map<String, dynamic>) {
        final push = res['push_enabled'];
        final sms = res['sms_enabled'];
        final email = res['email_enabled'];
        final marketing = res['marketing_enabled'];
        setState(() {
          _push = push is bool ? push : true;
          _sms = sms is bool ? sms : false;
          _email = email is bool ? email : false;
          _marketing = marketing is bool ? marketing : false;
        });
        await NotificationService.setPushEnabled(_push);
      }
    } catch (_) {
      final enabled = await NotificationService.isPushEnabled();
      if (!mounted) return;
      setState(() {
        _push = enabled;
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(title: 'নোটিফিকেশন', subtitle: 'পুশ, এসএমএস, ইমেইল'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(),
          _sectionCard(
            context,
            children: [
              SwitchListTile(
                value: _push,
                onChanged: (v) async {
                  setState(() => _push = v);
                  await NotificationService.setPushEnabled(v);
                  if (context.mounted) {
                    final auth = context.read<AuthManager>();
                    if (auth.isLoggedIn) {
                      await _api.post('/notifications/preferences', body: {
                        'push_enabled': v,
                        'sms_enabled': _sms,
                        'email_enabled': _email,
                        'marketing_enabled': _marketing,
                      });
                    }
                  }
                },
                title: const Text('পুশ নোটিফিকেশন'),
                subtitle: Text('অ্যাপের আপডেট ও জরুরি বার্তা', style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
              SwitchListTile(
                value: _sms,
                onChanged: (v) async {
                  setState(() => _sms = v);
                  final auth = context.read<AuthManager>();
                  if (auth.isLoggedIn) {
                    await _api.post('/notifications/preferences', body: {
                      'push_enabled': _push,
                      'sms_enabled': v,
                      'email_enabled': _email,
                      'marketing_enabled': _marketing,
                    });
                  }
                },
                title: const Text('এসএমএস নোটিফিকেশন'),
                subtitle: Text('ভেরিফিকেশন ও গুরুত্বপূর্ণ তথ্য', style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
              SwitchListTile(
                value: _email,
                onChanged: (v) async {
                  setState(() => _email = v);
                  final auth = context.read<AuthManager>();
                  if (auth.isLoggedIn) {
                    await _api.post('/notifications/preferences', body: {
                      'push_enabled': _push,
                      'sms_enabled': _sms,
                      'email_enabled': v,
                      'marketing_enabled': _marketing,
                    });
                  }
                },
                title: const Text('ইমেইল নোটিফিকেশন'),
                subtitle: Text('রিপোর্ট ও অ্যাকাউন্ট আপডেট', style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
              SwitchListTile(
                value: _marketing,
                onChanged: (v) async {
                  setState(() => _marketing = v);
                  final auth = context.read<AuthManager>();
                  if (auth.isLoggedIn) {
                    await _api.post('/notifications/preferences', body: {
                      'push_enabled': _push,
                      'sms_enabled': _sms,
                      'email_enabled': _email,
                      'marketing_enabled': v,
                    });
                  }
                },
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
