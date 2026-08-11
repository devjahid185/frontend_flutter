import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/widgets/location_picker_screen.dart';
import '../../core/widgets/logo_loader.dart';
import '../common/modern_app_bar.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  static const _bholaUpazilas = [
    'ভোলা সদর',
    'বোরহানউদ্দিন',
    'দৌলতখান',
    'লালমোহন',
    'চরফ্যাশন',
    'তজুমদ্দিন',
    'মনপুরা',
  ];

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
  int _tabIndex = 0;
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
      final body = <String, dynamic>{};
      if (status != null) {
        body['status'] = status;
      }
      await _api.post(path, body: body);
      _snack('অর্ডার আপডেট হয়েছে');
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _showOrderMap(Map<String, dynamic> order) async {
    final deliveryLat = readDouble(order['delivery_lat']);
    final deliveryLng = readDouble(order['delivery_lng']);
    if (deliveryLat == null || deliveryLng == null) {
      _snack('ডেলিভারি লোকেশন পাওয়া যায়নি');
      return;
    }

    final restaurant = order['restaurant'] is Map
        ? Map<String, dynamic>.from(order['restaurant'] as Map)
        : <String, dynamic>{};
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(deliveryLat, deliveryLng),
        infoWindow: InfoWindow(
          title: order['receiver_name']?.toString() ?? 'কাস্টমার',
        ),
      ),
    };
    final restaurantLat = readDouble(restaurant['lat']);
    final restaurantLng = readDouble(restaurant['lng']);
    if (restaurantLat != null && restaurantLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('restaurant'),
          position: LatLng(restaurantLat, restaurantLng),
          infoWindow: InfoWindow(
            title: restaurant['name']?.toString() ?? 'রেস্টুরেন্ট',
          ),
        ),
      );
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: restaurantLat ?? deliveryLat,
          initialLng: restaurantLng ?? deliveryLng,
          title: 'ডেলিভারি রুট লোকেশন',
          readOnly: true,
          markers: markers,
        ),
      ),
    );
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

  String? get _selectedUpazila {
    final value = _upazila.text.trim();
    return _bholaUpazilas.contains(value) ? value : null;
  }

  @override
  Widget build(BuildContext context) {
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
                  _heroPanel(context, rider),
                  const SizedBox(height: 12),
                  _tabSwitcher(context, rider),
                  const SizedBox(height: 12),
                  _tabContent(context, rider),
                  if (_saving) const _SavingFooter(),
                ],
              ),
            ),
    );
  }

  Widget _heroPanel(BuildContext context, Map<String, dynamic>? rider) {
    final scheme = Theme.of(context).colorScheme;
    final stats = Map<String, dynamic>.from(
      (_dashboard['stats'] as Map?) ?? {},
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.delivery_dining_rounded,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider == null
                          ? 'রাইডার হিসেবে শুরু করুন'
                          : rider['name']?.toString() ?? 'রাইডার',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      rider == null
                          ? 'প্রোফাইল, KYC ও চুক্তি সম্পন্ন করুন'
                          : 'KYC: ${rider['kyc_status_bn']} • ${rider['account_status_bn']} • ${rider['availability_status_bn']}',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer.withValues(
                          alpha: 0.78,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (rider != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _miniStat('আজ ডেলিভারি', '${stats['today_deliveries'] ?? 0}'),
                _miniStat('আজ আয়', '৳${stats['today_earning'] ?? 0}'),
                _miniStat('পেআউট', '৳${stats['pending_payout'] ?? 0}'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabSwitcher(BuildContext context, Map<String, dynamic>? rider) {
    final tabs = rider == null
        ? const [('profile', Icons.person_add_alt_1_rounded, 'রেজিস্ট্রেশন')]
        : const [
            ('delivery', Icons.route_outlined, 'ডেলিভারি'),
            ('profile', Icons.badge_outlined, 'প্রোফাইল'),
            ('kyc', Icons.verified_user_outlined, 'KYC'),
            ('wallet', Icons.account_balance_wallet_outlined, 'ওয়ালেট'),
            ('support', Icons.support_agent_outlined, 'সাপোর্ট'),
          ];
    if (_tabIndex >= tabs.length) _tabIndex = 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _tabIndex == index;
          final tab = tabs[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              avatar: Icon(tab.$2, size: 17),
              label: Text(tab.$3),
              onSelected: (_) => setState(() => _tabIndex = index),
            ),
          );
        }),
      ),
    );
  }

  Widget _tabContent(BuildContext context, Map<String, dynamic>? rider) {
    if (rider == null) return _profileForm(context);
    return switch (_tabIndex) {
      0 => Column(
        children: [
          _availabilitySection(context, rider),
          const SizedBox(height: 12),
          _ordersSection(context),
        ],
      ),
      1 => _profileForm(context),
      2 => Column(
        children: [
          _kycSection(context, rider),
          const SizedBox(height: 12),
          _agreementSection(context, rider),
        ],
      ),
      3 => _walletSection(context),
      _ => _supportSection(context),
    };
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
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
            _sectionHeader(
              icon: Icons.badge_outlined,
              title: 'রাইডার রেজিস্ট্রেশন',
              subtitle: 'ব্যক্তিগত তথ্য, এলাকা ও যানবাহনের তথ্য',
            ),
            _field(_name, 'নাম', required: true),
            _field(_phone, 'মোবাইল নম্বর', required: true),
            _field(_email, 'ইমেইল'),
            DropdownButtonFormField<String>(
              initialValue: _selectedUpazila,
              decoration: const InputDecoration(
                labelText: 'উপজেলা নির্বাচন করুন',
              ),
              items: _bholaUpazilas
                  .map(
                    (name) => DropdownMenuItem(value: name, child: Text(name)),
                  )
                  .toList(),
              validator: (v) => v == null || v.isEmpty ? 'উপজেলা আবশ্যক' : null,
              onChanged: (v) => _upazila.text = v ?? '',
            ),
            const SizedBox(height: 10),
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
          _sectionHeader(
            icon: Icons.verified_user_outlined,
            title: 'KYC যাচাই',
            subtitle: 'NID, সেলফি, লাইসেন্স ও পেমেন্ট ডকুমেন্ট',
          ),
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
          _sectionHeader(
            icon: Icons.edit_document,
            title: 'চুক্তি ও কমিশন',
            subtitle: 'ডিজিটাল চুক্তি, কমিশন ও পেমেন্ট সাইকেল',
          ),
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
          _sectionHeader(
            icon: Icons.toggle_on_outlined,
            title: 'অনলাইন/অফলাইন',
            subtitle: 'অর্ডার নিতে প্রস্তুত কিনা সেট করুন',
          ),
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
    final requests = (_dashboard['new_requests'] as List?) ?? [];
    final orders = (_dashboard['active_orders'] as List?) ?? [];
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.route_outlined,
            title: 'ডেলিভারি',
            subtitle: 'নতুন রিকোয়েস্ট ও চলমান অর্ডারের অবস্থা',
          ),
          if (requests.isEmpty && orders.isEmpty)
            const Text('এখন কোনো ডেলিভারি রিকোয়েস্ট নেই'),
          if (requests.isNotEmpty) ...[
            Text(
              'নতুন ডেলিভারি রিকোয়েস্ট',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...requests.map((raw) {
              final order = Map<String, dynamic>.from(raw as Map);
              final id = (order['id'] as num).toInt();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.delivery_dining),
                  ),
                  title: Text(order['order_no']?.toString() ?? 'অর্ডার #$id'),
                  subtitle: Text(
                    '${order['restaurant']?['name'] ?? 'রেস্টুরেন্ট'}\n${order['restaurant']?['address'] ?? order['delivery_address'] ?? ''}',
                  ),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => _orderAction(id, 'reject'),
                        child: const Text('না'),
                      ),
                      FilledButton(
                        onPressed: () => _orderAction(id, 'accept'),
                        child: const Text('নেবো'),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          if (orders.isNotEmpty) ...[
            if (requests.isNotEmpty) const Divider(height: 28),
            Text(
              'চলমান ডেলিভারি',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
          ],
          ...orders.map((raw) {
            final order = Map<String, dynamic>.from(raw as Map);
            final id = (order['id'] as num).toInt();
            return Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(order['order_no']?.toString() ?? 'অর্ডার #$id'),
                  subtitle: Text(
                    '${order['restaurant']?['name'] ?? 'রেস্টুরেন্ট'}\n${order['delivery_address'] ?? ''}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
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
                      PopupMenuItem(
                        value: 'picked_up',
                        child: Text('খাবার নিয়েছি'),
                      ),
                      PopupMenuItem(
                        value: 'on_the_way',
                        child: Text('পথে আছি'),
                      ),
                      PopupMenuItem(
                        value: 'delivered',
                        child: Text('ডেলিভারি সম্পন্ন'),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _showOrderMap(order),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('ম্যাপে রেস্টুরেন্ট ও কাস্টমার'),
                  ),
                ),
              ],
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
          _sectionHeader(
            icon: Icons.account_balance_wallet_outlined,
            title: 'আয় ও পারফরম্যান্স',
            subtitle: 'ডেলিভারি আয়, পেআউট, ক্যাশ ও রেটিং',
          ),
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
          _sectionHeader(
            icon: Icons.support_agent_outlined,
            title: 'সাপোর্ট টিকিট',
            subtitle: 'অর্ডার বা পেমেন্ট সমস্যা অ্যাডমিনকে জানান',
          ),
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

class _SavingFooter extends StatelessWidget {
  const _SavingFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 14),
      child: Center(child: LogoLoader(size: 34, showLabel: true)),
    );
  }
}
