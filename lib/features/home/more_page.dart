import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/theme_manager.dart';
import '../auth/auth_manager.dart';
import '../common/modern_app_bar.dart';
import 'profile_settings_screen.dart';
import 'notifications_settings_screen.dart';
import 'security_privacy_screen.dart';
import 'language_settings_screen.dart';
import 'help_support_screen.dart';
import 'about_app_screen.dart';
import 'terms_privacy_screen.dart';
import 'feedback_screen.dart';
import 'my_activity_screen.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthManager>();
    final themeManager = context.watch<ThemeManager>();
    final user = auth.user ?? <String, dynamic>{};

    return Scaffold(
      appBar: const ModernAppBar(title: 'আরও', subtitle: 'সেটিংস ও সহায়তা'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _profileCard(context, scheme, user),
          const SizedBox(height: 12),
          _sectionTitle(context, 'অ্যাকাউন্ট'),
          _sectionCard(
            context,
            children: [
              _navTile(
                context,
                icon: Icons.manage_accounts_outlined,
                title: 'প্রোফাইল সেটিংস',
                subtitle: 'নাম, ছবি, জেলা, থিম',
                onTap: () => _open(context, const ProfileSettingsScreen()),
              ),
              _navTile(
                context,
                icon: Icons.verified_user_outlined,
                title: 'অ্যাকাউন্ট ও সিকিউরিটি',
                subtitle: 'পাসওয়ার্ড, ডিভাইস, প্রাইভেসি',
                onTap: () => _open(context, const SecurityPrivacyScreen()),
              ),
              _navTile(
                context,
                icon: Icons.notifications_outlined,
                title: 'নোটিফিকেশন',
                subtitle: 'পুশ, এসএমএস, ইমেইল',
                onTap: () => _open(context, const NotificationsSettingsScreen()),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionTitle(context, 'প্রেফারেন্স'),
          _sectionCard(
            context,
            children: [
              _navTile(
                context,
                icon: Icons.language_outlined,
                title: 'ভাষা',
                subtitle: 'বাংলা / ইংরেজি',
                onTap: () => _open(context, const LanguageSettingsScreen()),
              ),
              _navTile(
                context,
                icon: Icons.tune_outlined,
                title: 'আমার কার্যক্রম',
                subtitle: 'আমার পোস্ট, আবেদন, বুকিং',
                onTap: () => _open(context, const MyActivityScreen()),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _sectionCard(
            context,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.color_lens_outlined, color: scheme.primary),
                ),
                title: const Text('থিম মোড', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('সিস্টেম / লাইট / ডার্ক', style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SegmentedButton<ThemeMode>(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return scheme.primaryContainer;
                      }
                      return scheme.surfaceContainer;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return scheme.onPrimaryContainer;
                      }
                      return scheme.onSurface;
                    }),
                    side: WidgetStatePropertyAll(
                      BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  segments: const [
                    ButtonSegment<ThemeMode>(value: ThemeMode.system, label: Text('সিস্টেম')),
                    ButtonSegment<ThemeMode>(value: ThemeMode.light, label: Text('লাইট')),
                    ButtonSegment<ThemeMode>(value: ThemeMode.dark, label: Text('ডার্ক')),
                  ],
                  selected: {themeManager.themeMode},
                  onSelectionChanged: (selection) {
                    if (selection.isNotEmpty) {
                      themeManager.setThemeMode(selection.first);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionTitle(context, 'সহায়তা'),
          _sectionCard(
            context,
            children: [
              _navTile(
                context,
                icon: Icons.support_agent_outlined,
                title: 'হেল্প & সাপোর্ট',
                subtitle: 'FAQ এবং যোগাযোগ',
                onTap: () => _open(context, const HelpSupportScreen()),
              ),
              _navTile(
                context,
                icon: Icons.rate_review_outlined,
                title: 'ফিডব্যাক দিন',
                subtitle: 'মতামত ও রেটিং',
                onTap: () => _open(context, const FeedbackScreen()),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionTitle(context, 'অ্যাপ তথ্য'),
          _sectionCard(
            context,
            children: [
              _navTile(
                context,
                icon: Icons.info_outline,
                title: 'অ্যাপ সম্পর্কে',
                subtitle: 'ভার্সন ও ডেভেলপার',
                onTap: () => _open(context, const AboutAppScreen()),
              ),
              _navTile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'টার্মস ও প্রাইভেসি',
                subtitle: 'নীতি ও শর্তাবলী',
                onTap: () => _open(context, const TermsPrivacyScreen()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: auth.isLoading ? null : () => _showLogoutSheet(context, auth),
              icon: const Icon(Icons.logout),
              label: const Text('লগআউট'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(BuildContext context, ColorScheme scheme, Map<String, dynamic> user) {
    final name = user['name']?.toString() ?? 'ব্যবহারকারী';
    final phone = user['phone']?.toString() ?? '-';
    final district = user['district']?.toString() ?? 'জেলা নেই';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: scheme.primary.withValues(alpha: 0.12),
            child: Text(name.substring(0, 1).toUpperCase(), style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text(phone, style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text(district, style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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

  Widget _navTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.primary.withValues(alpha: 0.12),
        child: Icon(icon, color: scheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _showLogoutSheet(BuildContext context, AuthManager auth) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('লগআউট করবেন?', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('আপনি চাইলে আবার লগইন করে ফিরে আসতে পারবেন।', style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('না'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await auth.logout();
                        },
                        child: const Text('হ্যাঁ, লগআউট'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}