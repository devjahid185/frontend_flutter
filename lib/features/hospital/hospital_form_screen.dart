import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class HospitalFormScreen extends StatefulWidget {
  const HospitalFormScreen({super.key, this.initial});

  final Map<String, dynamic>? initial;

  @override
  State<HospitalFormScreen> createState() => _HospitalFormScreenState();
}

class _HospitalFormScreenState extends State<HospitalFormScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _emergencyPhone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _website = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _upazila = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _openingHours = TextEditingController();
  final TextEditingController _beds = TextEditingController();
  final TextEditingController _services = TextEditingController();
  final TextEditingController _facilities = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _lat = TextEditingController();
  final TextEditingController _lng = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;
  int? _categoryId;
  String? _type;
  bool _icu = false;
  bool _emergency = true;
  bool _ambulance = false;
  bool _saving = false;
  bool _uploadingImage = false;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _applyInitial();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _emergencyPhone.dispose();
    _email.dispose();
    _website.dispose();
    _district.dispose();
    _upazila.dispose();
    _address.dispose();
    _openingHours.dispose();
    _beds.dispose();
    _services.dispose();
    _facilities.dispose();
    _description.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  void _applyInitial() {
    final data = widget.initial;
    if (data == null) return;
    _categoryId = (data['category_id'] as num?)?.toInt();
    _name.text = (data['name'] ?? '').toString();
    _type = (data['type'] ?? '').toString();
    _phone.text = (data['phone'] ?? '').toString();
    _emergencyPhone.text = (data['emergency_phone'] ?? '').toString();
    _email.text = (data['email'] ?? '').toString();
    _website.text = (data['website'] ?? '').toString();
    _district.text = (data['district'] ?? '').toString();
    _upazila.text = (data['upazila'] ?? '').toString();
    _address.text = (data['address'] ?? '').toString();
    _openingHours.text = (data['opening_hours'] ?? '').toString();
    _beds.text = (data['bed_capacity'] ?? '').toString();
    _description.text = (data['description'] ?? '').toString();
    _services.text = (data['services'] is List) ? (data['services'] as List).join(', ') : (data['services'] ?? '').toString();
    _facilities.text = (data['facilities'] is List) ? (data['facilities'] as List).join(', ') : (data['facilities'] ?? '').toString();
    _lat.text = (data['lat'] ?? '').toString();
    _lng.text = (data['lng'] ?? '').toString();
    _icu = data['icu_available'] == true || data['icu_available'] == 1;
    _emergency = data['emergency_available'] == true || data['emergency_available'] == 1;
    _ambulance = data['ambulance_available'] == true || data['ambulance_available'] == 1;
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final res = await _api.get('/hospitals/categories');
      _categories = (res as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  List<String> _parseCsv(String input) {
    return input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final res = await _api.post('/hospitals/register', body: {
        'category_id': _categoryId,
        'name': _name.text.trim(),
        'type': _type,
        'phone': _phone.text.trim(),
        'emergency_phone': _emergencyPhone.text.trim(),
        'email': _email.text.trim(),
        'website': _website.text.trim(),
        'district': _district.text.trim(),
        'upazila': _upazila.text.trim(),
        'address': _address.text.trim(),
        'opening_hours': _openingHours.text.trim(),
        'bed_capacity': _beds.text.trim(),
        'icu_available': _icu,
        'emergency_available': _emergency,
        'ambulance_available': _ambulance,
        'services': _parseCsv(_services.text),
        'facilities': _parseCsv(_facilities.text),
        'description': _description.text.trim(),
        'lat': _lat.text.trim(),
        'lng': _lng.text.trim(),
      });

      final hospital = res is Map<String, dynamic> ? res['hospital'] : null;
      final hospitalId = hospital is Map<String, dynamic> ? (hospital['id'] as num?)?.toInt() ?? 0 : 0;

      if (_selectedImage != null && hospitalId > 0) {
        setState(() => _uploadingImage = true);
        await _api.postMultipart(
          '/media/upload',
          fields: {
            'section': 'hospital',
            'target_type': 'hospital',
            'target_id': hospitalId.toString(),
            'set_primary': 'true',
          },
          files: {
            'images[]': [_selectedImage!.path],
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('হাসপাতাল সংরক্ষণ হয়েছে')));
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
    return Scaffold(
      appBar: const ModernAppBar(title: 'হাসপাতাল যোগ/আপডেট', subtitle: 'তথ্য দিন'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('লোগো/ছবি'),
            _imagePicker(context),
            const SizedBox(height: 14),
            _sectionTitle('মৌলিক তথ্য'),
            _categoryDropdown(),
            const SizedBox(height: 10),
            _textField(_name, 'হাসপাতালের নাম', validator: (v) => (v == null || v.trim().isEmpty) ? 'নাম দিন' : null),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'টাইপ'),
              items: const ['সরকারি', 'বেসরকারি', 'ডায়াগনস্টিক', 'ক্লিনিক']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => _type = value),
            ),
            const SizedBox(height: 14),
            _sectionTitle('যোগাযোগ'),
            _textField(_phone, 'ফোন নম্বর', keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _textField(_emergencyPhone, 'ইমার্জেন্সি নম্বর', keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _textField(_email, 'ইমেইল'),
            const SizedBox(height: 10),
            _textField(_website, 'ওয়েবসাইট'),
            const SizedBox(height: 14),
            _sectionTitle('ঠিকানা'),
            _textField(_district, 'জেলা'),
            const SizedBox(height: 10),
            _textField(_upazila, 'উপজেলা'),
            const SizedBox(height: 10),
            _textField(_address, 'পূর্ণ ঠিকানা', maxLines: 2),
            const SizedBox(height: 10),
            _textField(_openingHours, 'খোলার সময় (যেমন: ২৪/৭)'),
            const SizedBox(height: 14),
            _sectionTitle('সেবা ও সুবিধা'),
            _textField(_services, 'সেবা (কমা দিয়ে লিখুন)', maxLines: 2),
            const SizedBox(height: 10),
            _textField(_facilities, 'সুবিধা (কমা দিয়ে লিখুন)', maxLines: 2),
            const SizedBox(height: 10),
            _textField(_beds, 'বেড সংখ্যা', keyboard: TextInputType.number),
            const SizedBox(height: 10),
            _textField(_description, 'বিবরণ', maxLines: 3),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _textField(_lat, 'ল্যাটিটিউড', keyboard: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 10),
                Expanded(child: _textField(_lng, 'লংগিটিউড', keyboard: const TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _emergency,
              onChanged: (v) => setState(() => _emergency = v),
              title: const Text('ইমার্জেন্সি সেবা আছে'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _icu,
              onChanged: (v) => setState(() => _icu = v),
              title: const Text('আইসিইউ আছে'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _ambulance,
              onChanged: (v) => setState(() => _ambulance = v),
              title: const Text('অ্যাম্বুলেন্স আছে'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving || _uploadingImage
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('সংরক্ষণ করুন'),
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
