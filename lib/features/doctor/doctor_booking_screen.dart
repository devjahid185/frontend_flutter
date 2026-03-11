import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class DoctorBookingScreen extends StatefulWidget {
  const DoctorBookingScreen({super.key, required this.doctorId});

  final int doctorId;

  @override
  State<DoctorBookingScreen> createState() => _DoctorBookingScreenState();
}

class _DoctorBookingScreenState extends State<DoctorBookingScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _patientName = TextEditingController();
  final TextEditingController _age = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _problem = TextEditingController();
  final TextEditingController _note = TextEditingController();

  String? _gender;
  DateTime? _date;
  TimeOfDay? _time;
  bool _saving = false;

  @override
  void dispose() {
    _patientName.dispose();
    _age.dispose();
    _phone.dispose();
    _problem.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now());
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('অ্যাপয়েন্টমেন্ট তারিখ দিন')));
      return;
    }

    setState(() => _saving = true);
    try {
      final dateStr = _date!.toIso8601String().substring(0, 10);
      final timeStr = _time == null
          ? null
          : _time!.hour.toString().padLeft(2, '0') + ':' + _time!.minute.toString().padLeft(2, '0');

      await _api.post('/doctor-appointments', body: {
        'doctor_id': widget.doctorId,
        'patient_name': _patientName.text.trim(),
        'patient_age': _age.text.trim(),
        'patient_gender': _gender,
        'contact_phone': _phone.text.trim(),
        'appointment_date': dateStr,
        'appointment_time': timeStr,
        'problem': _problem.text.trim(),
        'note': _note.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('অ্যাপয়েন্টমেন্ট বুক হয়েছে')));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('বুক করা যায়নি')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _date == null ? 'তারিখ বাছুন' : _date!.toIso8601String().substring(0, 10);
    final timeLabel = _time == null
        ? 'সময় বাছুন'
        : _time!.hour.toString().padLeft(2, '0') + ':' + _time!.minute.toString().padLeft(2, '0');

    return Scaffold(
      appBar: const ModernAppBar(title: 'অ্যাপয়েন্টমেন্ট', subtitle: 'রোগীর তথ্য দিন'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _patientName,
              decoration: const InputDecoration(labelText: 'রোগীর নাম'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'রোগীর নাম দিন' : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _age,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'বয়স'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(labelText: 'লিঙ্গ'),
                    items: const ['পুরুষ', 'নারী', 'অন্যান্য']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'যোগাযোগ নম্বর'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.date_range),
                    label: Text(dateLabel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(timeLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _problem,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'সমস্যা/উপসর্গ'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'অতিরিক্ত নোট (ঐচ্ছিক)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('বুক করুন'),
            ),
            const SizedBox(height: 10),
            const Text('তারিখ ও সময় ঠিক থাকলে বুক করুন।', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
