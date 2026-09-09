import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/state/theme_manager.dart';
import '../auth/auth_manager.dart';
import '../food/rider_dashboard_screen.dart';
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
      backgroundColor: const Color(0xfff4f7f6),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          const Text(
            'প্রোফাইল',
            style: TextStyle(
              color: Color(0xff1f2937),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          _profileCard(context, scheme, user),
          const SizedBox(height: 18),
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
                onTap: () =>
                    _open(context, const NotificationsSettingsScreen()),
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
              _navTile(
                context,
                icon: Icons.delivery_dining_outlined,
                title: 'রাইডার সেকশন',
                subtitle: 'KYC, চুক্তি, ডেলিভারি ও আয়',
                onTap: () => _open(context, const RiderDashboardScreen()),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _sectionCard(
            context,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                leading: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xffe6f1ee),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.color_lens_outlined,
                    color: Color(0xff006a4e),
                    size: 22,
                  ),
                ),
                title: const Text(
                  'থিম মোড',
                  style: TextStyle(
                    color: Color(0xff1f2937),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: const Text(
                  'সিস্টেম / লাইট / ডার্ক',
                  style: TextStyle(color: Color(0xff4b5563), fontSize: 12),
                ),
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
                      BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text('সিস্টেম'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text('লাইট'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text('ডার্ক'),
                    ),
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
              onPressed: auth.isLoading
                  ? null
                  : () => _showLogoutSheet(context, auth),
              icon: const Icon(Icons.logout),
              label: const Text('লগআউট'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xffdc2626),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xfffecaca)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(
    BuildContext context,
    ColorScheme scheme,
    Map<String, dynamic> user,
  ) {
    final name = user['name']?.toString() ?? 'ব্যবহারকারী';
    final phone = user['phone']?.toString() ?? '-';
    final photoUrl = _resolveImageUrl(
      user['photo_url']?.toString() ?? user['photo']?.toString(),
    );
    final district = user['district']?.toString() ?? 'জেলা নেই';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xffe6f1ee),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xff006a4e),
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xff1f2937),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(phone, style: const TextStyle(color: Color(0xff4b5563))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xff9ca3af),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        district,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xff9ca3af),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: const Color(0xffe6f1ee),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xff006a4e),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xff006a4e),
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String? _resolveImageUrl(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      try {
        final uri = Uri.parse(value);
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          final apiUri = Uri.parse(AppConfig.apiBaseUrl);
          final origin =
              '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
          return '$origin${uri.path}';
        }
      } catch (_) {}
      return value;
    }

    final apiUri = Uri.parse(AppConfig.apiBaseUrl);
    final origin =
        '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
    final cleanPath = value.startsWith('/') ? value : '/storage/$value';
    return '$origin$cleanPath';
  }

  Widget _sectionCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      clipBehavior: Clip.antiAlias,
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

  Widget _navTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        height: 42,
        width: 42,
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
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xff9ca3af),
      ),
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
                Text(
                  'লগআউট করবেন?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'আপনি চাইলে আবার লগইন করে ফিরে আসতে পারবেন।',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
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
