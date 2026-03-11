import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class PropertyPostFormScreen extends StatefulWidget {
  const PropertyPostFormScreen({super.key, this.initial});

  final Map<String, dynamic>? initial;

  @override
  State<PropertyPostFormScreen> createState() => _PropertyPostFormScreenState();
}

class _PropertyPostFormScreenState extends State<PropertyPostFormScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _title = TextEditingController();
  final TextEditingController _type = TextEditingController();
  final TextEditingController _propertyType = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _pricePerSqft = TextEditingController();
  final TextEditingController _bedrooms = TextEditingController();
  final TextEditingController _bathrooms = TextEditingController();
  final TextEditingController _area = TextEditingController();
  final TextEditingController _areaUnit = TextEditingController(text: 'sqft');
  final TextEditingController _floor = TextEditingController();
  final TextEditingController _totalFloors = TextEditingController();
  final TextEditingController _facing = TextEditingController();
  final TextEditingController _yearBuilt = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _upazila = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _locationType = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _contactName = TextEditingController();
  final TextEditingController _contactPhone = TextEditingController();
  final TextEditingController _contactEmail = TextEditingController();
  final TextEditingController _contactWebsite = TextEditingController();
  final TextEditingController _amenities = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  String? _categoryId;
  String _purpose = 'rent';
  bool _furnished = false;
  bool _parking = false;
  bool _negotiable = false;
  bool _saving = false;

  List<XFile> _images = [];

  int get _propertyId => (widget.initial?['id'] as num?)?.toInt() ?? 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _prefill();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await _api.get('/properties/categories');
      setState(() => _categories = (res as List?)?.cast<Map<String, dynamic>>() ?? []);
    } catch (_) {
      setState(() => _categories = []);
    }
  }

  void _prefill() {
    final data = widget.initial;
    if (data == null) return;
    _categoryId = data['category_id']?.toString();
    _purpose = (data['purpose'] ?? 'rent').toString();
    _title.text = (data['title'] ?? '').toString();
    _type.text = (data['type'] ?? '').toString();
    _propertyType.text = (data['property_type'] ?? '').toString();
    _price.text = (data['price'] ?? '').toString();
    _pricePerSqft.text = (data['price_per_sqft'] ?? '').toString();
    _bedrooms.text = (data['bedrooms'] ?? '').toString();
    _bathrooms.text = (data['bathrooms'] ?? '').toString();
    _area.text = (data['area'] ?? '').toString();
    _areaUnit.text = (data['area_unit'] ?? 'sqft').toString();
    _floor.text = (data['floor'] ?? '').toString();
    _totalFloors.text = (data['total_floors'] ?? '').toString();
    _furnished = data['furnished'] == true || data['furnished'] == 1;
    _parking = data['parking'] == true || data['parking'] == 1;
    _facing.text = (data['facing'] ?? '').toString();
    _yearBuilt.text = (data['year_built'] ?? '').toString();
    _negotiable = data['negotiable'] == true || data['negotiable'] == 1;
    _district.text = (data['district'] ?? '').toString();
    _upazila.text = (data['upazila'] ?? '').toString();
    _address.text = (data['address'] ?? '').toString();
    _location.text = (data['location'] ?? '').toString();
    _locationType.text = (data['location_type'] ?? '').toString();
    _description.text = (data['description'] ?? '').toString();
    _contactName.text = (data['contact_name'] ?? '').toString();
    _contactPhone.text = (data['contact_phone'] ?? data['contact'] ?? '').toString();
    _contactEmail.text = (data['contact_email'] ?? '').toString();
    _contactWebsite.text = (data['contact_website'] ?? '').toString();
    if (data['amenities'] is List) {
      _amenities.text = (data['amenities'] as List).map((e) => e.toString()).join(', ');
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _type.dispose();
    _propertyType.dispose();
    _price.dispose();
    _pricePerSqft.dispose();
    _bedrooms.dispose();
    _bathrooms.dispose();
    _area.dispose();
    _areaUnit.dispose();
    _floor.dispose();
    _totalFloors.dispose();
    _facing.dispose();
    _yearBuilt.dispose();
    _district.dispose();
    _upazila.dispose();
    _address.dispose();
    _location.dispose();
    _locationType.dispose();
    _description.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    _contactEmail.dispose();
    _contactWebsite.dispose();
    _amenities.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isNotEmpty) {
      setState(() => _images = files);
    }
  }

  List<String> _amenitiesList() {
    return _amenities.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final body = {
        'category_id': _categoryId,
        'purpose': _purpose,
        'title': _title.text.trim(),
        'type': _type.text.trim(),
        'property_type': _propertyType.text.trim(),
        'price': _price.text.trim(),
        'price_per_sqft': _pricePerSqft.text.trim(),
        'negotiable': _negotiable,
        'bedrooms': _bedrooms.text.trim(),
        'bathrooms': _bathrooms.text.trim(),
        'area': _area.text.trim(),
        'area_unit': _areaUnit.text.trim(),
        'floor': _floor.text.trim(),
        'total_floors': _totalFloors.text.trim(),
        'furnished': _furnished,
        'parking': _parking,
        'facing': _facing.text.trim(),
        'year_built': _yearBuilt.text.trim(),
        'district': _district.text.trim(),
        'upazila': _upazila.text.trim(),
        'address': _address.text.trim(),
        'location': _location.text.trim(),
        'location_type': _locationType.text.trim(),
        'description': _description.text.trim(),
        'contact_name': _contactName.text.trim(),
        'contact_phone': _contactPhone.text.trim(),
        'contact_email': _contactEmail.text.trim(),
        'contact_website': _contactWebsite.text.trim(),
        'amenities': _amenitiesList(),
      };

      final res = _propertyId > 0
          ? await _api.post('/properties/$_propertyId/update', body: body)
          : await _api.post('/properties/add', body: body);

      final property = res is Map<String, dynamic> ? res['property'] : null;
      final propertyId = property is Map<String, dynamic> ? (property['id'] as num?)?.toInt() ?? _propertyId : _propertyId;

      if (_images.isNotEmpty && propertyId > 0) {
        await _api.postMultipart(
          '/media/upload',
          fields: {
            'section': 'property',
            'target_type': 'property',
            'target_id': propertyId.toString(),
            'set_primary': 'true',
          },
          files: {
            'images[]': _images.map((e) => e.path).toList(),
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('প্রোপার্টি সংরক্ষণ হয়েছে')));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সংরক্ষণ হয়নি')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: _propertyId > 0 ? 'প্রোপার্টি আপডেট' : 'প্রোপার্টি পোস্ট',
        subtitle: 'ভাড়া/বিক্রয়',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('ছবি'),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.image_outlined),
              label: Text(_images.isEmpty ? 'ছবি যোগ করুন' : '${_images.length} টি ছবি নির্বাচিত'),
            ),
            const SizedBox(height: 14),
            _section('মূল তথ্য'),
            _dropdown(
              label: 'ক্যাটাগরি',
              value: _categoryId,
              items: _categories.map((e) => DropdownMenuItem(value: e['id'].toString(), child: Text(e['name'].toString()))).toList(),
              onChanged: (value) => setState(() => _categoryId = value),
            ),
            const SizedBox(height: 10),
            _dropdown(
              label: 'ধরণ',
              value: _purpose,
              items: const [
                DropdownMenuItem(value: 'rent', child: Text('ভাড়া')),
                DropdownMenuItem(value: 'sell', child: Text('বিক্রয়')),
              ],
              onChanged: (value) => setState(() => _purpose = value ?? 'rent'),
            ),
            const SizedBox(height: 10),
            _textField(_title, 'শিরোনাম', required: true),
            const SizedBox(height: 10),
            _textField(_type, 'প্রোপার্টি টাইপ', required: true),
            const SizedBox(height: 10),
            _textField(_propertyType, 'উপ-টাইপ (ঐচ্ছিক)'),
            const SizedBox(height: 10),
            _textField(_price, 'মূল্য', keyboard: TextInputType.number, required: true),
            const SizedBox(height: 10),
            _textField(_pricePerSqft, 'দাম/স্কয়ারফিট', keyboard: TextInputType.number),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _negotiable,
              onChanged: (value) => setState(() => _negotiable = value),
              title: const Text('দাম আলোচনা সাপেক্ষ'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            _section('বিস্তারিত'),
            Row(
              children: [
                Expanded(child: _textField(_bedrooms, 'বেডরুম', keyboard: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _textField(_bathrooms, 'বাথরুম', keyboard: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _textField(_area, 'এলাকা', keyboard: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _textField(_areaUnit, 'ইউনিট (sqft/katha)')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _textField(_floor, 'ফ্লোর', keyboard: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _textField(_totalFloors, 'মোট ফ্লোর', keyboard: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _furnished,
              onChanged: (value) => setState(() => _furnished = value),
              title: const Text('ফার্নিশড'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _parking,
              onChanged: (value) => setState(() => _parking = value),
              title: const Text('পার্কিং'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            _textField(_facing, 'ফেসিং'),
            const SizedBox(height: 10),
            _textField(_yearBuilt, 'নির্মাণ বছর', keyboard: TextInputType.number),
            const SizedBox(height: 10),
            _textField(_amenities, 'সুবিধা (কমা দিয়ে লিখুন)'),
            const SizedBox(height: 10),
            _section('ঠিকানা'),
            _textField(_district, 'জেলা'),
            const SizedBox(height: 10),
            _textField(_upazila, 'উপজেলা'),
            const SizedBox(height: 10),
            _textField(_address, 'ঠিকানা', maxLines: 2),
            const SizedBox(height: 10),
            _textField(_location, 'এলাকা/লোকেশন', maxLines: 2),
            const SizedBox(height: 10),
            _textField(_locationType, 'লোকেশন টাইপ (রিমোট/অন-সাইট/হাইব্রিড)'),
            const SizedBox(height: 10),
            _section('যোগাযোগ'),
            _textField(_contactName, 'যোগাযোগের নাম'),
            const SizedBox(height: 10),
            _textField(_contactPhone, 'ফোন নম্বর', keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _textField(_contactEmail, 'ইমেইল', keyboard: TextInputType.emailAddress),
            const SizedBox(height: 10),
            _textField(_contactWebsite, 'ওয়েবসাইট'),
            const SizedBox(height: 10),
            _textField(_description, 'বিবরণ', maxLines: 3),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('সংরক্ষণ করুন'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
    );
  }

  Widget _textField(TextEditingController controller, String label,
      {TextInputType? keyboard, int maxLines = 1, bool required = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
      validator: required ? (value) => (value == null || value.trim().isEmpty) ? 'প্রয়োজনীয়' : null : null,
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
    );
  }
}
