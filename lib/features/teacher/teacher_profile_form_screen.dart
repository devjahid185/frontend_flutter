import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class TeacherProfileFormScreen extends StatefulWidget {
  const TeacherProfileFormScreen({super.key, this.initial});

  final Map<String, dynamic>? initial;

  @override
  State<TeacherProfileFormScreen> createState() => _TeacherProfileFormScreenState();
}

class _TeacherProfileFormScreenState extends State<TeacherProfileFormScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _subjects = TextEditingController();
  final TextEditingController _classLevels = TextEditingController();
  final TextEditingController _medium = TextEditingController();
  final TextEditingController _gender = TextEditingController();
  final TextEditingController _experience = TextEditingController();
  final TextEditingController _education = TextEditingController();
  final TextEditingController _institute = TextEditingController();
  final TextEditingController _hourlyRate = TextEditingController();
  final TextEditingController _monthlyRate = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _upazila = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _preferredArea = TextEditingController();
  final TextEditingController _mode = TextEditingController();
  final TextEditingController _availability = TextEditingController();
  final TextEditingController _about = TextEditingController();
  final TextEditingController _lat = TextEditingController();
  final TextEditingController _lng = TextEditingController();

  int? _categoryId;
  int? _teacherId;
  bool _available = true;
  bool _loadingCategories = true;
  bool _saving = false;
  bool _uploadingImage = false;
  XFile? _selectedImage;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _applyInitial();
  }

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    _subjects.dispose();
    _classLevels.dispose();
    _medium.dispose();
    _gender.dispose();
    _experience.dispose();
    _education.dispose();
    _institute.dispose();
    _hourlyRate.dispose();
    _monthlyRate.dispose();
    _phone.dispose();
    _email.dispose();
    _district.dispose();
    _upazila.dispose();
    _address.dispose();
    _preferredArea.dispose();
    _mode.dispose();
    _availability.dispose();
    _about.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  void _applyInitial() {
    final data = widget.initial;
    if (data == null) return;

    _teacherId = (data['id'] as num?)?.toInt();
    _categoryId = (data['category_id'] as num?)?.toInt();
    _name.text = (data['name'] ?? '').toString();
    _title.text = (data['title'] ?? '').toString();
    _subjects.text = (data['subjects'] as List?)?.join(', ') ?? '';
    _classLevels.text = (data['class_levels'] as List?)?.join(', ') ?? '';
    _medium.text = (data['medium'] ?? '').toString();
    _gender.text = (data['gender'] ?? '').toString();
    _experience.text = (data['experience_years'] ?? '').toString();
    _education.text = (data['education'] ?? '').toString();
    _institute.text = (data['institute'] ?? '').toString();
    _hourlyRate.text = (data['hourly_rate'] ?? '').toString();
    _monthlyRate.text = (data['monthly_rate'] ?? '').toString();
    _phone.text = (data['phone'] ?? '').toString();
    _email.text = (data['email'] ?? '').toString();
    _district.text = (data['district'] ?? '').toString();
    _upazila.text = (data['upazila'] ?? '').toString();
    _address.text = (data['address'] ?? '').toString();
    _preferredArea.text = (data['preferred_area'] ?? '').toString();
    _mode.text = (data['mode'] ?? '').toString();
    _availability.text = (data['availability'] ?? '').toString();
    _about.text = (data['about'] ?? '').toString();
    _lat.text = (data['lat'] ?? '').toString();
    _lng.text = (data['lng'] ?? '').toString();
    _available = data['is_available'] == true || data['is_available'] == 1;
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final res = await _api.get('/teachers/categories');
      _categories = (res as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() => _selectedImage = image);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final subjects = _subjects.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final classes = _classLevels.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      final res = await _api.post('/teachers/register', body: {
        'category_id': _categoryId,
        'name': _name.text.trim(),
        'title': _title.text.trim(),
        'subjects': subjects.isEmpty ? null : subjects,
        'class_levels': classes.isEmpty ? null : classes,
        'medium': _medium.text.trim(),
        'gender': _gender.text.trim(),
        'experience_years': _experience.text.trim(),
        'education': _education.text.trim(),
        'institute': _institute.text.trim(),
        'hourly_rate': _hourlyRate.text.trim(),
        'monthly_rate': _monthlyRate.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'district': _district.text.trim(),
        'upazila': _upazila.text.trim(),
        'address': _address.text.trim(),
        'preferred_area': _preferredArea.text.trim(),
        'mode': _mode.text.trim(),
        'availability': _availability.text.trim(),
        'about': _about.text.trim(),
        'is_available': _available,
        'lat': _lat.text.trim(),
        'lng': _lng.text.trim(),
      });

      final teacher = res is Map<String, dynamic> ? res['teacher'] : null;
      final teacherId = teacher is Map<String, dynamic> ? (teacher['id'] as num?)?.toInt() ?? 0 : 0;
      if (teacherId > 0) _teacherId = teacherId;

      if (_selectedImage != null && teacherId > 0) {
        setState(() => _uploadingImage = true);
        await _api.postMultipart(
          '/media/upload',
          fields: {
            'section': 'teacher',
            'target_type': 'teacher',
            'target_id': teacherId.toString(),
            'set_primary': 'true',
          },
          files: {
            'images[]': [_selectedImage!.path],
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('টিউটর প্রোফাইল সংরক্ষণ হয়েছে')));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সংরক্ষণ করা যায়নি')));
    } finally {
      if (mounted) setState(() => _saving = false);
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(title: 'টিউটর প্রোফাইল', subtitle: 'আপনার তথ্য দিন'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('প্রোফাইল ছবি'),
            _imagePicker(context),
            const SizedBox(height: 14),
            _sectionTitle('মৌলিক তথ্য'),
            _categoryDropdown(),
            const SizedBox(height: 10),
            _textField(_name, 'টিউটরের নাম', validator: (v) => (v == null || v.trim().isEmpty) ? 'নাম দিন' : null),
            const SizedBox(height: 10),
            _textField(_title, 'পদবি/ট্যাগলাইন (ঐচ্ছিক)'),
            const SizedBox(height: 10),
            _textField(_subjects, 'বিষয় (কমা দিয়ে লিখুন)'),
            const SizedBox(height: 10),
            _textField(_classLevels, 'ক্লাস/লেভেল (কমা দিয়ে লিখুন)'),
            const SizedBox(height: 10),
            _textField(_medium, 'মাধ্যম (বাংলা/ইংরেজি/মাদ্রাসা)'),
            const SizedBox(height: 10),
            _textField(_gender, 'লিঙ্গ (ঐচ্ছিক)'),
            const SizedBox(height: 14),
            _sectionTitle('যোগ্যতা ও ফি'),
            Row(
              children: [
                Expanded(child: _textField(_experience, 'অভিজ্ঞতা (বছর)', keyboard: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _textField(_hourlyRate, 'ঘণ্টা ফি', keyboard: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 10),
            _textField(_monthlyRate, 'মাসিক ফি', keyboard: TextInputType.number),
            const SizedBox(height: 10),
            _textField(_education, 'শিক্ষাগত যোগ্যতা'),
            const SizedBox(height: 10),
            _textField(_institute, 'ইনস্টিটিউট/কলেজ'),
            const SizedBox(height: 14),
            _sectionTitle('যোগাযোগ'),
            _textField(_phone, 'মোবাইল নম্বর', keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _textField(_email, 'ইমেইল'),
            const SizedBox(height: 14),
            _sectionTitle('ঠিকানা'),
            _textField(_district, 'জেলা'),
            const SizedBox(height: 10),
            _textField(_upazila, 'উপজেলা'),
            const SizedBox(height: 10),
            _textField(_address, 'পূর্ণ ঠিকানা', maxLines: 2),
            const SizedBox(height: 10),
            _textField(_preferredArea, 'পছন্দের এলাকা'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _textField(_lat, 'Latitude', keyboard: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 10),
                Expanded(child: _textField(_lng, 'Longitude', keyboard: const TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
            const SizedBox(height: 14),
            _sectionTitle('টিউশন সেটআপ'),
            _textField(_mode, 'মোড (অনলাইন/অফলাইন/দুইটাই)'),
            const SizedBox(height: 10),
            _textField(_availability, 'সময়সূচি/উপলব্ধতা', maxLines: 2),
            const SizedBox(height: 10),
            _textField(_about, 'পরিচিতি', maxLines: 3),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _available,
              onChanged: (value) => setState(() => _available = value),
              title: const Text('বর্তমানে টিউশন নিচ্ছেন'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving || _uploadingImage
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('সংরক্ষণ করুন'),
            ),
            const SizedBox(height: 12),
            Text(
              'সব তথ্য বাংলায় পরিষ্কারভাবে দিন।',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
    );
  }

  Widget _imagePicker(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: _selectedImage == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt_outlined, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 6),
                    Text('ছবি আপলোড করুন', style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
              ),
      ),
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<int>(
      value: _categoryId,
      decoration: const InputDecoration(labelText: 'ক্যাটাগরি'),
      items: _categories
          .map((c) => DropdownMenuItem<int>(
                value: (c['id'] as num?)?.toInt(),
                child: Text(c['name']?.toString() ?? ''),
              ))
          .toList(),
      onChanged: (value) => setState(() => _categoryId = value),
      validator: (value) => value == null ? 'ক্যাটাগরি নির্বাচন করুন' : null,
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    int maxLines = 1,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }
}
