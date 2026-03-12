import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class HotelFormScreen extends StatefulWidget {
  const HotelFormScreen({super.key, this.initial});

  final Map<String, dynamic>? initial;

  @override
  State<HotelFormScreen> createState() => _HotelFormScreenState();
}

class _HotelFormScreenState extends State<HotelFormScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _type = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _website = TextEditingController();
  final TextEditingController _facebook = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _upazila = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _checkIn = TextEditingController();
  final TextEditingController _checkOut = TextEditingController();
  final TextEditingController _rooms = TextEditingController();
  final TextEditingController _minPrice = TextEditingController();
  final TextEditingController _maxPrice = TextEditingController();
  final TextEditingController _amenities = TextEditingController();
  final TextEditingController _services = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _lat = TextEditingController();
  final TextEditingController _lng = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;
  int? _categoryId;
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
    _type.dispose();
    _phone.dispose();
    _email.dispose();
    _website.dispose();
    _facebook.dispose();
    _district.dispose();
    _upazila.dispose();
    _address.dispose();
    _checkIn.dispose();
    _checkOut.dispose();
    _rooms.dispose();
    _minPrice.dispose();
    _maxPrice.dispose();
    _amenities.dispose();
    _services.dispose();
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
    _type.text = (data['type'] ?? '').toString();
    _phone.text = (data['phone'] ?? '').toString();
    _email.text = (data['email'] ?? '').toString();
    _website.text = (data['website'] ?? '').toString();
    _facebook.text = (data['facebook'] ?? '').toString();
    _district.text = (data['district'] ?? '').toString();
    _upazila.text = (data['upazila'] ?? '').toString();
    _address.text = (data['address'] ?? '').toString();
    _checkIn.text = (data['check_in'] ?? '').toString();
    _checkOut.text = (data['check_out'] ?? '').toString();
    _rooms.text = (data['rooms_total'] ?? '').toString();
    _minPrice.text = (data['min_price'] ?? '').toString();
    _maxPrice.text = (data['max_price'] ?? '').toString();
    _description.text = (data['description'] ?? '').toString();
    _amenities.text = (data['amenities'] is List) ? (data['amenities'] as List).join(', ') : (data['amenities'] ?? '').toString();
    _services.text = (data['services'] is List) ? (data['services'] as List).join(', ') : (data['services'] ?? '').toString();
    _lat.text = (data['lat'] ?? '').toString();
    _lng.text = (data['lng'] ?? '').toString();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final res = await _api.get('/hotels/categories');
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
      final res = await _api.post('/hotels/register', body: {
        'category_id': _categoryId,
        'name': _name.text.trim(),
        'type': _type.text.trim().isEmpty ? null : _type.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'website': _website.text.trim(),
        'facebook': _facebook.text.trim(),
        'district': _district.text.trim(),
        'upazila': _upazila.text.trim(),
        'address': _address.text.trim(),
        'check_in': _checkIn.text.trim(),
        'check_out': _checkOut.text.trim(),
        'rooms_total': _rooms.text.trim(),
        'min_price': _minPrice.text.trim(),
        'max_price': _maxPrice.text.trim(),
        'amenities': _parseCsv(_amenities.text),
        'services': _parseCsv(_services.text),
        'description': _description.text.trim(),
        'lat': _lat.text.trim(),
        'lng': _lng.text.trim(),
      });

      final hotel = res is Map<String, dynamic> ? res['hotel'] : null;
      final hotelId = hotel is Map<String, dynamic> ? (hotel['id'] as num?)?.toInt() ?? 0 : 0;

      if (_selectedImage != null && hotelId > 0) {
        setState(() => _uploadingImage = true);
        await _api.postMultipart(
          '/media/upload',
          fields: {
            'section': 'hotel',
            'target_type': 'hotel',
            'target_id': hotelId.toString(),
            'set_primary': 'true',
          },
          files: {
            'images[]': [_selectedImage!.path],
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('হোটেল সংরক্ষণ হয়েছে')));
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
      appBar: const ModernAppBar(title: 'হোটেল যোগ/আপডেট', subtitle: 'তথ্য দিন'),
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
            _textField(_name, 'হোটেলের নাম', validator: (v) => (v == null || v.trim().isEmpty) ? 'নাম দিন' : null),
            const SizedBox(height: 10),
            _textField(_type, 'টাইপ (ঐচ্ছিক)'),
            const SizedBox(height: 14),
            _sectionTitle('যোগাযোগ'),
            _textField(_phone, 'ফোন নম্বর', keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _textField(_email, 'ইমেইল'),
            const SizedBox(height: 10),
            _textField(_website, 'ওয়েবসাইট'),
            const SizedBox(height: 10),
            _textField(_facebook, 'ফেসবুক পেজ'),
            const SizedBox(height: 14),
            _sectionTitle('ঠিকানা'),
            _textField(_district, 'জেলা'),
            const SizedBox(height: 10),
            _textField(_upazila, 'উপজেলা'),
            const SizedBox(height: 10),
            _textField(_address, 'পূর্ণ ঠিকানা', maxLines: 2),
            const SizedBox(height: 14),
            _sectionTitle('চেক-ইন/আউট'),
            Row(
              children: [
                Expanded(child: _textField(_checkIn, 'চেক-ইন সময়')),
                const SizedBox(width: 10),
                Expanded(child: _textField(_checkOut, 'চেক-আউট সময়')),
              ],
            ),
            const SizedBox(height: 14),
            _sectionTitle('রুম ও ভাড়া'),
            _textField(_rooms, 'রুম সংখ্যা', keyboard: TextInputType.number),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _textField(_minPrice, 'সর্বনিম্ন ভাড়া', keyboard: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _textField(_maxPrice, 'সর্বোচ্চ ভাড়া', keyboard: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 14),
            _sectionTitle('সুবিধা ও সেবা'),
            _textField(_amenities, 'সুবিধা (কমা দিয়ে লিখুন)', maxLines: 2),
            const SizedBox(height: 10),
            _textField(_services, 'সেবা (কমা দিয়ে লিখুন)', maxLines: 2),
            const SizedBox(height: 10),
            _textField(_description, 'বিবরণ', maxLines: 3),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _textField(_lat, 'ল্যাটিটিউড', keyboard: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 10),
                Expanded(child: _textField(_lng, 'লংিটিউড', keyboard: const TextInputType.numberWithOptions(decimal: true))),
              ],
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
