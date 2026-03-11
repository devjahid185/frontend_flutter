import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class BloodRequestFormScreen extends StatefulWidget {
  const BloodRequestFormScreen({super.key});

  @override
  State<BloodRequestFormScreen> createState() => _BloodRequestFormScreenState();
}

class _BloodRequestFormScreenState extends State<BloodRequestFormScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _patientName = TextEditingController();
  final TextEditingController _units = TextEditingController(text: '1');
  final TextEditingController _hospital = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _upazila = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _note = TextEditingController();

  String? _bloodGroup;
  DateTime? _neededAt;
  bool _saving = false;

  @override
  void dispose() {
    _patientName.dispose();
    _units.dispose();
    _hospital.dispose();
    _district.dispose();
    _upazila.dispose();
    _location.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _neededAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _neededAt = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await _api.post('/blood-requests', body: {
        'patient_name': _patientName.text.trim(),
        'blood_group': _bloodGroup,
        'units': _units.text.trim(),
        'needed_at': _neededAt?.toIso8601String().substring(0, 10),
        'hospital': _hospital.text.trim(),
        'district': _district.text.trim(),
        'upazila': _upazila.text.trim(),
        'location': _location.text.trim(),
        'contact_phone': _phone.text.trim(),
        'note': _note.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('অনুরোধ পোস্ট হয়েছে')));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('অনুরোধ পোস্ট হয়নি')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(title: 'রক্তের অনুরোধ', subtitle: 'রোগীর জন্য পোস্ট করুন'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _textField(_patientName, 'রোগীর নাম'),
            const SizedBox(height: 10),
            _dropdown(
              label: 'রক্তের গ্রুপ',
              value: _bloodGroup,
              items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
              onChanged: (value) => setState(() => _bloodGroup = value),
              validator: (value) => (value == null || value.isEmpty) ? 'রক্তের গ্রুপ দিন' : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _textField(_units, 'ইউনিট', keyboard: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_neededAt == null ? 'তারিখ' : _neededAt!.toIso8601String().substring(0, 10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _textField(_hospital, 'হাসপাতাল'),
            const SizedBox(height: 10),
            _textField(_district, 'জেলা'),
            const SizedBox(height: 10),
            _textField(_upazila, 'উপজেলা'),
            const SizedBox(height: 10),
            _textField(_location, 'লোকেশন', maxLines: 2),
            const SizedBox(height: 10),
            _textField(_phone, 'যোগাযোগ নম্বর', keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _textField(_note, 'নোট (ঐচ্ছিক)', maxLines: 2),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('পোস্ট করুন'),
            ),
          ],
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
