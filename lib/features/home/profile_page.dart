import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/state/theme_manager.dart';
import '../auth/auth_manager.dart';
import '../common/modern_app_bar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthManager>();
    final themeManager = context.watch<ThemeManager>();
    final user = auth.user ?? <String, dynamic>{};
    final scheme = Theme.of(context).colorScheme;
    final picker = ImagePicker();

    String? resolveImageUrl(String? raw) {
      final value = (raw ?? '').trim();
      if (value.isEmpty) return null;
      if (value.startsWith('http://') || value.startsWith('https://')) {
        try {
          final uri = Uri.parse(value);
          if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
            final apiUri = Uri.parse(AppConfig.apiBaseUrl);
            final origin = '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
            return '$origin${uri.path}';
          }
        } catch (_) {}
        return value;
      }
      return value;
    }

    final photoUrl = resolveImageUrl(user['photo_url']?.toString());

    Future<void> pickAndUpload(ImageSource source) async {
      if (auth.isLoading) return;

      final file = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (file == null) return;

      final ok = await auth.uploadProfilePhoto(file.path);
      if (!context.mounted) return;

      final message = ok ? 'প্রোফাইল ছবি আপডেট হয়েছে' : (auth.errorMessage ?? 'ছবি আপলোড করা যায়নি');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }

    void openPickerSheet() {
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('গ্যালারি থেকে বাছাই'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await pickAndUpload(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('ক্যামেরা দিয়ে তুলুন'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await pickAndUpload(ImageSource.camera);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: const ModernAppBar(title: 'প্রোফাইল', subtitle: 'একাউন্ট ও সেটিংস'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: scheme.primary.withValues(alpha: 0.12),
                        backgroundImage: (photoUrl?.isNotEmpty ?? false)
                            ? NetworkImage(photoUrl!)
                            : null,
                        child: (photoUrl?.isNotEmpty ?? false)
                            ? null
                            : Text(
                                (user['name']?.toString() ?? 'U').substring(0, 1).toUpperCase(),
                                style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                              ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Material(
                          color: scheme.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: auth.isLoading ? null : openPickerSheet,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(Icons.camera_alt, size: 14, color: scheme.onPrimary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name']?.toString() ?? 'ব্যবহারকারী',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: scheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['phone']?.toString() ?? '-',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Chip(
                              backgroundColor: scheme.surfaceContainer,
                              side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                              label: Text(user['district']?.toString() ?? 'জেলা নেই'),
                            ),
                            Chip(
                              backgroundColor: scheme.surfaceContainer,
                              side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                              label: Text(user['role']?.toString() ?? 'user'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: auth.isLoading ? null : openPickerSheet,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('ছবি আপডেট'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_city),
                  title: const Text('জেলা'),
                  subtitle: Text(
                    user['district']?.toString() ?? '-',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('উপজেলা'),
                  subtitle: Text(
                    user['upazila']?.toString() ?? '-',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.badge),
                  title: const Text('রোল'),
                  subtitle: Text(
                    user['role']?.toString() ?? 'user',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'থিম মোড',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: auth.isLoading ? null : auth.fetchProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('প্রোফাইল রিফ্রেশ'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: auth.isLoading ? null : auth.logout,
              icon: const Icon(Icons.logout),
              label: const Text('লগআউট'),
            ),
          ),
        ],
      ),
    );
  }
}
