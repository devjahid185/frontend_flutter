import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../auth/auth_manager.dart';

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

      if (!context.mounted) return;
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
      backgroundColor: const Color(0xfff4f7f6),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            _SettingsHeader(title: 'প্রোফাইল সেটিংস'),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffe5e7eb)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xffe6f1ee),
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
                                    color: const Color(0xff006a4e),
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
                            style: const TextStyle(
                              color: Color(0xff1f2937),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _phone.text.isNotEmpty ? _phone.text : '-',
                            style: const TextStyle(color: Color(0xff4b5563)),
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
              height: 48,
              child: FilledButton.icon(
                onPressed: auth.isLoading ? null : submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('আপডেট সংরক্ষণ করুন'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff006a4e),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldCard(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: child,
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.title});

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
