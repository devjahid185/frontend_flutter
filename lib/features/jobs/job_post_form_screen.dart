import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class JobPostFormScreen extends StatefulWidget {
  const JobPostFormScreen({super.key, required this.postType});

  final String postType;

  @override
  State<JobPostFormScreen> createState() => _JobPostFormScreenState();
}

class _JobPostFormScreenState extends State<JobPostFormScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _title = TextEditingController();
  final TextEditingController _company = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _salaryMin = TextEditingController();
  final TextEditingController _salaryMax = TextEditingController();
  final TextEditingController _vacancies = TextEditingController();
  final TextEditingController _deadline = TextEditingController();
  final TextEditingController _education = TextEditingController();
  final TextEditingController _locationType = TextEditingController();
  final TextEditingController _companyWebsite = TextEditingController();
  final TextEditingController _companySize = TextEditingController();
  final TextEditingController _ageMin = TextEditingController();
  final TextEditingController _ageMax = TextEditingController();
  final TextEditingController _contactPhone = TextEditingController();
  final TextEditingController _contactEmail = TextEditingController();
  final TextEditingController _responsibilities = TextEditingController();
  final TextEditingController _requirements = TextEditingController();
  final TextEditingController _benefits = TextEditingController();

  String? _employmentType;
  String? _experience;
  String? _gender;
  String? _categoryId;
  bool _negotiable = false;
  bool _saving = false;

  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await _api.get('/jobs/categories');
      setState(
        () => _categories = (res as List?)?.cast<Map<String, dynamic>>() ?? [],
      );
    } catch (_) {
      setState(() => _categories = []);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _company.dispose();
    _description.dispose();
    _location.dispose();
    _salaryMin.dispose();
    _salaryMax.dispose();
    _vacancies.dispose();
    _deadline.dispose();
    _education.dispose();
    _locationType.dispose();
    _companyWebsite.dispose();
    _companySize.dispose();
    _ageMin.dispose();
    _ageMax.dispose();
    _contactPhone.dispose();
    _contactEmail.dispose();
    _responsibilities.dispose();
    _requirements.dispose();
    _benefits.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _deadline.text = picked.toIso8601String().substring(0, 10);
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await _api.post(
        '/jobs/post',
        body: {
          'post_type': widget.postType,
          'category_id': _categoryId,
          'title': _title.text.trim(),
          'company': _company.text.trim(),
          'description': _description.text.trim(),
          'location': _location.text.trim(),
          'salary_min': _salaryMin.text.trim(),
          'salary_max': _salaryMax.text.trim(),
          'negotiable': _negotiable,
          'employment_type': _employmentType,
          'experience_level': _experience,
          'education': _education.text.trim(),
          'vacancies': _vacancies.text.trim(),
          'deadline': _deadline.text.trim(),
          'location_type': _locationType.text.trim(),
          'contact_phone': _contactPhone.text.trim(),
          'contact_email': _contactEmail.text.trim(),
          'company_website': _companyWebsite.text.trim(),
          'company_size': _companySize.text.trim(),
          'responsibilities': _responsibilities.text.trim(),
          'requirements': _requirements.text.trim(),
          'benefits': _benefits.text.trim(),
          'gender': _gender,
          'age_min': _ageMin.text.trim(),
          'age_max': _ageMax.text.trim(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('জব পোস্ট হয়েছে')));
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
        ).showSnackBar(const SnackBar(content: Text('পোস্ট হয়নি')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: widget.postType == 'hiring' ? 'চাকরি পোস্ট' : 'জব সিকার পোস্ট',
        subtitle: 'সঠিক তথ্য দিন',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _dropdown(
              label: 'ক্যাটাগরি',
              value: _categoryId,
              items: _categories
                  .map(
                    (e) => DropdownMenuItem(
                      value: e['id'].toString(),
                      child: Text(e['name'].toString()),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _categoryId = value),
            ),
            const SizedBox(height: 10),
            _textField(_title, 'শিরোনাম', required: true),
            const SizedBox(height: 10),
            _textField(
              _company,
              widget.postType == 'hiring' ? 'কোম্পানি' : 'নাম',
              required: true,
            ),
            const SizedBox(height: 10),
            _textField(_description, 'বিবরণ', maxLines: 3, required: true),
            const SizedBox(height: 10),
            _textField(_location, 'কর্মস্থল/ঠিকানা (যেমন: বনানী, ঢাকা)'),
            const SizedBox(height: 10),
            _textField(_locationType, 'কাজের ধরন (রিমোট/অফিসে/হাইব্রিড)'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    _salaryMin,
                    'সর্বনিম্ন বেতন',
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _textField(
                    _salaryMax,
                    'সর্বোচ্চ বেতন',
                    keyboard: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _negotiable,
              onChanged: (value) => setState(() => _negotiable = value),
              title: const Text('বেতন আলোচনা সাপেক্ষ'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _dropdown(
                    label: 'জব টাইপ',
                    value: _employmentType,
                    items: const [
                      DropdownMenuItem(
                        value: 'full_time',
                        child: Text('ফুল টাইম'),
                      ),
                      DropdownMenuItem(
                        value: 'part_time',
                        child: Text('পার্ট টাইম'),
                      ),
                      DropdownMenuItem(
                        value: 'contract',
                        child: Text('কন্ট্রাক্ট'),
                      ),
                      DropdownMenuItem(
                        value: 'intern',
                        child: Text('ইন্টার্ন'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _employmentType = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dropdown(
                    label: 'অভিজ্ঞতা',
                    value: _experience,
                    items: const [
                      DropdownMenuItem(value: 'entry', child: Text('এন্ট্রি')),
                      DropdownMenuItem(value: 'mid', child: Text('মিড')),
                      DropdownMenuItem(value: 'senior', child: Text('সিনিয়র')),
                    ],
                    onChanged: (value) => setState(() => _experience = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _textField(_education, 'শিক্ষাগত যোগ্যতা'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    _vacancies,
                    'ভ্যাকেন্সি',
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDeadline,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      _deadline.text.isEmpty ? 'ডেডলাইন' : _deadline.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _dropdown(
              label: 'লিঙ্গ (ঐচ্ছিক)',
              value: _gender,
              items: const [
                DropdownMenuItem(value: 'male', child: Text('পুরুষ')),
                DropdownMenuItem(value: 'female', child: Text('নারী')),
                DropdownMenuItem(value: 'any', child: Text('যেকোনো')),
              ],
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    _ageMin,
                    'বয়স (সর্বনিম্ন)',
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _textField(
                    _ageMax,
                    'বয়স (সর্বোচ্চ)',
                    keyboard: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _textField(_responsibilities, 'দায়িত্বসমূহ', maxLines: 3),
            const SizedBox(height: 10),
            _textField(_requirements, 'চাহিদা/যোগ্যতা', maxLines: 3),
            const SizedBox(height: 10),
            _textField(_benefits, 'সুবিধা', maxLines: 2),
            const SizedBox(height: 10),
            _textField(
              _contactPhone,
              'যোগাযোগ নম্বর',
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            _textField(
              _contactEmail,
              'ইমেইল',
              keyboard: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            _textField(_companyWebsite, 'ওয়েবসাইট'),
            const SizedBox(height: 10),
            _textField(_companySize, 'কোম্পানির আকার'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: LogoLoader(size: 18),
                    )
                  : const Text('পোস্ট করুন'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    int maxLines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (value) =>
                (value == null || value.trim().isEmpty) ? 'প্রয়োজনীয়' : null
          : null,
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
