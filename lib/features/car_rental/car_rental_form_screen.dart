import 'package:frontend_flutter/core/widgets/logo_loader.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/image_upload_preview.dart';
import '../common/modern_app_bar.dart';

class CarRentalFormScreen extends StatefulWidget {
  const CarRentalFormScreen({super.key, this.initial});

  final Map<String, dynamic>? initial;

  @override
  State<CarRentalFormScreen> createState() => _CarRentalFormScreenState();
}

class _CarRentalFormScreenState extends State<CarRentalFormScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _title = TextEditingController();
  final TextEditingController _brand = TextEditingController();
  final TextEditingController _model = TextEditingController();
  final TextEditingController _variant = TextEditingController();
  final TextEditingController _year = TextEditingController();
  final TextEditingController _seats = TextEditingController();
  final TextEditingController _doors = TextEditingController();
  final TextEditingController _color = TextEditingController();
  final TextEditingController _regNo = TextEditingController();
  final TextEditingController _priceDay = TextEditingController();
  final TextEditingController _priceHour = TextEditingController();
  final TextEditingController _priceKm = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _upazila = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _pickup = TextEditingController();
  final TextEditingController _dropoff = TextEditingController();
  final TextEditingController _contactName = TextEditingController();
  final TextEditingController _contactPhone = TextEditingController();
  final TextEditingController _features = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _terms = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  int? _categoryId;
  String? _fuel;
  String? _transmission;
  bool _driver = false;
  bool _ac = true;
  bool _gps = false;
  bool _delivery = false;
  bool _loadingCategories = true;
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
    _title.dispose();
    _brand.dispose();
    _model.dispose();
    _variant.dispose();
    _year.dispose();
    _seats.dispose();
    _doors.dispose();
    _color.dispose();
    _regNo.dispose();
    _priceDay.dispose();
    _priceHour.dispose();
    _priceKm.dispose();
    _district.dispose();
    _upazila.dispose();
    _address.dispose();
    _pickup.dispose();
    _dropoff.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    _features.dispose();
    _description.dispose();
    _terms.dispose();
    super.dispose();
  }

  void _applyInitial() {
    final data = widget.initial;
    if (data == null) return;
    _categoryId = (data['category_id'] as num?)?.toInt();
    _title.text = (data['title'] ?? '').toString();
    _brand.text = (data['brand'] ?? '').toString();
    _model.text = (data['model'] ?? '').toString();
    _variant.text = (data['variant'] ?? '').toString();
    _year.text = (data['year'] ?? '').toString();
    _fuel = (data['fuel_type'] ?? '').toString();
    _transmission = (data['transmission'] ?? '').toString();
    _seats.text = (data['seats'] ?? '').toString();
    _doors.text = (data['doors'] ?? '').toString();
    _color.text = (data['color'] ?? '').toString();
    _regNo.text = (data['reg_no'] ?? '').toString();
    _priceDay.text = (data['price_per_day'] ?? '').toString();
    _priceHour.text = (data['price_per_hour'] ?? '').toString();
    _priceKm.text = (data['price_per_km'] ?? '').toString();
    _district.text = (data['district'] ?? '').toString();
    _upazila.text = (data['upazila'] ?? '').toString();
    _address.text = (data['address'] ?? '').toString();
    _pickup.text = (data['pickup_location'] ?? '').toString();
    _dropoff.text = (data['dropoff_location'] ?? '').toString();
    _contactName.text = (data['contact_name'] ?? '').toString();
    _contactPhone.text = (data['contact_phone'] ?? '').toString();
    _features.text = (data['features'] is List)
        ? (data['features'] as List).join(', ')
        : (data['features'] ?? '').toString();
    _description.text = (data['description'] ?? '').toString();
    _terms.text = (data['terms'] ?? '').toString();
    _driver = data['driver_available'] == true || data['driver_available'] == 1;
    _ac = data['ac_available'] == true || data['ac_available'] == 1;
    _gps = data['gps_available'] == true || data['gps_available'] == 1;
    _delivery =
        data['delivery_available'] == true || data['delivery_available'] == 1;
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final res = await _api.get('/car-rentals/categories');
      _categories = (res as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) setState(() => _selectedImage = image);
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
      final res = await _api.post(
        '/car-rentals',
        body: {
          'category_id': _categoryId,
          'title': _title.text.trim(),
          'brand': _brand.text.trim(),
          'model': _model.text.trim(),
          'variant': _variant.text.trim(),
          'year': _year.text.trim(),
          'fuel_type': _fuel,
          'transmission': _transmission,
          'seats': _seats.text.trim(),
          'doors': _doors.text.trim(),
          'color': _color.text.trim(),
          'reg_no': _regNo.text.trim(),
          'price_per_day': _priceDay.text.trim(),
          'price_per_hour': _priceHour.text.trim(),
          'price_per_km': _priceKm.text.trim(),
          'driver_available': _driver,
          'ac_available': _ac,
          'gps_available': _gps,
          'delivery_available': _delivery,
          'district': _district.text.trim(),
          'upazila': _upazila.text.trim(),
          'address': _address.text.trim(),
          'pickup_location': _pickup.text.trim(),
          'dropoff_location': _dropoff.text.trim(),
          'contact_name': _contactName.text.trim(),
          'contact_phone': _contactPhone.text.trim(),
          'features': _parseCsv(_features.text),
          'description': _description.text.trim(),
          'terms': _terms.text.trim(),
        },
      );

      final rental = res is Map<String, dynamic> ? res['rental'] : null;
      final rentalId = rental is Map<String, dynamic>
          ? (rental['id'] as num?)?.toInt() ?? 0
          : 0;

      if (_selectedImage != null && rentalId > 0) {
        setState(() => _uploadingImage = true);
        await _api.postMultipart(
          '/media/upload',
          fields: {
            'section': 'car_rental',
            'target_type': 'car_rental',
            'target_id': rentalId.toString(),
            'set_primary': 'true',
          },
          files: {
            'images[]': [_selectedImage!.path],
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('গাড়ি সংরক্ষণ হয়েছে')));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('সংরক্ষণ করা যায়নি')));
    } finally {
      if (mounted) setState(() => _saving = false);
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(title: 'গাড়ি যোগ/আপডেট', subtitle: 'তথ্য দিন'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('ছবি'),
            _imagePicker(context),
            const SizedBox(height: 14),
            _sectionTitle('মৌলিক তথ্য'),
            _categoryDropdown(),
            const SizedBox(height: 10),
            _textField(
              _title,
              'শিরোনাম',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'শিরোনাম দিন' : null,
            ),
            const SizedBox(height: 10),
            _textField(_brand, 'ব্র্যান্ড'),
            const SizedBox(height: 10),
            _textField(_model, 'মডেল'),
            const SizedBox(height: 10),
            _textField(_variant, 'ভ্যারিয়েন্ট'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    _year,
                    'সাল',
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _textField(
                    _seats,
                    'সিট',
                    keyboard: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    _doors,
                    'দরজা',
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _textField(_color, 'রং')),
              ],
            ),
            const SizedBox(height: 10),
            _textField(_regNo, 'রেজি নম্বর (ঐচ্ছিক)'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _fuel,
              decoration: const InputDecoration(labelText: 'ফুয়েল'),
              items: const [
                'পেট্রোল',
                'ডিজেল',
                'সিএনজি',
                'অকটেন',
                'ইলেকট্রিক',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) => setState(() => _fuel = value),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _transmission,
              decoration: const InputDecoration(labelText: 'ট্রান্সমিশন'),
              items: const [
                'ম্যানুয়াল',
                'অটো',
                'সেমি-অটো',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) => setState(() => _transmission = value),
            ),
            const SizedBox(height: 14),
            _sectionTitle('ভাড়া'),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    _priceDay,
                    'প্রতি দিন',
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _textField(
                    _priceHour,
                    'প্রতি ঘণ্টা',
                    keyboard: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _textField(
              _priceKm,
              'প্রতি কিমি (ঐচ্ছিক)',
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 14),
            _sectionTitle('লোকেশন'),
            _textField(_district, 'জেলা'),
            const SizedBox(height: 10),
            _textField(_upazila, 'উপজেলা'),
            const SizedBox(height: 10),
            _textField(_address, 'ঠিকানা', maxLines: 2),
            const SizedBox(height: 10),
            _textField(_pickup, 'পিকআপ লোকেশন'),
            const SizedBox(height: 10),
            _textField(_dropoff, 'ড্রপ লোকেশন'),
            const SizedBox(height: 14),
            _sectionTitle('যোগাযোগ'),
            _textField(_contactName, 'যোগাযোগের নাম'),
            const SizedBox(height: 10),
            _textField(
              _contactPhone,
              'মোবাইল নম্বর',
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _sectionTitle('ফিচার/শর্ত'),
            _textField(_features, 'ফিচার (কমা দিয়ে লিখুন)', maxLines: 2),
            const SizedBox(height: 10),
            _textField(_description, 'বিবরণ', maxLines: 3),
            const SizedBox(height: 10),
            _textField(_terms, 'শর্তাবলি', maxLines: 3),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _driver,
              onChanged: (v) => setState(() => _driver = v),
              title: const Text('চালক পাওয়া যাবে'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _ac,
              onChanged: (v) => setState(() => _ac = v),
              title: const Text('এসি আছে'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _gps,
              onChanged: (v) => setState(() => _gps = v),
              title: const Text('জিপিএস আছে'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _delivery,
              onChanged: (v) => setState(() => _delivery = v),
              title: const Text('ডোরস্টেপ ডেলিভারি'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving || _uploadingImage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: LogoLoader(size: 18),
                    )
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
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }

  Widget _imagePicker(BuildContext context) {
    return PickedImageHeroPreview(
      image: _selectedImage,
      onTap: _pickImage,
      onRemove: _selectedImage == null
          ? null
          : () => setState(() => _selectedImage = null),
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<int>(
      value: _categoryId,
      decoration: const InputDecoration(labelText: 'ক্যাটাগরি'),
      items: _categories
          .map(
            (c) => DropdownMenuItem<int>(
              value: (c['id'] as num?)?.toInt(),
              child: Text(c['name']?.toString() ?? ''),
            ),
          )
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
