import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class BloodDonorFormScreen extends StatefulWidget {
  const BloodDonorFormScreen({super.key});

  @override
  State<BloodDonorFormScreen> createState() => _BloodDonorFormScreenState();
}

class _BloodDonorFormScreenState extends State<BloodDonorFormScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _upazila = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _age = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _donations = TextEditingController();
  final TextEditingController _note = TextEditingController();

  String? _bloodGroup;
  String? _gender;
  DateTime? _lastDonation;
  bool _available = true;
  bool _saving = false;
  XFile? _selectedImage;
  bool _uploadingImage = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _district.dispose();
    _upazila.dispose();
    _address.dispose();
    _location.dispose();
    _age.dispose();
    _weight.dispose();
    _donations.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _pickLastDonation() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastDonation ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _lastDonation = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final res = await _api.post('/blood-donor/register', body: {
        'name': _name.text.trim(),
        'blood_group': _bloodGroup,
        'phone': _phone.text.trim(),
        'district': _district.text.trim(),
        'upazila': _upazila.text.trim(),
        'address': _address.text.trim(),
        'location': _location.text.trim(),
        'gender': _gender,
        'age': _age.text.trim(),
        'weight': _weight.text.trim(),
        'donation_count': _donations.text.trim(),
        'note': _note.text.trim(),
        'last_donation': _lastDonation?.toIso8601String().substring(0, 10),
        'available': _available,
      });
      final donor = res is Map<String, dynamic> ? res['donor'] : null;
      final donorId = donor is Map<String, dynamic> ? (donor['id'] as num?)?.toInt() ?? 0 : 0;

      if (_selectedImage != null && donorId > 0) {
        setState(() => _uploadingImage = true);
        await _api.postMultipart(
          '/media/upload',
          fields: {
            'section': 'blood_donor',
            'target_type': 'blood_donor',
            'target_id': donorId.toString(),
            'set_primary': 'true',
          },
          files: {
            'images[]': [_selectedImage!.path],
          },
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ডোনার প্রোফাইল সংরক্ষণ হয়েছে')));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সংরক্ষণ হয়নি')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const ModernAppBar(title: 'ডোনার প্রোফাইল', subtitle: 'নিজের তথ্য দিন'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('প্রোফাইল ছবি'),
            _imagePicker(context),
            const SizedBox(height: 14),
            _sectionTitle('ব্যক্তিগত তথ্য'),
            _textField(_name, 'নাম'),
            const SizedBox(height: 10),
            _dropdown(
              label: 'রক্তের গ্রুপ',
              value: _bloodGroup,
              items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
              onChanged: (value) => setState(() => _bloodGroup = value),
              validator: (value) => (value == null || value.isEmpty) ? 'রক্তের গ্রুপ দিন' : null,
            ),
            const SizedBox(height: 10),
            _textField(_phone, 'ফোন নম্বর', keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _dropdown(
              label: 'লিঙ্গ',
              value: _gender,
              items: const ['পুরুষ', 'নারী', 'অন্যান্য'],
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 14),
            _sectionTitle('ঠিকানা'),
            _textField(_district, 'জেলা'),
            const SizedBox(height: 10),
            _textField(_upazila, 'উপজেলা'),
            const SizedBox(height: 10),
            _textField(_address, 'ঠিকানা', maxLines: 2),
            const SizedBox(height: 10),
            _textField(_location, 'লোকেশন', maxLines: 2),
            const SizedBox(height: 14),
            _sectionTitle('স্বাস্থ্য তথ্য'),
            Row(
              children: [
                Expanded(child: _textField(_age, 'বয়স', keyboard: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _textField(_weight, 'ওজন (কেজি)', keyboard: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _textField(_donations, 'ডোনেশন সংখ্যা', keyboard: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickLastDonation,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_lastDonation == null
                        ? 'শেষ ডোনেশন'
                        : _lastDonation!.toIso8601String().substring(0, 10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _available,
              onChanged: (value) => setState(() => _available = value),
              title: const Text('বর্তমানে ডোনেট করতে পারবেন'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            _textField(_note, 'নোট (ঐচ্ছিক)', maxLines: 2),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving || _uploadingImage
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('সংরক্ষণ করুন'),
            ),
            const SizedBox(height: 12),
            Text(
              'আপনার তথ্য সঠিকভাবে দিন।',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              textAlign: TextAlign.center,
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

  Widget _textField(TextEditingController controller, String label, {TextInputType? keyboard, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    FormFieldValidator<String?>? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
