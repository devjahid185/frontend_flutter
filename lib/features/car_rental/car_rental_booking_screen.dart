import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class CarRentalBookingScreen extends StatefulWidget {
  const CarRentalBookingScreen({super.key, required this.rentalId});

  final int rentalId;

  @override
  State<CarRentalBookingScreen> createState() => _CarRentalBookingScreenState();
}

class _CarRentalBookingScreenState extends State<CarRentalBookingScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _pickup = TextEditingController();
  final TextEditingController _dropoff = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final TextEditingController _price = TextEditingController();

  DateTime? _start;
  DateTime? _end;
  bool _driver = false;
  bool _saving = false;

  @override
  void dispose() {
    _pickup.dispose();
    _dropoff.dispose();
    _phone.dispose();
    _note.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end ?? _start ?? DateTime.now(),
      firstDate: _start ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _end = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_start == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('শুরুর তারিখ দিন')));
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.post(
        '/car-rental-bookings',
        body: {
          'car_rental_id': widget.rentalId,
          'start_date': _start!.toIso8601String().substring(0, 10),
          'end_date': _end?.toIso8601String().substring(0, 10),
          'pickup_location': _pickup.text.trim(),
          'dropoff_location': _dropoff.text.trim(),
          'need_driver': _driver,
          'contact_phone': _phone.text.trim(),
          'note': _note.text.trim(),
          'total_price': _price.text.trim(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('বুকিং পাঠানো হয়েছে')));
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
        ).showSnackBar(const SnackBar(content: Text('বুকিং হয়নি')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'গাড়ি বুকিং',
        subtitle: 'তারিখ ও লোকেশন দিন',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickStart,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _start == null
                          ? 'শুরুর তারিখ'
                          : _start!.toIso8601String().substring(0, 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickEnd,
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(
                      _end == null
                          ? 'শেষ তারিখ'
                          : _end!.toIso8601String().substring(0, 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _pickup,
              decoration: const InputDecoration(labelText: 'পিকআপ লোকেশন'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _dropoff,
              decoration: const InputDecoration(labelText: 'ড্রপ লোকেশন'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'যোগাযোগ নম্বর'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _price,
              decoration: const InputDecoration(
                labelText: 'সম্ভাব্য ভাড়া (ঐচ্ছিক)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _driver,
              onChanged: (v) => setState(() => _driver = v),
              title: const Text('চালক প্রয়োজন'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'নোট (ঐচ্ছিক)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: LogoLoader(size: 18),
                    )
                  : const Text('বুকিং পাঠান'),
            ),
          ],
        ),
      ),
    );
  }
}
