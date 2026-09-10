import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../auth/auth_manager.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
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
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const _NotificationHeader(title: 'নোটিফিকেশন'),
          const SizedBox(height: 16),
          if (_loading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(
                minHeight: 4,
                color: Color(0xff006a4e),
                backgroundColor: Color(0xffe6f1ee),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _sectionCard(
            context,
            children: [
              _notificationSwitch(
                value: _push,
                onChanged: (v) async {
                  setState(() => _push = v);
                  await NotificationService.setPushEnabled(v);
                  if (context.mounted) {
                    final auth = context.read<AuthManager>();
                    if (auth.isLoggedIn) {
                      await _api.post(
                        '/notifications/preferences',
                        body: {
                          'push_enabled': v,
                          'sms_enabled': _sms,
                          'email_enabled': _email,
                          'marketing_enabled': _marketing,
                        },
                      );
                    }
                  }
                },
                icon: Icons.notifications_active_outlined,
                title: 'পুশ নোটিফিকেশন',
                subtitle: 'অ্যাপের আপডেট ও জরুরি বার্তা',
              ),
              _notificationSwitch(
                value: _sms,
                onChanged: (v) async {
                  setState(() => _sms = v);
                  final auth = context.read<AuthManager>();
                  if (auth.isLoggedIn) {
                    await _api.post(
                      '/notifications/preferences',
                      body: {
                        'push_enabled': _push,
                        'sms_enabled': v,
                        'email_enabled': _email,
                        'marketing_enabled': _marketing,
                      },
                    );
                  }
                },
                icon: Icons.sms_outlined,
                title: 'এসএমএস নোটিফিকেশন',
                subtitle: 'ভেরিফিকেশন ও গুরুত্বপূর্ণ তথ্য',
              ),
              _notificationSwitch(
                value: _email,
                onChanged: (v) async {
                  setState(() => _email = v);
                  final auth = context.read<AuthManager>();
                  if (auth.isLoggedIn) {
                    await _api.post(
                      '/notifications/preferences',
                      body: {
                        'push_enabled': _push,
                        'sms_enabled': _sms,
                        'email_enabled': v,
                        'marketing_enabled': _marketing,
                      },
                    );
                  }
                },
                icon: Icons.email_outlined,
                title: 'ইমেইল নোটিফিকেশন',
                subtitle: 'রিপোর্ট ও অ্যাকাউন্ট আপডেট',
              ),
              _notificationSwitch(
                value: _marketing,
                onChanged: (v) async {
                  setState(() => _marketing = v);
                  final auth = context.read<AuthManager>();
                  if (auth.isLoggedIn) {
                    await _api.post(
                      '/notifications/preferences',
                      body: {
                        'push_enabled': _push,
                        'sms_enabled': _sms,
                        'email_enabled': _email,
                        'marketing_enabled': v,
                      },
                    );
                  }
                },
                icon: Icons.local_offer_outlined,
                title: 'মার্কেটিং বার্তা',
                subtitle: 'প্রোমোশন ও অফার',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e7eb)),
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

  Widget _notificationSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      activeThumbColor: const Color(0xff006a4e),
      secondary: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xffe6f1ee),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xff006a4e), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xff1f2937),
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xff4b5563), fontSize: 12),
      ),
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader({required this.title});

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
        Text(
          title,
          style: const TextStyle(
            color: Color(0xff1f2937),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
