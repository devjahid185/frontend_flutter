import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class ElectricityOfficeFormScreen extends StatefulWidget {
  const ElectricityOfficeFormScreen({super.key, this.initial});

  final Map<String, dynamic>? initial;

  @override
  State<ElectricityOfficeFormScreen> createState() => _ElectricityOfficeFormScreenState();
}

class _ElectricityOfficeFormScreenState extends State<ElectricityOfficeFormScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _name =
      TextEditingController(text: widget.initial?['name']?.toString() ?? '');
  late final TextEditingController _provider =
      TextEditingController(text: widget.initial?['provider']?.toString() ?? '');
  late final TextEditingController _officeType =
      TextEditingController(text: widget.initial?['office_type']?.toString() ?? '');
  late final TextEditingController _district =
      TextEditingController(text: widget.initial?['district']?.toString() ?? '');
  late final TextEditingController _upazila =
      TextEditingController(text: widget.initial?['upazila']?.toString() ?? '');
  late final TextEditingController _address =
      TextEditingController(text: widget.initial?['address']?.toString() ?? '');
  late final TextEditingController _phones =
      TextEditingController(text: (widget.initial?['phones'] as List?)?.join(', ') ?? '');
  late final TextEditingController _hotline =
      TextEditingController(text: widget.initial?['hotline']?.toString() ?? '');
  late final TextEditingController _email =
      TextEditingController(text: widget.initial?['email']?.toString() ?? '');
  late final TextEditingController _website =
      TextEditingController(text: widget.initial?['website']?.toString() ?? '');
  late final TextEditingController _notes =
      TextEditingController(text: widget.initial?['notes']?.toString() ?? '');
  late final TextEditingController _lat =
      TextEditingController(text: widget.initial?['lat']?.toString() ?? '');
  late final TextEditingController _lng =
      TextEditingController(text: widget.initial?['lng']?.toString() ?? '');

  @override
  void dispose() {
    _name.dispose();
    _provider.dispose();
    _officeType.dispose();
    _district.dispose();
    _upazila.dispose();
    _address.dispose();
    _phones.dispose();
    _hotline.dispose();
    _email.dispose();
    _website.dispose();
    _notes.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final phones = _phones.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final body = <String, dynamic>{
        if (widget.initial?['id'] != null) 'id': widget.initial!['id'],
        'name': _name.text.trim(),
        'provider': _provider.text.trim().isEmpty ? null : _provider.text.trim(),
        'office_type': _officeType.text.trim().isEmpty ? null : _officeType.text.trim(),
        'district': _district.text.trim().isEmpty ? null : _district.text.trim(),
        'upazila': _upazila.text.trim().isEmpty ? null : _upazila.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'phones': phones.isEmpty ? null : phones,
        'hotline': _hotline.text.trim().isEmpty ? null : _hotline.text.trim(),
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
        'website': _website.text.trim().isEmpty ? null : _website.text.trim(),
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        'lat': _lat.text.trim().isEmpty ? null : double.tryParse(_lat.text.trim()),
        'lng': _lng.text.trim().isEmpty ? null : double.tryParse(_lng.text.trim()),
      };

      await _api.post('/electricity/register', body: body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('তথ্য সংরক্ষণ হয়েছে')));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সংরক্ষণ করা যায়নি')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(title: 'বিদ্যুৎ অফিস', subtitle: 'অফিস যোগ করুন'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_name, 'অফিসের নাম', required: true),
            _field(_provider, 'প্রোভাইডার (REB ইত্যাদি)'),
            _field(_officeType, 'অফিস টাইপ (সমিতি অফিস/উপকেন্দ্র)'),
            _field(_district, 'জেলা'),
            _field(_upazila, 'উপজেলা'),
            _field(_address, 'ঠিকানা'),
            _field(_phones, 'ফোন নম্বর (কমা দিয়ে আলাদা করুন)'),
            _field(_hotline, 'হটলাইন'),
            _field(_email, 'ইমেইল', inputType: TextInputType.emailAddress),
            _field(_website, 'ওয়েবসাইট', inputType: TextInputType.url),
            _field(_notes, 'নোট/সার্ভিস বিবরণ', maxLines: 3),
            Row(
              children: [
                Expanded(child: _field(_lat, 'Latitude', inputType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _field(_lng, 'Longitude', inputType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: scheme.primary),
              child: _saving ? const CircularProgressIndicator() : const Text('সাবমিট'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? inputType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: inputType,
        validator: required
            ? (value) => value == null || value.trim().isEmpty ? 'এই ঘরটি প্রয়োজন' : null
            : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
