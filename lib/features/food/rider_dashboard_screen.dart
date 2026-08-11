import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/widgets/logo_loader.dart';
import '../common/modern_app_bar.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _district = TextEditingController(text: 'Bhola');
  final _upazila = TextEditingController();
  final _address = TextEditingController();
  final _vehicleNumber = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _ticketSubject = TextEditingController();
  final _ticketMessage = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String _vehicleType = 'bike';
  Map<String, dynamic>? _rider;
  Map<String, dynamic> _dashboard = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _email,
      _district,
      _upazila,
      _address,
      _vehicleNumber,
      _emergencyName,
      _emergencyPhone,
      _ticketSubject,
      _ticketMessage,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await _api.get('/riders/profile');
      final rider = profile['rider'] == null
          ? null
          : Map<String, dynamic>.from(profile['rider']);
      Map<String, dynamic> dashboard = {};
      if (rider != null) {
        dashboard = Map<String, dynamic>.from(
          await _api.get('/riders/dashboard'),
        );
      }
      if (!mounted) return;
      setState(() {
        _rider = rider;
        _dashboard = dashboard;
      });
      _fillForm(rider);
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillForm(Map<String, dynamic>? rider) {
    if (rider == null) return;
    _name.text = rider['name']?.toString() ?? '';
    _phone.text = rider['phone']?.toString() ?? '';
    _email.text = rider['email']?.toString() ?? '';
    _district.text = rider['district']?.toString() ?? 'Bhola';
    _upazila.text = rider['upazila']?.toString() ?? '';
    _address.text = rider['address']?.toString() ?? '';
    _vehicleType = rider['vehicle_type']?.toString() ?? 'bike';
    _vehicleNumber.text = rider['vehicle_number']?.toString() ?? '';
    _emergencyName.text = rider['emergency_contact_name']?.toString() ?? '';
    _emergencyPhone.text = rider['emergency_contact_phone']?.toString() ?? '';
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _api.post(
        '/riders/register',
        body: {
          'name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'email': _email.text.trim(),
          'district': _district.text.trim(),
          'upazila': _upazila.text.trim(),
          'address': _address.text.trim(),
          'vehicle_type': _vehicleType,
          'vehicle_number': _vehicleNumber.text.trim(),
          'emergency_contact_name': _emergencyName.text.trim(),
          'emergency_contact_phone': _emergencyPhone.text.trim(),
        },
      );
      _snack('রাইডার প্রোফাইল সংরক্ষণ হয়েছে');
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadDoc(String type, String title) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (image == null) return;
    setState(() => _saving = true);
    try {
      await _api.postMultipart(
        '/riders/documents',
        fields: {'type': type, 'title': title},
        files: {'file': image.path},
      );
      _snack('$title আপলোড হয়েছে');
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _acceptAgreement() async {
    try {
      await _api.post('/riders/agreement/accept', body: {'accepted': true});
      _snack('চুক্তি গ্রহণ করা হয়েছে');
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _setAvailability(String status) async {
    try {
      await _api.post(
        '/riders/availability',
        body: {'availability_status': status},
      );
      if (status == 'online') await _sendLocation();
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _sendLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    await _api.post(
      '/riders/location',
      body: {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'accuracy': pos.accuracy,
      },
    );
  }

  Future<void> _orderAction(int id, String action, {String? status}) async {
    try {
      final path = action == 'status'
          ? '/riders/orders/$id/status'
          : '/riders/orders/$id/$action';
      await _api.post(path, body: {if (status != null) 'status': status});
      _snack('অর্ডার আপডেট হয়েছে');
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _sendTicket() async {
    if (_ticketSubject.text.trim().isEmpty ||
        _ticketMessage.text.trim().isEmpty) {
      _snack('বিষয় ও বিস্তারিত লিখুন');
      return;
    }
    try {
      await _api.post(
        '/riders/support-tickets',
        body: {
          'subject': _ticketSubject.text.trim(),
          'message': _ticketMessage.text.trim(),
        },
      );
      _ticketSubject.clear();
      _ticketMessage.clear();
      _snack('সাপোর্ট টিকিট পাঠানো হয়েছে');
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rider = _rider;
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'রাইডার সেকশন',
        subtitle: 'রেজিস্ট্রেশন, KYC, অর্ডার ও আয়',
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _statusCard(context, rider),
                  const SizedBox(height: 12),
                  _profileForm(context),
                  if (rider != null) ...[
                    const SizedBox(height: 12),
                    _kycSection(context, rider),
                    const SizedBox(height: 12),
                    _agreementSection(context, rider),
                    const SizedBox(height: 12),
                    _availabilitySection(context, rider),
                    const SizedBox(height: 12),
                    _ordersSection(context),
                    const SizedBox(height: 12),
                    _walletSection(context),
                    const SizedBox(height: 12),
                    _supportSection(context),
                  ],
                  if (_saving)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Center(
                        child: LogoLoader(
                          size: 34,
                          showLabel: true,
                          key: ValueKey(scheme.primary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _statusCard(BuildContext context, Map<String, dynamic>? rider) {
    final scheme = Theme.of(context).colorScheme;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rider == null ? 'রাইডার হিসেবে শুরু করুন' : 'আপনার রাইডার অবস্থা',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            rider == null
                ? 'প্রোফাইল তৈরি করুন, KYC দিন, চুক্তি গ্রহণ করুন। অ্যাডমিন অনুমোদন দিলে অর্ডার নিতে পারবেন।'
                : 'KYC: ${rider['kyc_status_bn']} • অ্যাকাউন্ট: ${rider['account_status_bn']} • ${rider['availability_status_bn']}',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _profileForm(BuildContext context) {
    return _card(
      context,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'রাইডার রেজিস্ট্রেশন',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _field(_name, 'নাম', required: true),
            _field(_phone, 'মোবাইল নম্বর', required: true),
            _field(_email, 'ইমেইল'),
            Row(
              children: [
                Expanded(child: _field(_district, 'জেলা')),
                const SizedBox(width: 10),
                Expanded(child: _field(_upazila, 'উপজেলা')),
              ],
            ),
            _field(_address, 'ঠিকানা', maxLines: 2),
            DropdownButtonFormField<String>(
              initialValue: _vehicleType,
              decoration: const InputDecoration(labelText: 'যানবাহনের ধরন'),
              items: const [
                DropdownMenuItem(value: 'cycle', child: Text('সাইকেল')),
                DropdownMenuItem(value: 'bike', child: Text('মোটরসাইকেল')),
                DropdownMenuItem(value: 'car', child: Text('গাড়ি')),
              ],
              onChanged: (v) => setState(() => _vehicleType = v ?? 'bike'),
            ),
            const SizedBox(height: 10),
            _field(_vehicleNumber, 'যানবাহনের নম্বর'),
            _field(_emergencyName, 'জরুরি যোগাযোগের নাম'),
            _field(_emergencyPhone, 'জরুরি মোবাইল নম্বর', required: true),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveProfile,
                icon: const Icon(Icons.save_outlined),
                label: const Text('প্রোফাইল সংরক্ষণ করুন'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kycSection(BuildContext context, Map<String, dynamic> rider) {
    final docs = (rider['documents'] as List?) ?? [];
    bool has(String type) => docs.any((d) => d['type'] == type);
    final requiredDocs = [
      ('nid_front', 'এনআইডি সামনে'),
      ('nid_back', 'এনআইডি পিছনে'),
      ('selfie', 'সেলফি যাচাই'),
      if (_vehicleType != 'cycle') ('driving_license', 'ড্রাইভিং লাইসেন্স'),
      if (_vehicleType != 'cycle') ('vehicle_paper', 'যানবাহনের কাগজ'),
      ('bank_mfs', 'ব্যাংক/বিকাশ/নগদ তথ্য'),
    ];
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KYC যাচাই',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...requiredDocs.map(
            (doc) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                has(doc.$1)
                    ? Icons.verified_rounded
                    : Icons.upload_file_rounded,
              ),
              title: Text(doc.$2),
              subtitle: Text(
                has(doc.$1) ? 'আপলোড করা হয়েছে' : 'ছবি/PDF আপলোড করুন',
              ),
              trailing: TextButton(
                onPressed: _saving ? null : () => _uploadDoc(doc.$1, doc.$2),
                child: Text(has(doc.$1) ? 'পরিবর্তন' : 'আপলোড'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _agreementSection(BuildContext context, Map<String, dynamic> rider) {
    final accepted = rider['agreement_accepted'] == true;
    final pdf = rider['agreement_pdf_url']?.toString();
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'চুক্তি ও কমিশন',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text('কমিশন: ${_commissionLabel(rider)}'),
          Text('পেমেন্ট সাইকেল: ${_paymentCycle(rider['payment_cycle'])}'),
          const SizedBox(height: 8),
          const Text(
            'রাইডারের দায়িত্ব: সময়মতো পিকআপ, নিরাপদ ডেলিভারি, গ্রাহকের সাথে ভদ্র আচরণ এবং ক্যাশ হিসাব সঠিক রাখা।',
          ),
          const SizedBox(height: 8),
          const Text(
            'পেনাল্টি: ভুল ডেলিভারি, অযথা বাতিল, ক্যাশ জমা না দিলে অ্যাডমিন ব্যবস্থা নিতে পারবে।',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: accepted ? null : _acceptAgreement,
                  icon: Icon(
                    accepted ? Icons.check_circle : Icons.edit_document,
                  ),
                  label: Text(
                    accepted ? 'চুক্তি গ্রহণ করা হয়েছে' : 'চুক্তি গ্রহণ করুন',
                  ),
                ),
              ),
              if (pdf != null && pdf.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => launchUrl(
                    Uri.parse(pdf),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _availabilitySection(
    BuildContext context,
    Map<String, dynamic> rider,
  ) {
    final current = rider['availability_status']?.toString() ?? 'offline';
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'অনলাইন/অফলাইন',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'offline', label: Text('অফলাইন')),
              ButtonSegment(value: 'online', label: Text('অনলাইন')),
              ButtonSegment(value: 'busy', label: Text('ব্যস্ত')),
            ],
            selected: {current},
            onSelectionChanged: (s) => _setAvailability(s.first),
          ),
        ],
      ),
    );
  }

  Widget _ordersSection(BuildContext context) {
    final orders = (_dashboard['active_orders'] as List?) ?? [];
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'চলমান ডেলিভারি',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (orders.isEmpty) const Text('এখন কোনো অর্ডার নেই'),
          ...orders.map((raw) {
            final order = Map<String, dynamic>.from(raw as Map);
            final id = (order['id'] as num).toInt();
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(order['order_no']?.toString() ?? 'অর্ডার #$id'),
              subtitle: Text(
                '${order['restaurant']?['name'] ?? 'রেস্টুরেন্ট'}\n${order['delivery_address'] ?? ''}',
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'accept') {
                    _orderAction(id, 'accept');
                  }
                  if (value == 'reject') {
                    _orderAction(id, 'reject');
                  }
                  if (value == 'picked_up') {
                    _orderAction(id, 'status', status: 'picked_up');
                  }
                  if (value == 'on_the_way') {
                    _orderAction(id, 'status', status: 'on_the_way');
                  }
                  if (value == 'delivered') {
                    _orderAction(id, 'status', status: 'delivered');
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'accept', child: Text('গ্রহণ করুন')),
                  PopupMenuItem(value: 'reject', child: Text('রিজেক্ট করুন')),
                  PopupMenuItem(
                    value: 'picked_up',
                    child: Text('খাবার নিয়েছি'),
                  ),
                  PopupMenuItem(value: 'on_the_way', child: Text('পথে আছি')),
                  PopupMenuItem(
                    value: 'delivered',
                    child: Text('ডেলিভারি সম্পন্ন'),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _walletSection(BuildContext context) {
    final stats = Map<String, dynamic>.from(
      (_dashboard['stats'] as Map?) ?? {},
    );
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'আয় ও পারফরম্যান্স',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniStat('আজ ডেলিভারি', '${stats['today_deliveries'] ?? 0}'),
              _miniStat('আজ আয়', '৳${stats['today_earning'] ?? 0}'),
              _miniStat('পেন্ডিং পেআউট', '৳${stats['pending_payout'] ?? 0}'),
              _miniStat('ক্যাশ ইন হ্যান্ড', '৳${stats['cash_in_hand'] ?? 0}'),
              _miniStat('রেটিং', '${stats['rating'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _supportSection(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'সাপোর্ট টিকিট',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _field(_ticketSubject, 'বিষয়'),
          _field(_ticketMessage, 'সমস্যার বিস্তারিত', maxLines: 3),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _sendTicket,
              icon: const Icon(Icons.support_agent_outlined),
              label: const Text('অ্যাডমিন সাপোর্টে পাঠান'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => v == null || v.trim().isEmpty ? '$label আবশ্যক' : null
            : null,
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      width: 142,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _commissionLabel(Map<String, dynamic> rider) {
    final type = rider['commission_type']?.toString() ?? 'fixed';
    final value = rider['commission_value']?.toString() ?? '0';
    return {
          'fixed': 'প্রতি ডেলিভারিতে ৳$value',
          'percentage': 'ডেলিভারি চার্জের $value%',
          'zone_based': 'এলাকা অনুযায়ী',
        }[type] ??
        type;
  }

  String _paymentCycle(dynamic value) {
    return {'daily': 'দৈনিক', 'weekly': 'সাপ্তাহিক', 'monthly': 'মাসিক'}[value
            ?.toString()] ??
        'সাপ্তাহিক';
  }
}
