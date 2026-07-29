import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class LaunchFormScreen extends StatefulWidget {
  const LaunchFormScreen({super.key, this.initial});

  final Map<String, dynamic>? initial;

  @override
  State<LaunchFormScreen> createState() => _LaunchFormScreenState();
}

class _LaunchFormScreenState extends State<LaunchFormScreen> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _cabin = true;
  bool _ac = false;
  bool _food = true;
  bool _online = false;

  late final _name = TextEditingController(text: _v('name'));
  late final _operator = TextEditingController(text: _v('operator_name'));
  late final _from = TextEditingController(text: _v('route_from'));
  late final _to = TextEditingController(text: _v('route_to'));
  late final _departTerminal = TextEditingController(text: _v('departure_terminal'));
  late final _arrivalTerminal = TextEditingController(text: _v('arrival_terminal'));
  late final _departTime = TextEditingController(text: _time('departure_time'));
  late final _arrivalTime = TextEditingController(text: _time('arrival_time'));
  late final _days = TextEditingController(text: _v('running_days'));
  late final _deckFare = TextEditingController(text: _v('deck_fare'));
  late final _chairFare = TextEditingController(text: _v('chair_fare'));
  late final _singleCabin = TextEditingController(text: _v('single_cabin_fare'));
  late final _doubleCabin = TextEditingController(text: _v('double_cabin_fare'));
  late final _phones = TextEditingController(text: (widget.initial?['phones'] as List?)?.join(', ') ?? '');
  late final _hotline = TextEditingController(text: _v('hotline'));
  late final _website = TextEditingController(text: _v('website'));
  late final _district = TextEditingController(text: _v('district'));
  late final _upazila = TextEditingController(text: _v('upazila'));
  late final _address = TextEditingController(text: _v('address'));
  late final _description = TextEditingController(text: _v('description'));
  late final _notes = TextEditingController(text: _v('notes'));

  @override
  void initState() {
    super.initState();
    final data = widget.initial;
    if (data != null) {
      _cabin = data['has_cabin'] == true || data['has_cabin'] == 1;
      _ac = data['has_ac'] == true || data['has_ac'] == 1;
      _food = data['has_food'] == true || data['has_food'] == 1;
      _online = data['online_booking'] == true || data['online_booking'] == 1;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _operator, _from, _to, _departTerminal, _arrivalTerminal, _departTime, _arrivalTime, _days, _deckFare, _chairFare, _singleCabin, _doubleCabin, _phones, _hotline, _website, _district, _upazila, _address, _description, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String _v(String key) => widget.initial?[key]?.toString() == 'null' ? '' : widget.initial?[key]?.toString() ?? '';
  String _time(String key) => _v(key).length >= 5 ? _v(key).substring(0, 5) : _v(key);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final phones = _phones.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      await _api.post('/launches/register', body: {
        if (widget.initial?['id'] != null) 'id': widget.initial!['id'],
        'name': _name.text.trim(),
        'operator_name': _empty(_operator),
        'route_from': _empty(_from),
        'route_to': _empty(_to),
        'departure_terminal': _empty(_departTerminal),
        'arrival_terminal': _empty(_arrivalTerminal),
        'departure_time': _empty(_departTime),
        'arrival_time': _empty(_arrivalTime),
        'running_days': _empty(_days),
        'deck_fare': _empty(_deckFare),
        'chair_fare': _empty(_chairFare),
        'single_cabin_fare': _empty(_singleCabin),
        'double_cabin_fare': _empty(_doubleCabin),
        'has_cabin': _cabin,
        'has_ac': _ac,
        'has_food': _food,
        'online_booking': _online,
        'phones': phones.isEmpty ? null : phones,
        'hotline': _empty(_hotline),
        'website': _empty(_website),
        'district': _empty(_district),
        'upazila': _empty(_upazila),
        'address': _empty(_address),
        'description': _empty(_description),
        'notes': _empty(_notes),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('লঞ্চের তথ্য সংরক্ষণ হয়েছে')));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সংরক্ষণ করা যায়নি')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _empty(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(title: 'লঞ্চ তথ্য যোগ', subtitle: 'সময়, ভাড়া ও যোগাযোগ'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_name, 'লঞ্চের নাম', required: true),
            _field(_operator, 'অপারেটর/কোম্পানি'),
            Row(children: [Expanded(child: _field(_from, 'কোথা থেকে')), const SizedBox(width: 10), Expanded(child: _field(_to, 'কোথায় যাবে'))]),
            _field(_departTerminal, 'ছাড়ার ঘাট/টার্মিনাল'),
            _field(_arrivalTerminal, 'গন্তব্য ঘাট/টার্মিনাল'),
            Row(children: [Expanded(child: _field(_departTime, 'ছাড়ার সময়', hint: '20:30')), const SizedBox(width: 10), Expanded(child: _field(_arrivalTime, 'পৌঁছানোর সময়', hint: '06:00'))]),
            _field(_days, 'চলার দিন', hint: 'Daily / Sun-Thu'),
            Row(children: [Expanded(child: _field(_deckFare, 'ডেক ভাড়া', inputType: TextInputType.number)), const SizedBox(width: 10), Expanded(child: _field(_chairFare, 'চেয়ার ভাড়া', inputType: TextInputType.number))]),
            Row(children: [Expanded(child: _field(_singleCabin, 'সিঙ্গেল কেবিন', inputType: TextInputType.number)), const SizedBox(width: 10), Expanded(child: _field(_doubleCabin, 'ডাবল কেবিন', inputType: TextInputType.number))]),
            SwitchListTile(value: _cabin, onChanged: (v) => setState(() => _cabin = v), title: const Text('কেবিন আছে')),
            SwitchListTile(value: _ac, onChanged: (v) => setState(() => _ac = v), title: const Text('এসি আছে')),
            SwitchListTile(value: _food, onChanged: (v) => setState(() => _food = v), title: const Text('খাবারের সুবিধা আছে')),
            SwitchListTile(value: _online, onChanged: (v) => setState(() => _online = v), title: const Text('অনলাইন বুকিং আছে')),
            _field(_phones, 'ফোন নম্বর (কমা দিয়ে আলাদা করুন)', inputType: TextInputType.phone),
            _field(_hotline, 'হটলাইন', inputType: TextInputType.phone),
            _field(_website, 'ওয়েবসাইট', inputType: TextInputType.url),
            Row(children: [Expanded(child: _field(_district, 'জেলা')), const SizedBox(width: 10), Expanded(child: _field(_upazila, 'উপজেলা'))]),
            _field(_address, 'ঠিকানা'),
            _field(_description, 'বিবরণ', maxLines: 3),
            _field(_notes, 'নোট/সতর্কতা', maxLines: 3),
            const SizedBox(height: 8),
            FilledButton(onPressed: _saving ? null : _submit, child: _saving ? const CircularProgressIndicator() : const Text('সাবমিট')),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {bool required = false, String? hint, TextInputType? inputType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: inputType,
        validator: required ? (value) => value == null || value.trim().isEmpty ? 'এই ঘরটি প্রয়োজন' : null : null,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}