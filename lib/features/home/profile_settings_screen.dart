import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../auth/auth_manager.dart';
import '../common/modern_app_bar.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _district = TextEditingController();
  final _upazila = TextEditingController();
  final _union = TextEditingController();
  final _address = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _district.dispose();
    _upazila.dispose();
    _union.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final user = context.read<AuthManager>().user ?? <String, dynamic>{};
    _name.text = user['name']?.toString() ?? '';
    _phone.text = user['phone']?.toString() ?? '';
    _email.text = user['email']?.toString() ?? '';
    _district.text = user['district']?.toString() ?? '';
    _upazila.text = user['upazila']?.toString() ?? '';
    _union.text = user['union_name']?.toString() ?? '';
    _address.text = user['address']?.toString() ?? '';
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthManager>();
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
            final origin =
                '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
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

      final message = ok
          ? 'প্রোফাইল ছবি আপডেট হয়েছে'
          : (auth.errorMessage ?? 'ছবি আপলোড করা যায়নি');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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

    Future<void> submit() async {
      if (!_formKey.currentState!.validate()) return;
      final ok = await auth.updateProfile(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        district: _district.text.trim().isEmpty ? null : _district.text.trim(),
        upazila: _upazila.text.trim().isEmpty ? null : _upazila.text.trim(),
        unionName: _union.text.trim().isEmpty ? null : _union.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      );

      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('প্রোফাইল আপডেট হয়েছে')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMessage ?? 'আপডেট করা যায়নি')),
        );
      }
    }

    return Scaffold(
      appBar: const ModernAppBar(
        title: 'প্রোফাইল সেটিংস',
        subtitle: 'তথ্য পরিবর্তন ও আপডেট',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
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
                          backgroundColor: scheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          backgroundImage: (photoUrl?.isNotEmpty ?? false)
                              ? NetworkImage(photoUrl!)
                              : null,
                          child: (photoUrl?.isNotEmpty ?? false)
                              ? null
                              : Text(
                                  (_name.text.isNotEmpty ? _name.text : 'U')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
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
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: scheme.onPrimary,
                                ),
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
                            _name.text.isNotEmpty ? _name.text : 'ব্যবহারকারী',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: scheme.onSurface),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _phone.text.isNotEmpty ? _phone.text : '-',
                            style: TextStyle(color: scheme.onSurfaceVariant),
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
            const SizedBox(height: 12),
            _fieldCard(
              context,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'নাম'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'নাম দিন' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phone,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'মোবাইল নম্বর',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'নম্বর দিন' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _email,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'ইমেইল (ঐচ্ছিক)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _district,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'জেলা'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _upazila,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'উপজেলা'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _union,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'ইউনিয়ন (ঐচ্ছিক)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _address,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'ঠিকানা (ঐচ্ছিক)',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: auth.isLoading ? null : submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('আপডেট সংরক্ষণ করুন'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldCard(BuildContext context, {required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: child,
    );
  }
}
