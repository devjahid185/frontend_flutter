import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class TeacherRequestFormScreen extends StatefulWidget {
  const TeacherRequestFormScreen({super.key});

  @override
  State<TeacherRequestFormScreen> createState() => _TeacherRequestFormScreenState();
}

class _TeacherRequestFormScreenState extends State<TeacherRequestFormScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _loadingCategories = true;

  int? _categoryId;
  List<Map<String, dynamic>> _categories = [];

  final TextEditingController _title = TextEditingController();
  final TextEditingController _classLevel = TextEditingController();
  final TextEditingController _medium = TextEditingController();
  final TextEditingController _mode = TextEditingController();
  final TextEditingController _daysPerWeek = TextEditingController();
  final TextEditingController _budget = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _upazila = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _title.dispose();
    _classLevel.dispose();
    _medium.dispose();
    _mode.dispose();
    _daysPerWeek.dispose();
    _budget.dispose();
    _district.dispose();
    _upazila.dispose();
    _address.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _api.post('/teacher-requests', body: {
        'category_id': _categoryId,
        'title': _title.text.trim(),
        'class_level': _classLevel.text.trim(),
        'medium': _medium.text.trim(),
        'mode': _mode.text.trim(),
        'days_per_week': _daysPerWeek.text.trim(),
        'budget': _budget.text.trim(),
        'district': _district.text.trim(),
        'upazila': _upazila.text.trim(),
        'address': _address.text.trim(),
        'phone': _phone.text.trim(),
        'notes': _notes.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রিকোয়েস্ট যোগ হয়েছে')));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রিকোয়েস্ট যোগ করা যায়নি')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(title: 'টিউশন রিকোয়েস্ট', subtitle: 'শিক্ষক খোঁজার অনুরোধ'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _categoryDropdown(),
            const SizedBox(height: 10),
            _textField(_title, 'কিসের টিউশন দরকার', validator: (v) => (v == null || v.trim().isEmpty) ? 'শিরোনাম দিন' : null),
            const SizedBox(height: 10),
            _textField(_classLevel, 'ক্লাস/লেভেল'),
            const SizedBox(height: 10),
            _textField(_medium, 'মাধ্যম'),
            const SizedBox(height: 10),
            _textField(_mode, 'মোড (অনলাইন/অফলাইন)'),
            const SizedBox(height: 10),
            _textField(_daysPerWeek, 'সপ্তাহে কয়দিন'),
            const SizedBox(height: 10),
            _textField(_budget, 'বাজেট (৳)', keyboard: TextInputType.number),
            const SizedBox(height: 10),
            _textField(_district, 'জেলা'),
            const SizedBox(height: 10),
            _textField(_upazila, 'উপজেলা'),
            const SizedBox(height: 10),
            _textField(_address, 'ঠিকানা', maxLines: 2),
            const SizedBox(height: 10),
            _textField(_phone, 'যোগাযোগ নম্বর', keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _textField(_notes, 'অতিরিক্ত তথ্য', maxLines: 3),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving ? const CircularProgressIndicator() : const Text('সাবমিট'),
            ),
          ],
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
