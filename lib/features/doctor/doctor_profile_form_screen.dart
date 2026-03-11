import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class DoctorProfileFormScreen extends StatefulWidget {
  const DoctorProfileFormScreen({super.key, this.initial});

  final Map<String, dynamic>? initial;

  @override
  State<DoctorProfileFormScreen> createState() => _DoctorProfileFormScreenState();
}

class _DoctorProfileFormScreenState extends State<DoctorProfileFormScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _specialization = TextEditingController();
  final TextEditingController _hospital = TextEditingController();
  final TextEditingController _clinic = TextEditingController();
  final TextEditingController _experience = TextEditingController();
  final TextEditingController _degrees = TextEditingController();
  final TextEditingController _bmdc = TextEditingController();
  final TextEditingController _fees = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _upazila = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _chamberTime = TextEditingController();
  final TextEditingController _about = TextEditingController();
  final TextEditingController _lat = TextEditingController();
  final TextEditingController _lng = TextEditingController();

  int? _categoryId;
  int? _doctorId;
  bool _available = true;
  bool _loadingCategories = true;
  bool _saving = false;
  bool _uploadingImage = false;
  XFile? _selectedImage;
  List<Map<String, dynamic>> _categories = [];
  final List<Map<String, String>> _schedules = [];

  static const _days = <String>['শনিবার', 'রবিবার', 'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার'];

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
    _specialization.dispose();
    _hospital.dispose();
    _clinic.dispose();
    _experience.dispose();
    _degrees.dispose();
    _bmdc.dispose();
    _fees.dispose();
    _phone.dispose();
    _email.dispose();
    _district.dispose();
    _upazila.dispose();
    _address.dispose();
    _chamberTime.dispose();
    _about.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  void _applyInitial() {
    final data = widget.initial;
    if (data == null) return;

    _doctorId = (data['id'] as num?)?.toInt();
    _categoryId = (data['category_id'] as num?)?.toInt();
    _name.text = (data['name'] ?? '').toString();
    _title.text = (data['title'] ?? '').toString();
    _specialization.text = (data['specialization'] ?? '').toString();
    _hospital.text = (data['hospital'] ?? '').toString();
    _clinic.text = (data['clinic'] ?? '').toString();
    _experience.text = (data['experience_years'] ?? '').toString();
    _degrees.text = (data['degrees'] ?? '').toString();
    _bmdc.text = (data['bmdc_number'] ?? '').toString();
    _fees.text = (data['fees'] ?? '').toString();
    _phone.text = (data['phone'] ?? '').toString();
    _email.text = (data['email'] ?? '').toString();
    _district.text = (data['district'] ?? '').toString();
    _upazila.text = (data['upazila'] ?? '').toString();
    _address.text = (data['address'] ?? '').toString();
    _chamberTime.text = (data['chamber_time'] ?? '').toString();
    _about.text = (data['about'] ?? '').toString();
    _lat.text = (data['lat'] ?? '').toString();
    _lng.text = (data['lng'] ?? '').toString();
    _available = data['is_available'] == true || data['is_available'] == 1;

    final schedules = (data['schedules'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    _schedules
      ..clear()
      ..addAll(schedules.map((e) => {
            'day_of_week': (e['day_of_week'] ?? '').toString(),
            'start_time': (e['start_time'] ?? '').toString(),
            'end_time': (e['end_time'] ?? '').toString(),
            'note': (e['note'] ?? '').toString(),
          }));
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final res = await _api.get('/doctors/categories');
      _categories = (res as List?)?.cast<Map<String, dynamic>>() ?? [];
    } on ApiException catch (_) {
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      debugPrint('[DoctorProfile] submit start');
      final res = await _api.post('/doctors/register', body: {
        'category_id': _categoryId,
        'name': _name.text.trim(),
        'title': _title.text.trim(),
        'specialization': _specialization.text.trim(),
        'hospital': _hospital.text.trim(),
        'clinic': _clinic.text.trim(),
        'experience_years': _experience.text.trim(),
        'degrees': _degrees.text.trim(),
        'bmdc_number': _bmdc.text.trim(),
        'fees': _fees.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'district': _district.text.trim(),
        'upazila': _upazila.text.trim(),
        'address': _address.text.trim(),
        'chamber_time': _chamberTime.text.trim(),
        'about': _about.text.trim(),
        'is_available': _available,
        'lat': _lat.text.trim(),
        'lng': _lng.text.trim(),
      });

      debugPrint('[DoctorProfile] register response: $res');
      final doctor = res is Map<String, dynamic> ? res['doctor'] : null;
      final doctorId = doctor is Map<String, dynamic> ? (doctor['id'] as num?)?.toInt() ?? 0 : 0;
      if (doctorId > 0) _doctorId = doctorId;

      if (_selectedImage != null && doctorId > 0) {
        setState(() => _uploadingImage = true);
        final uploadRes = await _api.postMultipart(
          '/media/upload',
          fields: {
            'section': 'doctor',
            'target_type': 'doctor',
            'target_id': doctorId.toString(),
            'set_primary': 'true',
          },
          files: {
            'images[]': [_selectedImage!.path],
          },
        );
        debugPrint('[DoctorProfile] image upload response: $uploadRes');
      }

      if (doctorId > 0 && _schedules.isNotEmpty) {
        final scheduleRes = await _api.post('/doctors/$doctorId/schedules', body: {
          'schedules': _schedules
              .where((e) => (e['day_of_week'] ?? '').toString().isNotEmpty)
              .map((e) => {
                    'day_of_week': e['day_of_week'],
                    'start_time': e['start_time'],
                    'end_time': e['end_time'],
                    'note': e['note'],
                  })
              .toList(),
        });
        debugPrint('[DoctorProfile] schedule response: $scheduleRes');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ডাক্তার প্রোফাইল সংরক্ষণ হয়েছে')));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      debugPrint('[DoctorProfile] ApiException: ${e.message} (${e.statusCode})');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      debugPrint('[DoctorProfile] Unknown error');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সংরক্ষণ করা যায়নি')));
    } finally {
      if (mounted) setState(() => _saving = false);
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _pickTime(int index, String key) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked == null) return;
    final value = picked.hour.toString().padLeft(2, '0') + ':' + picked.minute.toString().padLeft(2, '0');
    setState(() => _schedules[index][key] = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(title: 'ডাক্তার প্রোফাইল', subtitle: 'আপনার তথ্য দিন'),
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
            _textField(_name, 'ডাক্তার নাম', validator: (v) => (v == null || v.trim().isEmpty) ? 'নাম দিন' : null),
            const SizedBox(height: 10),
            _textField(_title, 'পদবি (ঐচ্ছিক)'),
            const SizedBox(height: 10),
            _textField(_specialization, 'বিশেষজ্ঞতা (ঐচ্ছিক)'),
            const SizedBox(height: 14),
            _sectionTitle('হাসপাতাল/ক্লিনিক'),
            _textField(_hospital, 'হাসপাতাল'),
            const SizedBox(height: 10),
            _textField(_clinic, 'ক্লিনিক/চেম্বার'),
            const SizedBox(height: 10),
            _textField(_chamberTime, 'চেম্বার সময় (যেমন: বিকাল ৫টা - ৯টা)'),
            const SizedBox(height: 14),
            _sectionTitle('অভিজ্ঞতা'),
            Row(
              children: [
                Expanded(child: _textField(_experience, 'অভিজ্ঞতা (বছর)', keyboard: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _textField(_fees, 'ফি (৳)', keyboard: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 10),
            _textField(_degrees, 'ডিগ্রি/যোগ্যতা'),
            const SizedBox(height: 10),
            _textField(_bmdc, 'বিএমডিসি নম্বর'),
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
            Row(
              children: [
                Expanded(child: _textField(_lat, 'ল্যাটিটিউড', keyboard: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 10),
                Expanded(child: _textField(_lng, 'লংগিটিউড', keyboard: const TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
            const SizedBox(height: 14),
            _sectionTitle('ডাক্তার সম্পর্কে'),
            _textField(_about, 'সংক্ষিপ্ত পরিচিতি', maxLines: 3),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _available,
              onChanged: (value) => setState(() => _available = value),
              title: const Text('বর্তমানে সেবা দেওয়া হচ্ছে'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 14),
            _sectionTitle('সাপ্তাহিক সময়সূচি'),
            if (_schedules.isEmpty)
              Text('সময়সূচি দিলে রোগীরা সহজে বুক করতে পারবে।', style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            ..._schedules.asMap().entries.map((entry) => _scheduleCard(entry.key, scheme)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() => _schedules.add({'day_of_week': '', 'start_time': '', 'end_time': '', 'note': ''})),
              icon: const Icon(Icons.add),
              label: const Text('নতুন সময় যোগ করুন'),
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
              'সব তথ্য বাংলা ভাষায় পরিষ্কারভাবে দিন।',
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
      decoration: const InputDecoration(labelText: 'ডাক্তার ক্যাটাগরি'),
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

  Widget _scheduleCard(int index, ColorScheme scheme) {
    final item = _schedules[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: item['day_of_week']!.isEmpty ? null : item['day_of_week'],
                  decoration: const InputDecoration(labelText: 'দিন'),
                  items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (value) => setState(() => _schedules[index]['day_of_week'] = value ?? ''),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _schedules.removeAt(index)),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickTime(index, 'start_time'),
                  child: Text(item['start_time']!.isEmpty ? 'শুরু সময়' : item['start_time']!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickTime(index, 'end_time'),
                  child: Text(item['end_time']!.isEmpty ? 'শেষ সময়' : item['end_time']!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: item['note'],
            decoration: const InputDecoration(labelText: 'নোট (ঐচ্ছিক)'),
            onChanged: (value) => _schedules[index]['note'] = value,
          ),
        ],
      ),
    );
  }
}
