import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class CourierFormScreen extends StatefulWidget {
  const CourierFormScreen({super.key, this.initial});

  final Map<String, dynamic>? initial;

  @override
  State<CourierFormScreen> createState() => _CourierFormScreenState();
}

class _CourierFormScreenState extends State<CourierFormScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _company = TextEditingController();
  final TextEditingController _branch = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _upazila = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _phones = TextEditingController();
  final TextEditingController _hotline = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _website = TextEditingController();
  final TextEditingController _facebook = TextEditingController();
  final TextEditingController _services = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _applyInitial();
  }

  @override
  void dispose() {
    _company.dispose();
    _branch.dispose();
    _district.dispose();
    _upazila.dispose();
    _address.dispose();
    _phones.dispose();
    _hotline.dispose();
    _email.dispose();
    _website.dispose();
    _facebook.dispose();
    _services.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _applyInitial() {
    final data = widget.initial;
    if (data == null) return;
    _company.text = (data['company_name'] ?? '').toString();
    _branch.text = (data['name'] ?? '').toString();
    _district.text = (data['district'] ?? '').toString();
    _upazila.text = (data['upazila'] ?? '').toString();
    _address.text = (data['address'] ?? '').toString();
    _hotline.text = (data['hotline'] ?? '').toString();
    _email.text = (data['email'] ?? '').toString();
    _website.text = (data['website'] ?? '').toString();
    _facebook.text = (data['facebook'] ?? '').toString();
    _notes.text = (data['notes'] ?? '').toString();
    _phones.text = (data['phones'] is List)
        ? (data['phones'] as List).join(', ')
        : (data['phones'] ?? '').toString();
    _services.text = (data['services'] is List)
        ? (data['services'] as List).join(', ')
        : (data['services'] ?? '').toString();
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
      await _api.post(
        '/couriers/register',
        body: {
          'company_name': _company.text.trim(),
          'branch_name': _branch.text.trim(),
          'district': _district.text.trim(),
          'upazila': _upazila.text.trim(),
          'address': _address.text.trim(),
          'phones': _parseCsv(_phones.text),
          'hotline': _hotline.text.trim(),
          'email': _email.text.trim(),
          'website': _website.text.trim(),
          'facebook': _facebook.text.trim(),
          'services': _parseCsv(_services.text),
          'notes': _notes.text.trim(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('কুরিয়ার সংরক্ষণ হয়েছে')));
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'কুরিয়ার যোগ/আপডেট',
        subtitle: 'অফিস তথ্য',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _textField(
              _company,
              'কোম্পানি নাম',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'কোম্পানি দিন' : null,
            ),
            const SizedBox(height: 10),
            _textField(
              _branch,
              'ব্রাঞ্চ/অফিস নাম',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'ব্রাঞ্চ দিন' : null,
            ),
            const SizedBox(height: 10),
            _textField(_district, 'জেলা'),
            const SizedBox(height: 10),
            _textField(_upazila, 'উপজেলা'),
            const SizedBox(height: 10),
            _textField(_address, 'ঠিকানা', maxLines: 2),
            const SizedBox(height: 10),
            _textField(_phones, 'ফোন (কমা দিয়ে লিখুন)'),
            const SizedBox(height: 10),
            _textField(_hotline, 'হটলাইন'),
            const SizedBox(height: 10),
            _textField(_email, 'ইমেইল'),
            const SizedBox(height: 10),
            _textField(_website, 'ওয়েবসাইট'),
            const SizedBox(height: 10),
            _textField(_facebook, 'ফেসবুক পেজ'),
            const SizedBox(height: 10),
            _textField(_services, 'সেবা (কমা দিয়ে লিখুন)', maxLines: 2),
            const SizedBox(height: 10),
            _textField(_notes, 'নোট/বিস্তারিত', maxLines: 3),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
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

  Widget _textField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }
}
