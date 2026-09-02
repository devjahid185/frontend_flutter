import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/widgets/location_picker_screen.dart';
import '../../core/widgets/logo_loader.dart';
import '../common/image_upload_preview.dart';
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
  final _bkashNumber = TextEditingController();
  final _nagadNumber = TextEditingController();
  final _bankAccountName = TextEditingController();
  final _bankAccountNumber = TextEditingController();
  final _bankName = TextEditingController();
  final _bankBranch = TextEditingController();
  final _ticketSubject = TextEditingController();
  final _ticketMessage = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  int _tabIndex = 0;
  String _vehicleType = 'bike';
  Map<String, dynamic>? _rider;
  Map<String, dynamic> _dashboard = {};
  Map<String, dynamic> _settings = {};
  Timer? _liveLocationTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _liveLocationTimer?.cancel();
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
      _bkashNumber,
      _nagadNumber,
      _bankAccountName,
      _bankAccountNumber,
      _bankName,
      _bankBranch,
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
        if (rider['availability_status']?.toString() == 'online') {
          await _sendLocation(silent: true);
        }
        dashboard = Map<String, dynamic>.from(
          await _api.get('/riders/dashboard'),
        );
      }
      if (!mounted) return;
      setState(() {
        _rider = rider;
        _settings = Map<String, dynamic>.from(
          (profile['settings'] as Map?) ?? {},
        );
        _dashboard = dashboard;
      });
      _syncLiveLocationTracking();
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
    _bkashNumber.text = rider['bkash_number']?.toString() ?? '';
    _nagadNumber.text = rider['nagad_number']?.toString() ?? '';
    _bankAccountName.text = rider['bank_account_name']?.toString() ?? '';
    _bankAccountNumber.text = rider['bank_account_number']?.toString() ?? '';
    _bankName.text = rider['bank_name']?.toString() ?? '';
    _bankBranch.text = rider['bank_branch']?.toString() ?? '';
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
          'bkash_number': _bkashNumber.text.trim(),
          'nagad_number': _nagadNumber.text.trim(),
          'bank_account_name': _bankAccountName.text.trim(),
          'bank_account_number': _bankAccountNumber.text.trim(),
          'bank_name': _bankName.text.trim(),
          'bank_branch': _bankBranch.text.trim(),
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

  Future<void> _sendLocation({bool silent = false}) async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition();
      await _api.post(
        '/riders/location',
        body: {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'accuracy': pos.accuracy,
          if (_activeTrackingOrderId != null)
            'food_order_id': _activeTrackingOrderId,
        },
      );
    } on ApiException catch (e) {
      if (!silent) _snack(e.message);
    } catch (_) {
      if (!silent) _snack('লোকেশন আপডেট করা যায়নি।');
    }
  }

  Future<void> _orderAction(
    int id,
    String action, {
    String? status,
    Map<String, dynamic>? body,
    Map<String, dynamic>? files,
  }) async {
    try {
      final path = action == 'status'
          ? '/riders/orders/$id/status'
          : '/riders/orders/$id/$action';
      final payload = <String, dynamic>{...?body};
      if (status != null) {
        payload['status'] = status;
      }
      if (files != null && files.isNotEmpty) {
        await _api.postMultipart(
          path,
          fields: payload.map((key, value) => MapEntry(key, '$value')),
          files: files,
        );
      } else {
        await _api.post(path, body: payload);
      }
      _snack('অর্ডার আপডেট হয়েছে');
      if (status == 'picked_up' || status == 'on_the_way') {
        await _sendLocation(silent: true);
      }
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _openOrderDetails(Map<String, dynamic> order) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RiderOrderDetailsScreen(
          order: order,
          onRefresh: _load,
          onAction: _orderAction,
          onShowMap: _showOrderMap,
        ),
      ),
    );
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
    final markers = <AppMapMarker>[];
    final restaurantLat = readDouble(restaurant['lat']);
    final restaurantLng = readDouble(restaurant['lng']);
    if (restaurantLat != null && restaurantLng != null) {
      markers.add(
        AppMapMarker(
          lat: restaurantLat,
          lng: restaurantLng,
          label: restaurant['name']?.toString() ?? 'রেস্টুরেন্ট',
          icon: Icons.restaurant_rounded,
          color: Colors.deepOrange,
        ),
      );
    }
    markers.add(
      AppMapMarker(
        lat: deliveryLat,
        lng: deliveryLng,
        label: order['receiver_name']?.toString() ?? 'কাস্টমার',
        icon: Icons.location_city_rounded,
      ),
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: restaurantLat ?? deliveryLat,
          initialLng: restaurantLng ?? deliveryLng,
          title: 'ডেলিভারি রুট লোকেশন',
          readOnly: true,
          useNativeGoogleRoute: false,
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

  int? get _activeTrackingOrderId {
    final orders = (_dashboard['active_orders'] as List?) ?? [];
    for (final raw in orders) {
      final order = Map<String, dynamic>.from(raw as Map);
      final status = order['status']?.toString();
      if (status == 'picked_up' || status == 'on_the_way') {
        return (order['id'] as num?)?.toInt();
      }
    }
    return null;
  }

  void _syncLiveLocationTracking() {
    final shouldTrack = _activeTrackingOrderId != null;
    if (!shouldTrack) {
      _liveLocationTimer?.cancel();
      _liveLocationTimer = null;
      return;
    }
    _liveLocationTimer ??= Timer.periodic(
      const Duration(seconds: 15),
      (_) => _sendLocation(silent: true),
    );
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
            const Divider(height: 22),
            Text(
              'পেমেন্ট তথ্য',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _field(_bkashNumber, 'bKash নম্বর'),
            _field(_nagadNumber, 'Nagad নম্বর'),
            _field(_bankAccountName, 'ব্যাংক অ্যাকাউন্ট নাম'),
            _field(_bankAccountNumber, 'ব্যাংক অ্যাকাউন্ট নম্বর'),
            _field(_bankName, 'ব্যাংকের নাম'),
            _field(_bankBranch, 'ব্রাঞ্চ'),
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
    Map<String, dynamic>? docFor(String type) {
      for (final raw in docs) {
        final doc = Map<String, dynamic>.from(raw as Map);
        if (doc['type'] == type) return doc;
      }
      return null;
    }

    final requiredDocs = [
      ('nid_front', 'এনআইডি সামনে'),
      ('nid_back', 'এনআইডি পিছনে'),
      ('selfie', 'সেলফি যাচাই'),
      if (_vehicleType != 'cycle') ('driving_license', 'ড্রাইভিং লাইসেন্স'),
      if (_vehicleType != 'cycle') ('vehicle_paper', 'যানবাহনের কাগজ'),
    ];
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.verified_user_outlined,
            title: 'KYC যাচাই',
            subtitle: 'NID, সেলফি, লাইসেন্স ও যানবাহনের কাগজ',
          ),
          ...requiredDocs.map((item) {
            final uploaded = docFor(item.$1);
            final fileUrl = uploaded?['file_url']?.toString();
            final isImage =
                fileUrl != null &&
                RegExp(
                  r'\.(jpg|jpeg|png|webp)(\?.*)?$',
                  caseSensitive: false,
                ).hasMatch(fileUrl);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: isImage
                      ? Image.network(fileUrl, fit: BoxFit.cover)
                      : ColoredBox(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: Icon(
                            uploaded != null
                                ? Icons.verified_rounded
                                : Icons.upload_file_rounded,
                          ),
                        ),
                ),
              ),
              title: Text(item.$2),
              subtitle: Text(
                uploaded != null ? 'আপলোড করা হয়েছে' : 'ছবি আপলোড করুন',
              ),
              trailing: TextButton(
                onPressed: _saving ? null : () => _uploadDoc(item.$1, item.$2),
                child: Text(uploaded != null ? 'পরিবর্তন' : 'আপলোড'),
              ),
              onTap: fileUrl == null
                  ? null
                  : () => launchUrl(
                      Uri.parse(fileUrl),
                      mode: LaunchMode.externalApplication,
                    ),
            );
          }),
          if (_bkashNumber.text.trim().isNotEmpty ||
              _nagadNumber.text.trim().isNotEmpty ||
              _bankAccountNumber.text.trim().isNotEmpty) ...[
            const Divider(height: 18),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('পেমেন্ট তথ্য'),
              subtitle: Text(
                [
                  if (_bkashNumber.text.trim().isNotEmpty)
                    'bKash: ${_bkashNumber.text.trim()}',
                  if (_nagadNumber.text.trim().isNotEmpty)
                    'Nagad: ${_nagadNumber.text.trim()}',
                  if (_bankAccountNumber.text.trim().isNotEmpty)
                    'Bank: ${_bankAccountNumber.text.trim()}',
                ].join('\n'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _agreementSection(BuildContext context, Map<String, dynamic> rider) {
    final accepted = rider['agreement_accepted'] == true;
    final pdf = rider['agreement_pdf_url']?.toString();
    final commissionDescription = _settingText('commission_description');
    final commissionTitle = _settingText('commission_title') ?? 'কমিশন';
    final agreementTitle = _settingText('agreement_title') ?? 'চুক্তি ও কমিশন';
    final agreementTerms = _settingText('agreement_terms');
    final cashPolicy = _settingText('cash_policy');
    final penaltyPolicy = _settingText('penalty_policy');
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.edit_document,
            title: agreementTitle,
            subtitle: 'ডিজিটাল চুক্তি, কমিশন ও পেমেন্ট সাইকেল',
          ),
          Text('$commissionTitle: ${_commissionLabel(rider)}'),
          Text('পেমেন্ট সাইকেল: ${_paymentCycle(rider['payment_cycle'])}'),
          if (commissionDescription != null &&
              commissionDescription.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(commissionDescription),
          ],
          const SizedBox(height: 8),
          Text(
            agreementTerms?.isNotEmpty == true
                ? agreementTerms!
                : 'রাইডারের দায়িত্ব: সময়মতো পিকআপ, নিরাপদ ডেলিভারি, গ্রাহকের সাথে ভদ্র আচরণ এবং ক্যাশ হিসাব সঠিক রাখা।',
          ),
          if (cashPolicy != null && cashPolicy.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('ক্যাশ নীতি: $cashPolicy'),
          ],
          if (penaltyPolicy != null && penaltyPolicy.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('পেনাল্টি/আইনি ব্যবস্থা: $penaltyPolicy'),
          ],
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
              final isMedicine =
                  order['service_type']?.toString() == 'medicine';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => _openOrderDetails(order),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.65),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          child: Icon(
                            isMedicine
                                ? Icons.medical_services_outlined
                                : Icons.delivery_dining,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order['order_no']?.toString() ??
                                    'অর্ডার #${order['id'] ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${order['restaurant']?['name'] ?? (isMedicine ? 'মেডিসিন পিকআপ' : 'রেস্টুরেন্ট')}\n${order['restaurant']?['address'] ?? order['delivery_address'] ?? ''}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
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
            final isMedicine = order['service_type']?.toString() == 'medicine';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => _openOrderDetails(order),
              title: Text(
                order['order_no']?.toString() ?? 'অর্ডার #${order['id'] ?? ''}',
              ),
              subtitle: Text(
                '${order['restaurant']?['name'] ?? (isMedicine ? 'মেডিসিন পিকআপ' : 'রেস্টুরেন্ট')}\n${order['delivery_address'] ?? ''}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                onPressed: () => _openOrderDetails(order),
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'খুলুন',
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

  String? _settingText(String key) {
    final value = _settings[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }
}

class RiderOrderDetailsScreen extends StatefulWidget {
  const RiderOrderDetailsScreen({
    super.key,
    required this.order,
    required this.onRefresh,
    required this.onAction,
    required this.onShowMap,
  });

  final Map<String, dynamic> order;
  final Future<void> Function() onRefresh;
  final Future<void> Function(
    int id,
    String action, {
    String? status,
    Map<String, dynamic>? body,
    Map<String, dynamic>? files,
  })
  onAction;
  final Future<void> Function(Map<String, dynamic> order) onShowMap;

  @override
  State<RiderOrderDetailsScreen> createState() =>
      _RiderOrderDetailsScreenState();
}

class _RiderOrderDetailsScreenState extends State<RiderOrderDetailsScreen> {
  bool _busy = false;
  final _picker = ImagePicker();

  Map<String, dynamic> get order => widget.order;

  int get _orderId => (order['id'] as num?)?.toInt() ?? 0;

  Map<String, dynamic> get _restaurant => order['restaurant'] is Map
      ? Map<String, dynamic>.from(order['restaurant'] as Map)
      : <String, dynamic>{};

  List<Map<String, dynamic>> get _items => ((order['items'] as List?) ?? [])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();

  String get _serviceType => order['service_type']?.toString() ?? 'food';

  bool get _isMedicine => _serviceType == 'medicine';

  String get _pickupTitle => _isMedicine ? 'মেডিসিন পিকআপ' : 'রেস্টুরেন্ট';

  Future<void> _call(String? phone) async {
    final value = phone?.trim();
    if (value == null || value.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: value);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _runAction(
    String action, {
    String? status,
    Map<String, dynamic>? body,
    Map<String, dynamic>? files,
  }) async {
    if (_orderId == 0 || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.onAction(
        _orderId,
        action,
        status: status,
        body: {'service_type': _serviceType, ...?body},
        files: files,
      );
      await widget.onRefresh();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeDelivery() async {
    final otp = TextEditingController();
    final cash = TextEditingController(text: '${order['grand_total'] ?? ''}');
    XFile? proof;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ডেলিভারি কনফার্ম',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'কাস্টমারের OTP বা ডেলিভারি প্রুফ দিয়ে অর্ডার সম্পন্ন করুন।',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otp,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ডেলিভারি OTP',
                      hintText: 'কাস্টমারের কাছ থেকে OTP নিন',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cash,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ক্যাশ সংগ্রহ',
                      prefixText: '৳ ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final image = await _picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 75,
                        maxWidth: 1600,
                      );
                      if (image != null) {
                        setSheetState(() => proof = image);
                      }
                    },
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(
                      proof == null ? 'ডেলিভারি ছবি তুলুন' : 'ছবি নেওয়া হয়েছে',
                    ),
                  ),
                  if (proof != null) ...[
                    const SizedBox(height: 12),
                    PickedImageHeroPreview(
                      image: proof,
                      height: 140,
                      onTap: () async {
                        final image = await _picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 75,
                          maxWidth: 1600,
                        );
                        if (image != null) {
                          setSheetState(() => proof = image);
                        }
                      },
                      onRemove: () => setSheetState(() => proof = null),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      icon: const Icon(Icons.task_alt_rounded),
                      label: const Text('ডেলিভারি সম্পন্ন করুন'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final otpText = otp.text.trim();
    final cashText = cash.text.trim();
    otp.dispose();
    cash.dispose();

    if (submitted != true) return;
    await _runAction(
      'status',
      status: 'delivered',
      body: {
        if (otpText.isNotEmpty) 'delivery_otp': otpText,
        if (cashText.isNotEmpty) 'cash_collected': cashText,
      },
      files: proof == null ? null : {'proof_photo': proof!.path},
    );
  }

  String _money(dynamic value) => '৳${value ?? 0}';

  String _statusLabel(String status) {
    return {
          'pending': 'পেন্ডিং',
          'accepted': 'রেস্টুরেন্ট গ্রহণ করেছে',
          'preparing': 'খাবার তৈরি হচ্ছে',
          'assigned': 'রাইডার অ্যাসাইন হয়েছে',
          'picked_up': 'খাবার নেওয়া হয়েছে',
          'on_the_way': 'ডেলিভারির পথে',
          'delivered': 'ডেলিভারি সম্পন্ন',
          'cancelled': 'বাতিল',
        }[status] ??
        status;
  }

  List<Widget> _actionButtons(String status) {
    final hasRider = order['rider_id'] != null;
    if (!hasRider && status != 'cancelled' && status != 'delivered') {
      return [
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _runAction('reject'),
          icon: const Icon(Icons.close_rounded, size: 18),
          label: const Text('রিকোয়েস্ট নেবো না'),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : () => _runAction('accept'),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('অর্ডার গ্রহণ করুন'),
        ),
      ];
    }
    if (status == 'accepted' || status == 'preparing' || status == 'assigned') {
      return [
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () => _runAction('status', status: 'picked_up'),
          icon: const Icon(Icons.shopping_bag_outlined, size: 18),
          label: Text(_isMedicine ? 'মেডিসিন নিয়েছি' : 'খাবার নিয়েছি'),
        ),
      ];
    }
    if (status == 'picked_up') {
      return [
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () => _runAction('status', status: 'on_the_way'),
          icon: const Icon(Icons.delivery_dining_rounded, size: 18),
          label: const Text('ডেলিভারির পথে'),
        ),
      ];
    }
    if (status == 'on_the_way') {
      return [
        FilledButton.icon(
          onPressed: _busy ? null : _completeDelivery,
          icon: const Icon(Icons.task_alt_rounded, size: 18),
          label: const Text('ডেলিভারি সম্পন্ন'),
        ),
      ];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = order['status']?.toString() ?? 'pending';
    final restaurantPhone =
        _restaurant['phone']?.toString() ??
        _restaurant['owner_phone']?.toString();
    final distance =
        order['route_distance_km'] ?? order['delivery_distance_km'];
    final actionButtons = _actionButtons(status);

    return Scaffold(
      appBar: ModernAppBar(
        title: 'অর্ডার ডিটেইলস',
        subtitle: order['order_no']?.toString() ?? 'রাইডার ডেলিভারি',
      ),
      body: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _RiderDetailCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.onPrimaryContainer,
                        child: const Icon(Icons.receipt_long_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order['order_no']?.toString() ??
                                  'অর্ডার #$_orderId',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _statusLabel(status),
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      _RiderStatusPill(label: _statusLabel(status)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _RiderMiniMetric(
                          label: 'মোট বিল',
                          value: _money(order['grand_total']),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RiderMiniMetric(
                          label: 'ডেলিভারি',
                          value: _money(order['delivery_fee']),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _RiderDetailCard(
              title: 'রুট ও লোকেশন',
              subtitle: distance == null
                  ? 'পিকআপ থেকে কাস্টমারের লোকেশন'
                  : 'পিকআপ থেকে কাস্টমার: $distance KM',
              child: Column(
                children: [
                  _InfoTile(
                    icon: _isMedicine
                        ? Icons.medical_services_outlined
                        : Icons.restaurant_rounded,
                    title: _restaurant['name']?.toString() ?? _pickupTitle,
                    subtitle: _restaurant['address']?.toString() ?? '',
                  ),
                  const Divider(height: 18),
                  _InfoTile(
                    icon: Icons.location_on_rounded,
                    title: order['receiver_name']?.toString() ?? 'কাস্টমার',
                    subtitle: order['delivery_address']?.toString() ?? '',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => widget.onShowMap(order),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('পিকআপ ও ডেলিভারি ম্যাপে দেখুন'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _RiderDetailCard(
              title: _pickupTitle,
              child: Column(
                children: [
                  _DetailRow('নাম', _restaurant['name']),
                  _DetailRow('মোবাইল', restaurantPhone),
                  _DetailRow('ঠিকানা', _restaurant['address']),
                  if (restaurantPhone != null && restaurantPhone.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _call(restaurantPhone),
                        icon: const Icon(Icons.call_outlined, size: 18),
                        label: Text('$_pickupTitle-এ কল করুন'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _RiderDetailCard(
              title: 'কাস্টমার',
              child: Column(
                children: [
                  _DetailRow('নাম', order['receiver_name']),
                  _DetailRow('মোবাইল', order['receiver_phone']),
                  _DetailRow('ডেলিভারি ঠিকানা', order['delivery_address']),
                  _DetailRow('এরিয়া', order['delivery_area']),
                  if (order['receiver_phone']?.toString().isNotEmpty == true)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () =>
                            _call(order['receiver_phone']?.toString()),
                        icon: const Icon(Icons.call_outlined, size: 18),
                        label: const Text('কাস্টমারকে কল করুন'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _RiderDetailCard(
              title: _isMedicine ? 'মেডিসিনের তালিকা' : 'খাবারের তালিকা',
              subtitle: '${_items.length} টি আইটেম',
              child: Column(
                children: _items.isEmpty
                    ? [const Text('আইটেম তথ্য পাওয়া যায়নি')]
                    : _items.map((item) => _RiderItemLine(item: item)).toList(),
              ),
            ),
            const SizedBox(height: 12),
            _RiderDetailCard(
              title: 'বিল ও পেমেন্ট',
              child: Column(
                children: [
                  _DetailRow('আইটেম মোট', _money(order['items_total'])),
                  _DetailRow('ডেলিভারি ফি', _money(order['delivery_fee'])),
                  _DetailRow(
                    'ডিসকাউন্ট',
                    _money(order['discount_amount'] ?? 0),
                  ),
                  const Divider(height: 18),
                  _DetailRow(
                    'গ্র্যান্ড টোটাল',
                    _money(order['grand_total']),
                    strong: true,
                  ),
                  _DetailRow(
                    'পেমেন্ট মেথড',
                    order['payment_method'] ?? 'cash_on_delivery',
                  ),
                  _DetailRow(
                    'পেমেন্ট স্ট্যাটাস',
                    order['payment_status'] ?? 'pending',
                  ),
                  _DetailRow(
                    'ক্যাশ সংগ্রহ',
                    _money(order['cash_collection'] ?? order['grand_total']),
                  ),
                ],
              ),
            ),
            if (actionButtons.isNotEmpty) ...[
              const SizedBox(height: 12),
              _RiderDetailCard(
                title: 'ডেলিভারি অ্যাকশন',
                subtitle: 'পরবর্তী স্ট্যাটাস এখান থেকে আপডেট করুন',
                child: Wrap(spacing: 8, runSpacing: 8, children: actionButtons),
              ),
            ],
            if (_busy) const _SavingFooter(),
          ],
        ),
      ),
    );
  }
}

class _RiderDetailCard extends StatelessWidget {
  const _RiderDetailCard({required this.child, this.title, this.subtitle});

  final Widget child;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _RiderStatusPill extends StatelessWidget {
  const _RiderStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RiderMiniMetric extends StatelessWidget {
  const _RiderMiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.strong = false});

  final String label;
  final dynamic value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderItemLine extends StatelessWidget {
  const _RiderItemLine({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final qty = item['quantity'] ?? 1;
    final unit = item['unit_price'] ?? item['price'] ?? 0;
    final total = item['total_price'] ?? item['line_total'] ?? unit;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name']?.toString() ?? 'আইটেম',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '$qty x ৳$unit',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text('৳$total', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
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
