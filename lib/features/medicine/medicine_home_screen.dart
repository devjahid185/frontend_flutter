import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/widgets/location_picker_screen.dart';
import '../common/modern_app_bar.dart';
import '../food/widgets/checkout_payment_section.dart';

class MedicineHomeScreen extends StatefulWidget {
  const MedicineHomeScreen({super.key});

  @override
  State<MedicineHomeScreen> createState() => _MedicineHomeScreenState();
}

class _MedicineHomeScreenState extends State<MedicineHomeScreen> {
  static const int _pageSize = 20;

  final _api = ApiClient(getToken: SessionStorage().getToken);
  final _search = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  bool _loading = true;
  bool _searching = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  int _requestSerial = 0;
  int _cartCount = 0;
  Map<String, dynamic> _home = {};
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _loadItems(reset: true);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _loading ||
        _searching ||
        _loadingMore ||
        !_hasMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 420) {
      _loadItems();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('/medicine/home');
      final count = await _api.get('/medicine/cart-count');
      if (!mounted) return;
      setState(() {
        _home = Map<String, dynamic>.from(data as Map);
        _cartCount = (count['count'] as num?)?.toInt() ?? 0;
      });
      await _loadItems(reset: true, showSpinner: false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadItems({bool reset = false, bool showSpinner = true}) async {
    if (_loadingMore || (_searching && !reset)) return;
    final query = _search.text.trim();
    final nextPage = reset ? 1 : _page + 1;
    final serial = ++_requestSerial;
    setState(() {
      if (reset) {
        _page = 1;
        _hasMore = true;
      }
      if (reset && showSpinner) {
        _searching = true;
      } else if (!reset) {
        _loadingMore = true;
      }
    });
    try {
      final data = await _api.get(
        '/medicine/items',
        query: {
          if (query.isNotEmpty) 'q': query,
          'page': '$nextPage',
          'per_page': '$_pageSize',
        },
      );
      if (!mounted || serial != _requestSerial) return;
      final rows = (data['data'] as List?) ?? [];
      final meta = data['meta'] is Map
          ? Map<String, dynamic>.from(data['meta'] as Map)
          : null;
      final currentPage = (meta?['current_page'] as num?)?.toInt() ?? nextPage;
      final lastPage = (meta?['last_page'] as num?)?.toInt();
      setState(() {
        _items = reset ? rows : [..._items, ...rows];
        _page = currentPage;
        _hasMore = lastPage == null
            ? rows.length >= _pageSize
            : currentPage < lastPage;
      });
    } finally {
      if (mounted && serial == _requestSerial) {
        setState(() {
          _searching = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _openCart() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MedicineCartScreen()));
    await _load();
  }

  Future<void> _addToCart(Map<String, dynamic> item) async {
    await _api.post(
      '/medicine/cart/items',
      body: {'medicine_item_id': item['id'], 'quantity': 1},
    );
    final count = await _api.get('/medicine/cart-count');
    if (!mounted) return;
    setState(
      () => _cartCount = (count['count'] as num?)?.toInt() ?? _cartCount + 1,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['brand_name']} কার্টে যোগ হয়েছে')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final promoted = (_home['promoted_items'] as List?) ?? [];
    return Scaffold(
      backgroundColor: const Color(0xfff6faf8),
      appBar: ModernAppBar(
        title: 'মেডিসিন ডেলিভারি',
        subtitle: 'প্রয়োজনীয় ওষুধ, ঠিকানা, পেমেন্ট এক জায়গায়',
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: _openCart,
                icon: const Icon(Icons.shopping_bag_outlined),
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: const Color(0xffdc2626),
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  _MedicineSearchField(
                    controller: _search,
                    searching: _searching,
                  ),
                  const SizedBox(height: 16),
                  _MedicineHero(
                    total: (_home['total_items'] as num?)?.toInt() ?? 0,
                    onCart: _openCart,
                    cartCount: _cartCount,
                  ),
                  if (promoted.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const _SectionTitle(
                      title: 'Promoted Medicine',
                      subtitle: 'দ্রুত পাওয়া যায় এমন প্রয়োজনীয় আইটেম',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 178,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (_, i) => SizedBox(
                          width: 248,
                          child: _MedicineCard(
                            item: Map<String, dynamic>.from(promoted[i] as Map),
                            compact: true,
                            onAdd: _addToCart,
                          ),
                        ),
                        separatorBuilder: (_, index) =>
                            const SizedBox(width: 12),
                        itemCount: promoted.length,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  const _SectionTitle(
                    title: 'সব মেডিসিন',
                    subtitle: 'জেনেরিক, শক্তি, কোম্পানি দেখে বেছে নিন',
                  ),
                  const SizedBox(height: 12),
                  if (_items.isEmpty)
                    _EmptyMedicine(
                      text: _searching
                          ? 'মেডিসিন খোঁজা হচ্ছে...'
                          : 'কোনো মেডিসিন পাওয়া যায়নি',
                    )
                  else
                    ..._items.map(
                      (raw) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MedicineCard(
                          item: Map<String, dynamic>.from(raw as Map),
                          onAdd: _addToCart,
                        ),
                      ),
                    ),
                  if (_loadingMore) ...[
                    const SizedBox(height: 10),
                    const Center(child: LogoLoader(size: 28)),
                  ] else if (!_hasMore && _items.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'সব ফলাফল দেখানো হয়েছে',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class MedicineCartScreen extends StatefulWidget {
  const MedicineCartScreen({super.key});

  @override
  State<MedicineCartScreen> createState() => _MedicineCartScreenState();
}

class _MedicineCartScreenState extends State<MedicineCartScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  Map<String, dynamic> _cart = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('/medicine/cart');
      if (!mounted) return;
      setState(() => _cart = Map<String, dynamic>.from(data as Map));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _qty(int id, int quantity) async {
    if (quantity < 1) return;
    await _api.post('/medicine/cart/items/$id', body: {'quantity': quantity});
    await _load();
  }

  Future<void> _remove(int id) async {
    await _api.delete('/medicine/cart/items/$id');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = (_cart['items'] as List?) ?? [];
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xfff6faf8),
      appBar: const ModernAppBar(
        title: 'মেডিসিন কার্ট',
        subtitle: 'পরিমাণ ও বিল যাচাই করুন',
      ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'মোট বিল',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '৳${_cart['grand_total'] ?? 0}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 144,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => const MedicineCheckoutScreen(),
                              ),
                            )
                            .then((_) => _load()),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('চেকআউট'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (items.isEmpty)
                    const _EmptyMedicine(text: 'কার্টে কোনো মেডিসিন নেই'),
                  if (items.isNotEmpty) ...[
                    _SectionBlockHeader(
                      icon: Icons.medical_services_outlined,
                      title: 'কার্টের মেডিসিন',
                      subtitle: '${items.length} টি আইটেম যোগ হয়েছে',
                    ),
                    const SizedBox(height: 12),
                    ...items.map((raw) {
                      final item = Map<String, dynamic>.from(raw as Map);
                      final id = (item['id'] as num).toInt();
                      final quantity = (item['quantity'] as num).toInt();
                      return _MedicineCartTile(
                        item: item,
                        onMinus: () => _qty(id, quantity - 1),
                        onPlus: () => _qty(id, quantity + 1),
                        onRemove: () => _remove(id),
                      );
                    }),
                    const SizedBox(height: 6),
                    _PriceBox(cart: _cart, itemLabel: 'মেডিসিন'),
                    const SizedBox(height: 90),
                  ],
                ],
              ),
            ),
    );
  }
}

class MedicineCheckoutScreen extends StatefulWidget {
  const MedicineCheckoutScreen({super.key});

  @override
  State<MedicineCheckoutScreen> createState() => _MedicineCheckoutScreenState();
}

class _MedicineCheckoutScreenState extends State<MedicineCheckoutScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _area = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  final _manualTransactionId = TextEditingController();
  final _paymentProofPicker = ImagePicker();
  bool _loading = true;
  bool _placing = false;
  bool _locating = false;
  bool _feeLoading = false;
  Map<String, dynamic> _cart = {};
  double? _deliveryLat;
  double? _deliveryLng;
  String? _locationStatus;
  String _paymentMethod = 'cash_on_delivery';
  XFile? _paymentProofPhoto;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _area.dispose();
    _address.dispose();
    _note.dispose();
    _manualTransactionId.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('/medicine/cart');
      if (!mounted) return;
      setState(() {
        _cart = Map<String, dynamic>.from(data as Map);
        final options = (_cart['payment_options'] as List?) ?? [];
        if (options.isNotEmpty &&
            !options.any((option) => option['method'] == _paymentMethod)) {
          _paymentMethod =
              options.first['method']?.toString() ?? 'cash_on_delivery';
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _captureLocation() async {
    setState(() {
      _locating = true;
      _locationStatus = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'লোকেশন সার্ভিস বন্ধ আছে। অনুগ্রহ করে চালু করুন।';
        });
        await Geolocator.openLocationSettings();
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _locationStatus =
              'লোকেশন permission না দিলে ডেলিভারি চার্জ হিসাব হবে না।';
        });
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus =
              'লোকেশন permission permanently বন্ধ আছে। App settings থেকে চালু করুন।';
        });
        await Geolocator.openAppSettings();
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _deliveryLat = position.latitude;
        _deliveryLng = position.longitude;
        _locationStatus =
            'বর্তমান লোকেশন নেওয়া হয়েছে: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      });
      await _refreshDeliveryCharge();
      return true;
    } catch (_) {
      setState(() {
        _locationStatus = 'লোকেশন নেওয়া যায়নি। আবার চেষ্টা করুন।';
      });
      return false;
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickLocationOnMap() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: _deliveryLat,
          initialLng: _deliveryLng,
          title: 'মেডিসিন ডেলিভারি লোকেশন',
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _deliveryLat = picked.lat;
      _deliveryLng = picked.lng;
      _locationStatus =
          'ম্যাপ থেকে লোকেশন নেওয়া হয়েছে: ${picked.lat.toStringAsFixed(5)}, ${picked.lng.toStringAsFixed(5)}';
    });
    await _refreshDeliveryCharge();
  }

  Future<void> _refreshDeliveryCharge() async {
    if (_deliveryLat == null || _deliveryLng == null) return;
    setState(() => _feeLoading = true);
    try {
      final res = await _api.post(
        '/medicine/delivery-charge-preview',
        body: {'delivery_lat': _deliveryLat, 'delivery_lng': _deliveryLng},
      );
      if (!mounted) return;
      setState(() {
        _cart = {
          ..._cart,
          'delivery_fee': res['delivery_fee'],
          'delivery_distance_km': res['delivery_distance_km'],
          'delivery_charge_mode': res['delivery_charge_mode'],
          'delivery_charge_label': res['delivery_charge_label'],
          'grand_total': res['grand_total'],
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cart = {..._cart, 'delivery_charge_label': '$e'};
      });
    } finally {
      if (mounted) setState(() => _feeLoading = false);
    }
  }

  Future<void> _pickPaymentProof() async {
    final image = await _paymentProofPicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (image == null) return;
    setState(() => _paymentProofPhoto = image);
  }

  Future<void> _place() async {
    if (_deliveryLat == null || _deliveryLng == null) {
      final ok = await _captureLocation();
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('অর্ডার করতে বর্তমান বা ম্যাপ লোকেশন লাগবে।'),
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('নাম, ফোন ও সম্পূর্ণ ঠিকানা দিন')),
      );
      return;
    }

    setState(() => _placing = true);
    try {
      final isManualPayment =
          _paymentMethod == 'manual_bkash' || _paymentMethod == 'manual_nagad';
      final payload = {
        'receiver_name': _name.text.trim(),
        'receiver_phone': _phone.text.trim(),
        'delivery_area': _area.text.trim().isEmpty ? null : _area.text.trim(),
        'delivery_address': _address.text.trim(),
        'payment_method': _paymentMethod,
        'order_note': _note.text.trim().isEmpty ? null : _note.text.trim(),
        'delivery_lat': _deliveryLat,
        'delivery_lng': _deliveryLng,
        'delivery_map_url':
            'https://www.google.com/maps/search/?api=1&query=$_deliveryLat,$_deliveryLng',
        if (isManualPayment && _manualTransactionId.text.trim().isNotEmpty)
          'manual_transaction_id': _manualTransactionId.text.trim(),
      };
      final res = _paymentProofPhoto == null
          ? await _api.post('/medicine/checkout', body: payload)
          : await _api.postMultipart(
              '/medicine/checkout',
              fields: payload.map(
                (key, value) => MapEntry(key, value == null ? '' : '$value'),
              ),
              files: {'payment_proof_photo': _paymentProofPhoto!.path},
            );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MedicineOrderDetailsScreen(
            order: Map<String, dynamic>.from(res['order'] as Map),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (_cart['items'] as List?) ?? [];
    return Scaffold(
      backgroundColor: const Color(0xfff6faf8),
      appBar: const ModernAppBar(
        title: 'মেডিসিন চেকআউট',
        subtitle: 'লোকেশন, ঠিকানা ও পেমেন্ট',
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _placing || items.isEmpty ? null : _place,
            icon: _placing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.local_shipping_outlined),
            label: Text(_placing ? 'অর্ডার হচ্ছে...' : 'অর্ডার কনফার্ম করুন'),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PriceBox(
                  cart: _cart,
                  itemLabel: 'মেডিসিন',
                  loading: _feeLoading,
                ),
                const SizedBox(height: 14),
                _DeliveryLocationCard(
                  locating: _locating,
                  lat: _deliveryLat,
                  lng: _deliveryLng,
                  status: _locationStatus,
                  onCurrentLocation: _captureLocation,
                  onPickMap: _pickLocationOnMap,
                ),
                const SizedBox(height: 14),
                const _SectionBlockHeader(
                  icon: Icons.home_work_outlined,
                  title: 'ডেলিভারি ঠিকানা',
                  subtitle: 'রাইডার যেন সহজে বাসা খুঁজে পায়',
                ),
                const SizedBox(height: 12),
                _CheckoutField(controller: _name, label: 'রিসিভারের নাম'),
                _CheckoutField(
                  controller: _phone,
                  label: 'মোবাইল নম্বর',
                  keyboardType: TextInputType.phone,
                ),
                _CheckoutField(controller: _area, label: 'এলাকা'),
                _CheckoutField(
                  controller: _address,
                  label: 'সম্পূর্ণ ঠিকানা',
                  maxLines: 3,
                ),
                _CheckoutField(
                  controller: _note,
                  label: 'অর্ডার নোট',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                CheckoutPaymentSection(
                  options: (_cart['payment_options'] as List?) ?? const [],
                  selectedMethod: _paymentMethod,
                  total: _cart['grand_total'],
                  onChanged: (method) =>
                      setState(() => _paymentMethod = method),
                  emptyText: 'মেডিসিনের জন্য এখন কোনো পেমেন্ট পদ্ধতি চালু নেই।',
                ),
                if ((_cart['payment_notice']?.toString().trim() ?? '')
                    .isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _PaymentNoticeCard(text: _cart['payment_notice'].toString()),
                ],
                if (_paymentMethod == 'manual_bkash' ||
                    _paymentMethod == 'manual_nagad') ...[
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final option = _selectedPaymentOption();
                      return _ManualPaymentProofCard(
                        transactionId: _manualTransactionId,
                        proof: _paymentProofPhoto,
                        proofRequired: option?['requires_proof'] == true,
                        onPick: _pickPaymentProof,
                        onRemove: () =>
                            setState(() => _paymentProofPhoto = null),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 84),
              ],
            ),
    );
  }

  Map<dynamic, dynamic>? _selectedPaymentOption() {
    for (final raw in (_cart['payment_options'] as List?) ?? const []) {
      if (raw is Map && raw['method'] == _paymentMethod) {
        return raw;
      }
    }
    return null;
  }
}

class MedicineOrderDetailsScreen extends StatelessWidget {
  const MedicineOrderDetailsScreen({super.key, required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List?) ?? [];
    return Scaffold(
      backgroundColor: const Color(0xfff6faf8),
      appBar: ModernAppBar(
        title: '${order['order_no'] ?? 'Medicine Order'}',
        subtitle: 'অর্ডার ডিটেইলস',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OrderStatusCard(order: order),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'মেডিসিন',
            icon: Icons.medical_services_outlined,
            lines: items.map((e) {
              final item = Map<String, dynamic>.from(e as Map);
              return '${item['brand_name']} - ${item['quantity']} pcs • ৳${item['total_price']}';
            }).toList(),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'ডেলিভারি',
            icon: Icons.location_on_outlined,
            lines: [
              '${order['receiver_name']}',
              '${order['receiver_phone']}',
              '${order['delivery_address']}',
              if (order['delivery_distance_km'] != null)
                'দূরত্ব: ${order['delivery_distance_km']} KM',
            ],
          ),
          const SizedBox(height: 12),
          _PriceBox(cart: order, itemLabel: 'মেডিসিন'),
        ],
      ),
    );
  }
}

class MedicineDetailsScreen extends StatefulWidget {
  const MedicineDetailsScreen({super.key, required this.id});
  final int id;

  @override
  State<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends State<MedicineDetailsScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  Map<String, dynamic>? _item;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.get('/medicine/items/${widget.id}');
    if (mounted) setState(() => _item = Map<String, dynamic>.from(data as Map));
  }

  Future<void> _add() async {
    final item = _item;
    if (item == null) return;
    setState(() => _adding = true);
    try {
      await _api.post(
        '/medicine/cart/items',
        body: {'medicine_item_id': item['id'], 'quantity': 1},
      );
      if (mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MedicineCartScreen()));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return Scaffold(
      backgroundColor: const Color(0xfff6faf8),
      appBar: ModernAppBar(
        title: item?['brand_name']?.toString() ?? 'Medicine',
        subtitle: item?['generic_name']?.toString() ?? 'Details',
      ),
      bottomNavigationBar: item == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _adding ? null : _add,
                  icon: _adding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_shopping_cart),
                  label: Text(_adding ? 'যোগ হচ্ছে...' : 'কার্টে যোগ করুন'),
                ),
              ),
            ),
      body: item == null
          ? const Center(child: LogoLoader(showLabel: true))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xffdbeee8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: _MedicineImage(
                          url: item['image_url']?.toString(),
                          size: 104,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (item['prescription_required'] == true)
                        const _Badge(text: 'Prescription required'),
                      Text(
                        '${item['brand_name']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        [item['strength'], item['dosage_form']]
                            .where((e) => e != null && '$e'.isNotEmpty)
                            .join(' • '),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        medicinePriceText(item, emptyText: 'Price update soon'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Color(0xff087464),
                        ),
                      ),
                      if (item['pack_sizes'] != null)
                        Text('Pack: ${medicinePlainText(item['pack_sizes'])}'),
                      if (item['company'] != null)
                        Text('Company: ${item['company']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                for (final entry in {
                  'ব্যবহার': item['indications'],
                  'Composition': item['composition'],
                  'Dosage': item['dosage_and_administration'],
                  'Side effects': item['side_effects'],
                  'Precautions': item['precautions_and_warnings'],
                  'Storage': item['storage_conditions'],
                }.entries)
                  if (entry.value != null && '${entry.value}'.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _InfoCard(
                        title: entry.key,
                        icon: Icons.info_outline,
                        lines: [medicinePlainText(entry.value)],
                      ),
                    ),
                const SizedBox(height: 84),
              ],
            ),
    );
  }
}

class _MedicineSearchField extends StatelessWidget {
  const _MedicineSearchField({
    required this.controller,
    required this.searching,
  });
  final TextEditingController controller;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'মেডিসিন, জেনেরিক বা কোম্পানি খুঁজুন',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: searching
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: LogoLoader(size: 18),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}

String medicinePriceText(
  Map<String, dynamic> item, {
  String emptyText = 'N/A',
}) {
  final unitPrice = item['unit_price'];
  if (unitPrice != null && '$unitPrice'.trim().isNotEmpty) {
    final parsed = num.tryParse('$unitPrice');
    if (parsed != null && parsed > 0) return '৳$unitPrice / pcs';
  }

  final priceText = item['price_text']?.toString().trim();
  if (priceText != null && priceText.isNotEmpty) {
    return medicinePlainText(priceText);
  }

  return emptyText;
}

String medicinePlainText(dynamic value) {
  var text = value?.toString() ?? '';
  if (text.trim().isEmpty) return '';

  text = _decodeHtmlEntities(text);
  text = text
      .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
      .replaceAll(
        RegExp(r'<\s*/\s*(p|div|ul|ol|h[1-6])\s*>', caseSensitive: false),
        '\n',
      )
      .replaceAll(RegExp(r'<\s*li\b[^>]*>', caseSensitive: false), '\n• ')
      .replaceAll(RegExp(r'<\s*/\s*li\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  text = _decodeHtmlEntities(text);
  text = text
      .replaceAll(RegExp(r'[ \t\u00a0]+'), ' ')
      .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
      .trim();

  return text;
}

String _decodeHtmlEntities(String value) {
  return value
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&apos;', "'");
}

class _MedicineHero extends StatelessWidget {
  const _MedicineHero({
    required this.total,
    required this.onCart,
    required this.cartCount,
  });
  final int total;
  final VoidCallback onCart;
  final int cartCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff087464),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total+ বাংলাদেশি মেডিসিন',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'লোকেশন অনুযায়ী ডেলিভারি চার্জসহ অর্ডার করুন',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onCart,
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.item,
    required this.onAdd,
    this.compact = false,
  });

  final Map<String, dynamic> item;
  final bool compact;
  final Future<void> Function(Map<String, dynamic>) onAdd;

  @override
  Widget build(BuildContext context) {
    final price = medicinePriceText(item, emptyText: 'Price update soon');
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                MedicineDetailsScreen(id: (item['id'] as num).toInt()),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffdbeee8)),
          ),
          child: Row(
            children: [
              _MedicineImage(url: item['image_url']?.toString()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (item['is_promoted'] == true)
                          const _Badge(text: 'Promoted'),
                        if (item['prescription_required'] == true)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: _Badge(text: 'Rx'),
                          ),
                      ],
                    ),
                    Text(
                      '${item['brand_name']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      [
                        item['strength'],
                        item['dosage_form'],
                      ].where((e) => e != null && '$e'.isNotEmpty).join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${item['generic_name'] ?? item['company'] ?? ''}',
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      price,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xff087464),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => onAdd(item),
                icon: const Icon(Icons.add_shopping_cart),
                tooltip: 'Add to cart',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicineCartTile extends StatelessWidget {
  const _MedicineCartTile({
    required this.item,
    required this.onMinus,
    required this.onPlus,
    required this.onRemove,
  });

  final Map<String, dynamic> item;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final medicine = Map<String, dynamic>.from(
      (item['medicine_item'] as Map?) ?? {},
    );
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _MedicineImage(url: medicine['image_url']?.toString(), size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${medicine['brand_name'] ?? 'Medicine'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${medicine['strength'] ?? ''} • ${medicinePriceText({...medicine, 'unit_price': item['unit_price']})} x $qty',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '৳${item['total_price']}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            _QtyStepper(
              quantity: qty,
              onMinus: qty > 1 ? onMinus : null,
              onPlus: onPlus,
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            onPressed: onMinus,
            icon: const Icon(Icons.remove_rounded, size: 18),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            onPressed: onPlus,
            icon: const Icon(Icons.add_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _DeliveryLocationCard extends StatelessWidget {
  const _DeliveryLocationCard({
    required this.locating,
    required this.lat,
    required this.lng,
    required this.status,
    required this.onCurrentLocation,
    required this.onPickMap,
  });

  final bool locating;
  final double? lat;
  final double? lng;
  final String? status;
  final Future<bool> Function() onCurrentLocation;
  final VoidCallback onPickMap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasLocation = lat != null && lng != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: hasLocation
              ? scheme.primary.withValues(alpha: 0.35)
              : scheme.outlineVariant.withValues(alpha: 0.72),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasLocation
                    ? Icons.location_on_rounded
                    : Icons.my_location_rounded,
                color: hasLocation ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ডেলিভারি লোকেশন',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasLocation
                          ? 'লোকেশন নেওয়া হয়েছে। দূরত্ব অনুযায়ী চার্জ আপডেট হবে।'
                          : 'বর্তমান লোকেশন বা ম্যাপ থেকে পিন দিন।',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: 10),
            Text(
              status!,
              style: TextStyle(
                color: hasLocation ? scheme.primary : scheme.error,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: locating ? null : onCurrentLocation,
                  icon: locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  label: Text(locating ? 'নেওয়া হচ্ছে...' : 'Current'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickMap,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Map'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManualPaymentProofCard extends StatelessWidget {
  const _ManualPaymentProofCard({
    required this.transactionId,
    required this.proof,
    required this.proofRequired,
    required this.onPick,
    required this.onRemove,
  });

  final TextEditingController transactionId;
  final XFile? proof;
  final bool proofRequired;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ম্যানুয়াল পেমেন্ট প্রুফ',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: transactionId,
              decoration: const InputDecoration(
                labelText: 'Transaction ID',
                hintText: 'যেমন: 9AB12CDE34',
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.image_outlined, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      proof == null
                          ? proofRequired
                                ? 'স্ক্রিনশট প্রুফ বাধ্যতামূলক।'
                                : 'স্ক্রিনশট প্রুফ optional, দিলে যাচাই সহজ হবে।'
                          : proof!.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (proof != null)
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Remove',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(
                  proof == null
                      ? 'Screenshot proof যোগ করুন'
                      : 'Screenshot পরিবর্তন করুন',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentNoticeCard extends StatelessWidget {
  const _PaymentNoticeCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfffffbeb),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xfffde68a)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xff92400e),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  const _PriceBox({
    required this.cart,
    required this.itemLabel,
    this.loading = false,
  });

  final Map<String, dynamic> cart;
  final String itemLabel;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _priceRow('$itemLabel দাম', cart['items_total']),
            _priceRow(
              'ডেলিভারি চার্জ',
              loading ? '...' : cart['delivery_fee'],
              pendingText: cart['delivery_fee'] == null ? 'লোকেশন লাগবে' : null,
            ),
            if (cart['delivery_distance_km'] != null ||
                cart['delivery_charge_label'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    [
                      if (cart['delivery_distance_km'] != null)
                        'দূরত্ব ${cart['delivery_distance_km']} KM',
                      if (cart['delivery_charge_label'] != null)
                        '${cart['delivery_charge_label']}',
                    ].join(' • '),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const Divider(),
            _priceRow('মোট', cart['grand_total'], strong: true),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(
    String label,
    dynamic value, {
    bool strong = false,
    String? pendingText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          Text(
            pendingText ?? (value == '...' ? '...' : '৳${value ?? 0}'),
            style: TextStyle(
              fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff087464),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '৳${order['grand_total'] ?? 0}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'অর্ডার: ${order['status']} • পেমেন্ট: ${order['payment_status']}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'পেমেন্ট পদ্ধতি: ${order['payment_method'] ?? 'cash_on_delivery'}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.86)),
          ),
        ],
      ),
    );
  }
}

class _MedicineImage extends StatelessWidget {
  const _MedicineImage({this.url, this.size = 58});
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasImage = url != null && url!.startsWith('http');
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xffe7f5f0),
        child: hasImage
            ? Image.network(url!, fit: BoxFit.cover)
            : const Icon(
                Icons.local_pharmacy,
                color: Color(0xff087464),
                size: 30,
              ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
      ],
    );
  }
}

class _SectionBlockHeader extends StatelessWidget {
  const _SectionBlockHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xff087464)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xfffff1d6),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: Color(0xff9a5a00),
        fontSize: 11,
      ),
    ),
  );
}

class _EmptyMedicine extends StatelessWidget {
  const _EmptyMedicine({this.text = 'কোনো মেডিসিন পাওয়া যায়নি'});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        const Icon(Icons.search_off, size: 42),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _CheckoutField extends StatelessWidget {
  const _CheckoutField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.lines,
    required this.icon,
  });

  final String title;
  final List<String> lines;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xffe0ece7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xff087464)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        ...lines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(line),
          ),
        ),
      ],
    ),
  );
}
