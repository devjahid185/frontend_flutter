import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/widgets/location_picker_screen.dart';
import '../common/image_upload_preview.dart';
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
  String? _selectedDosageForm;
  final Set<int> _addingItemIds = {};
  final Set<int> _addedItemIds = {};
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

  void _selectDosageForm(String? value) {
    setState(() => _selectedDosageForm = value);
    _loadItems(reset: true);
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
    final dosageForm = _selectedDosageForm;
    final nextPage = reset ? 1 : _page + 1;
    final serial = ++_requestSerial;
    final queryParams = {
      if (query.isNotEmpty) 'q': query,
      'page': '$nextPage',
      'per_page': '$_pageSize',
    };
    if (dosageForm != null) {
      queryParams['dosage_form'] = dosageForm;
    }
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
      final data = await _api.get('/medicine/items', query: queryParams);
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

  Future<void> _openOrders() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MedicineOrdersScreen()));
  }

  Future<void> _addToCart(Map<String, dynamic> item) async {
    final id = (item['id'] as num?)?.toInt();
    if (id == null || _addingItemIds.contains(id)) return;
    setState(() => _addingItemIds.add(id));
    try {
      await _api.post(
        '/medicine/cart/items',
        body: {'medicine_item_id': id, 'quantity': 1},
      );
      final count = await _api.get('/medicine/cart-count');
      if (!mounted) return;
      setState(() {
        _cartCount = (count['count'] as num?)?.toInt() ?? _cartCount + 1;
        _addedItemIds.add(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item['brand_name']} কার্টে যোগ হয়েছে')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      setState(() => _addedItemIds.remove(id));
    } finally {
      if (mounted) setState(() => _addingItemIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final promoted = (_home['promoted_items'] as List?) ?? [];
    final dosageForms = ((_home['dosage_forms'] as List?) ?? [])
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return Scaffold(
      backgroundColor: const Color(0xfff6faf8),
      appBar: ModernAppBar(
        title: 'মেডিসিন ডেলিভারি',
        subtitle: 'প্রয়োজনীয় ওষুধ, ঠিকানা, পেমেন্ট এক জায়গায়',
        actions: [
          IconButton(
            onPressed: _openOrders,
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'My orders',
          ),
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
                  if (dosageForms.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _DosageFilterChips(
                      forms: dosageForms,
                      selected: _selectedDosageForm,
                      onSelected: _selectDosageForm,
                    ),
                  ],
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
                            adding: _addingItemIds.contains(
                              (promoted[i]['id'] as num?)?.toInt(),
                            ),
                            added: _addedItemIds.contains(
                              (promoted[i]['id'] as num?)?.toInt(),
                            ),
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
                          adding: _addingItemIds.contains(
                            (raw['id'] as num?)?.toInt(),
                          ),
                          added: _addedItemIds.contains(
                            (raw['id'] as num?)?.toInt(),
                          ),
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
      final order = Map<String, dynamic>.from(res['order'] as Map);
      if (_paymentMethod == 'bkash_tokenized') {
        await _openBkashPayment(order);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MedicineOrderDetailsScreen(initialOrder: order),
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
                _MedicineOrderItemsCard(
                  title: 'অর্ডারের মেডিসিন',
                  subtitle: 'প্রতি আইটেমের দাম ও পরিমাণ যাচাই করুন',
                  items: items,
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

  Future<void> _openBkashPayment(Map<String, dynamic> order) async {
    final id = (order['id'] as num?)?.toInt();
    final url = '${order['bkash_url'] ?? ''}'.trim();
    if (url.isEmpty || id == null) return;
    final result = await Navigator.of(context).push<BkashPaymentResult>(
      MaterialPageRoute(
        builder: (_) => BkashPaymentWebViewScreen(
          initialUrl: url,
          callbackUrl: '${AppConfig.apiBaseUrl}/medicine/bkash/callback',
        ),
      ),
    );
    if (!mounted) return;
    if (result?.paymentId != null) {
      order['bkash_payment_id'] = result!.paymentId;
    }
    final status = result?.status?.toLowerCase();
    if (status == null) return;
    if (status != 'success') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_bkashResultMessage(status))));
      return;
    }
    final res = await _api.post(
      '/medicine/orders/$id/bkash/execute',
      body: {if (result?.paymentId != null) 'payment_id': result!.paymentId},
    );
    final paidOrder = res['order'] is Map
        ? Map<String, dynamic>.from(res['order'] as Map)
        : null;
    if (paidOrder != null) {
      order
        ..clear()
        ..addAll(paidOrder);
    }
  }
}

class MedicineOrdersScreen extends StatefulWidget {
  const MedicineOrdersScreen({super.key});

  @override
  State<MedicineOrdersScreen> createState() => _MedicineOrdersScreenState();
}

class _MedicineOrdersScreenState extends State<MedicineOrdersScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  String? _error;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.get('/medicine/orders');
      if (!mounted) return;
      setState(() => _orders = (data['data'] as List?) ?? []);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xfff6faf8),
      appBar: const ModernAppBar(
        title: 'মেডিসিন অর্ডার',
        subtitle: 'আপনার সব অর্ডার ও পেমেন্ট',
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    _InfoCard(
                      title: 'লোড হয়নি',
                      icon: Icons.error_outline,
                      lines: [_error!],
                    )
                  else if (_orders.isEmpty)
                    const _EmptyMedicine(text: 'এখনো কোনো মেডিসিন অর্ডার নেই')
                  else
                    ..._orders.map((raw) {
                      final order = Map<String, dynamic>.from(raw as Map);
                      final items = (order['items'] as List?) ?? const [];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MedicineOrderDetailsScreen(
                                  orderId: (order['id'] as num).toInt(),
                                  initialOrder: order,
                                ),
                              ),
                            );
                            await _load();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${order['order_no'] ?? 'Medicine Order'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    _MedicineStatusChip(
                                      status:
                                          '${order['payment_status'] ?? 'unpaid'}',
                                      compact: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${items.length} item • ৳${order['grand_total'] ?? 0}',
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    _MedicineStatusChip(
                                      status: '${order['status'] ?? 'pending'}',
                                      compact: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_shipping_outlined,
                                      color: scheme.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${order['delivery_address'] ?? ''}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class MedicineOrderDetailsScreen extends StatefulWidget {
  const MedicineOrderDetailsScreen({
    super.key,
    this.orderId,
    this.initialOrder,
  });

  final int? orderId;
  final Map<String, dynamic>? initialOrder;

  @override
  State<MedicineOrderDetailsScreen> createState() =>
      _MedicineOrderDetailsScreenState();
}

class _MedicineOrderDetailsScreenState
    extends State<MedicineOrderDetailsScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  final _paymentTransactionId = TextEditingController();
  final _paymentProofPicker = ImagePicker();
  Map<String, dynamic> _order = {};
  bool _loading = true;
  bool _paymentSubmitting = false;
  XFile? _paymentProofPhoto;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder ?? {};
    if (widget.orderId == null && _order.isNotEmpty) {
      _loading = false;
      _paymentTransactionId.text = '${_order['manual_transaction_id'] ?? ''}'
          .trim();
    } else {
      _load();
    }
    _poller = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    _paymentTransactionId.dispose();
    super.dispose();
  }

  int? get _orderId => widget.orderId ?? (_order['id'] as num?)?.toInt();

  bool get _shouldShowPayNow {
    final method = '${_order['payment_method'] ?? ''}';
    final status = '${_order['payment_status'] ?? 'unpaid'}';
    return (method == 'manual_bkash' ||
            method == 'manual_nagad' ||
            method == 'bkash_tokenized') &&
        status != 'paid';
  }

  bool get _isBkashTokenized =>
      '${_order['payment_method'] ?? ''}' == 'bkash_tokenized';

  Future<void> _load({bool silent = false}) async {
    final id = _orderId;
    if (id == null) return;
    if (!silent) setState(() => _loading = true);
    try {
      final data = await _api.get('/medicine/orders/$id');
      if (!mounted) return;
      setState(() {
        _order = Map<String, dynamic>.from(data as Map);
        if (_paymentTransactionId.text.trim().isEmpty) {
          _paymentTransactionId.text =
              '${_order['manual_transaction_id'] ?? ''}'.trim();
        }
        _loading = false;
      });
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Map<dynamic, dynamic>? _manualPaymentOption() {
    final method = '${_order['payment_method'] ?? ''}';
    for (final raw in (_order['payment_options'] as List?) ?? const []) {
      if (raw is Map && raw['method'] == method) return raw;
    }
    return null;
  }

  Future<void> _pickOrderPaymentProof() async {
    final image = await _paymentProofPicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (image == null) return;
    setState(() => _paymentProofPhoto = image);
  }

  Future<void> _submitOrderPaymentProof() async {
    final id = _orderId;
    if (id == null) return;
    if (_paymentTransactionId.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction ID দিন')));
      return;
    }
    setState(() => _paymentSubmitting = true);
    try {
      final fields = {
        'manual_transaction_id': _paymentTransactionId.text.trim(),
      };
      final res = _paymentProofPhoto == null
          ? await _api.post('/medicine/orders/$id/payment-proof', body: fields)
          : await _api.postMultipart(
              '/medicine/orders/$id/payment-proof',
              fields: fields,
              files: {'payment_proof_photo': _paymentProofPhoto!.path},
            );
      if (!mounted) return;
      final order = res['order'] is Map
          ? Map<String, dynamic>.from(res['order'] as Map)
          : null;
      setState(() {
        if (order != null) _order = order;
        _paymentProofPhoto = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('পেমেন্ট তথ্য যাচাইয়ের জন্য পাঠানো হয়েছে'),
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _paymentSubmitting = false);
    }
  }

  Future<void> _payWithBkash() async {
    final id = _orderId;
    if (id == null) return;
    setState(() => _paymentSubmitting = true);
    try {
      final createRes = await _api.post('/medicine/orders/$id/bkash/create');
      final createdOrder = createRes['order'] is Map
          ? Map<String, dynamic>.from(createRes['order'] as Map)
          : null;
      if (createdOrder != null) {
        _order = createdOrder;
      }
      final url = '${createdOrder?['bkash_url'] ?? _order['bkash_url'] ?? ''}'
          .trim();
      if (url.isEmpty) {
        throw ApiException('bKash payment URL পাওয়া যায়নি।', 422);
      }
      if (!mounted) return;
      final result = await Navigator.of(context).push<BkashPaymentResult>(
        MaterialPageRoute(
          builder: (_) => BkashPaymentWebViewScreen(
            initialUrl: url,
            callbackUrl: '${AppConfig.apiBaseUrl}/medicine/bkash/callback',
          ),
        ),
      );
      if (!mounted) return;
      final status = result?.status?.toLowerCase();
      if (status == null) return;
      if (status != 'success') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_bkashResultMessage(status))));
        return;
      }
      final res = await _api.post(
        '/medicine/orders/$id/bkash/execute',
        body: {if (result?.paymentId != null) 'payment_id': result!.paymentId},
      );
      final order = res['order'] is Map
          ? Map<String, dynamic>.from(res['order'] as Map)
          : null;
      if (!mounted) return;
      setState(() {
        if (order != null) _order = order;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Payment checked'),
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _paymentSubmitting = false);
    }
  }

  Future<void> _openOrderMap() async {
    final deliveryLat = readDouble(_order['delivery_lat']);
    final deliveryLng = readDouble(_order['delivery_lng']);
    if (deliveryLat == null || deliveryLng == null) return;

    final pickup = _order['restaurant'] is Map
        ? Map<String, dynamic>.from(_order['restaurant'] as Map)
        : <String, dynamic>{};
    final rider = _order['rider'] is Map
        ? Map<String, dynamic>.from(_order['rider'] as Map)
        : <String, dynamic>{};
    final markers = <AppMapMarker>[];
    final pickupLat = readDouble(pickup['lat']);
    final pickupLng = readDouble(pickup['lng']);
    if (pickupLat != null && pickupLng != null) {
      markers.add(
        AppMapMarker(
          lat: pickupLat,
          lng: pickupLng,
          label: pickup['name']?.toString() ?? 'মেডিসিন পিকআপ',
          icon: Icons.medical_services_outlined,
          color: Colors.deepOrange,
        ),
      );
    }
    markers.add(
      AppMapMarker(
        lat: deliveryLat,
        lng: deliveryLng,
        label: _order['receiver_name']?.toString() ?? 'ডেলিভারি ঠিকানা',
        icon: Icons.location_city_rounded,
      ),
    );
    final riderLat = readDouble(rider['last_lat']);
    final riderLng = readDouble(rider['last_lng']);
    if (riderLat != null && riderLng != null) {
      markers.add(
        AppMapMarker(
          lat: riderLat,
          lng: riderLng,
          label: rider['name']?.toString() ?? 'রাইডার',
          icon: Icons.delivery_dining,
          color: Colors.green,
        ),
      );
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: riderLat ?? deliveryLat,
          initialLng: riderLng ?? deliveryLng,
          title: riderLat != null
              ? 'লাইভ ডেলিভারি ট্র্যাকিং'
              : 'কাস্টমার ডেলিভারি লোকেশন',
          readOnly: true,
          markers: markers,
        ),
      ),
    );
  }

  Future<void> _openProof(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (_order['items'] as List?) ?? [];
    final proofUrl = '${_order['payment_proof_photo_url'] ?? ''}'.trim();
    final hasMap =
        (_order['delivery_map_url']?.toString().isNotEmpty == true) ||
        (_order['delivery_lat'] != null && _order['delivery_lng'] != null);
    return Scaffold(
      backgroundColor: const Color(0xfff6faf8),
      appBar: ModernAppBar(
        title: '${_order['order_no'] ?? 'Medicine Order'}',
        subtitle: 'স্ট্যাটাস, পেমেন্ট ও ডেলিভারি',
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _OrderStatusCard(order: _order),
                  const SizedBox(height: 14),
                  _MedicineOrderItemsCard(
                    title: 'অর্ডারের মেডিসিন',
                    subtitle: '${items.length} টি আইটেম',
                    items: items,
                  ),
                  const SizedBox(height: 12),
                  _PriceBox(cart: _order, itemLabel: 'মেডিসিন'),
                  const SizedBox(height: 14),
                  if (_shouldShowPayNow) ...[
                    _isBkashTokenized
                        ? _BkashTokenizedPayCard(
                            order: _order,
                            submitting: _paymentSubmitting,
                            onPay: _payWithBkash,
                          )
                        : _MedicinePayNowCard(
                            order: _order,
                            paymentOption: _manualPaymentOption(),
                            transactionId: _paymentTransactionId,
                            proof: _paymentProofPhoto,
                            submitting: _paymentSubmitting,
                            onPick: _pickOrderPaymentProof,
                            onRemove: () =>
                                setState(() => _paymentProofPhoto = null),
                            onSubmit: _submitOrderPaymentProof,
                          ),
                    const SizedBox(height: 14),
                  ],
                  _MedicinePaymentInfoCard(
                    order: _order,
                    proofUrl: proofUrl,
                    onOpenProof: proofUrl.isEmpty
                        ? null
                        : () => _openProof(proofUrl),
                  ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    title: 'ডেলিভারি',
                    icon: Icons.location_on_outlined,
                    lines: [
                      '${_order['receiver_name'] ?? ''}',
                      '${_order['receiver_phone'] ?? ''}',
                      '${_order['delivery_address'] ?? ''}',
                      if ((_order['delivery_area']?.toString() ?? '')
                          .isNotEmpty)
                        'এলাকা: ${_order['delivery_area']}',
                      if (_order['delivery_distance_km'] != null)
                        'দূরত্ব: ${_order['delivery_distance_km']} KM',
                    ],
                  ),
                  if (hasMap) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _openOrderMap,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('ম্যাপে ডেলিভারি লোকেশন দেখুন'),
                    ),
                  ],
                  if ((_order['order_note']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _InfoCard(
                      title: 'অর্ডার নোট',
                      icon: Icons.notes_outlined,
                      lines: ['${_order['order_note']}'],
                    ),
                  ],
                ],
              ),
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
  bool _added = false;

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
        setState(() => _added = true);
        await Future<void>.delayed(const Duration(milliseconds: 650));
        if (!mounted) return;
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MedicineCartScreen()));
      }
    } finally {
      if (mounted) {
        setState(() {
          _adding = false;
          _added = false;
        });
      }
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
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _adding && !_added
                        ? const SizedBox(
                            key: ValueKey('adding'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _added
                                ? Icons.check_circle_rounded
                                : Icons.add_shopping_cart,
                            key: ValueKey(_added ? 'added' : 'add'),
                          ),
                  ),
                  label: Text(
                    _added
                        ? 'কার্টে যোগ হয়েছে'
                        : (_adding ? 'যোগ হচ্ছে...' : 'কার্টে যোগ করুন'),
                  ),
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

class _DosageFilterChips extends StatelessWidget {
  const _DosageFilterChips({
    required this.forms,
    required this.selected,
    required this.onSelected,
  });

  final List<String> forms;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: forms.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = index == 0 ? null : forms[index - 1];
          final active = selected == value;
          return ChoiceChip(
            selected: active,
            label: Text(value ?? 'সব'),
            avatar: Icon(
              value == null
                  ? Icons.medication_liquid_outlined
                  : _dosageIcon(value),
              size: 18,
              color: active ? scheme.onPrimary : scheme.primary,
            ),
            onSelected: (_) => onSelected(value),
            selectedColor: scheme.primary,
            labelStyle: TextStyle(
              color: active ? scheme.onPrimary : scheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(
              color: active
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.9),
            ),
          );
        },
      ),
    );
  }

  static IconData _dosageIcon(String form) {
    final value = form.toLowerCase();
    if (value.contains('syrup') ||
        value.contains('suspension') ||
        value.contains('drop')) {
      return Icons.medication_liquid_outlined;
    }
    if (value.contains('capsule')) return Icons.vaccines_outlined;
    if (value.contains('injection') || value.contains('infusion')) {
      return Icons.vaccines_outlined;
    }
    return Icons.medication_outlined;
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.item,
    required this.onAdd,
    this.compact = false,
    this.adding = false,
    this.added = false,
  });

  final Map<String, dynamic> item;
  final bool compact;
  final bool adding;
  final bool added;
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
              AnimatedScale(
                scale: added ? 1.12 : 1,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: IconButton.filledTonal(
                  onPressed: adding ? null : () => onAdd(item),
                  style: IconButton.styleFrom(
                    backgroundColor: added
                        ? const Color(0xffdcfce7)
                        : Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: added
                        ? const Color(0xff047857)
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: adding
                        ? const SizedBox(
                            key: ValueKey('adding'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            added
                                ? Icons.check_circle_rounded
                                : Icons.add_shopping_cart,
                            key: ValueKey(added ? 'added' : 'add'),
                          ),
                  ),
                  tooltip: 'Add to cart',
                ),
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
                    'Subtotal: ৳${item['total_price']}',
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

class _MedicineOrderItemsCard extends StatelessWidget {
  const _MedicineOrderItemsCard({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe0ece7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionBlockHeader(
            icon: Icons.medical_services_outlined,
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'কোনো আইটেম নেই',
              style: TextStyle(color: scheme.onSurfaceVariant),
            )
          else
            ...items.map((raw) {
              final item = Map<String, dynamic>.from(raw as Map);
              final medicine = Map<String, dynamic>.from(
                (item['medicine_item'] as Map?) ?? {},
              );
              final brand = item['brand_name'] ?? medicine['brand_name'];
              final generic = item['generic_name'] ?? medicine['generic_name'];
              final strength = item['strength'] ?? medicine['strength'];
              final qty = (item['quantity'] as num?)?.toInt() ?? 1;
              final unit = item['unit_price'] ?? medicine['unit_price'] ?? 0;
              final total = item['total_price'] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xfff6faf8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MedicineImage(
                      url: medicine['image_url']?.toString(),
                      size: 52,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$brand',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              if ('$generic'.trim().isNotEmpty) '$generic',
                              if ('$strength'.trim().isNotEmpty) '$strength',
                            ].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '৳$unit x $qty = ৳$total',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MedicinePayNowCard extends StatelessWidget {
  const _MedicinePayNowCard({
    required this.order,
    required this.paymentOption,
    required this.transactionId,
    required this.proof,
    required this.submitting,
    required this.onPick,
    required this.onRemove,
    required this.onSubmit,
  });

  final Map<String, dynamic> order;
  final Map<dynamic, dynamic>? paymentOption;
  final TextEditingController transactionId;
  final XFile? proof;
  final bool submitting;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final method = '${order['payment_method'] ?? ''}';
    final title = method == 'manual_nagad'
        ? 'Nagad পেমেন্ট সম্পন্ন করুন'
        : 'bKash পেমেন্ট সম্পন্ন করুন';
    final number = '${paymentOption?['number'] ?? ''}'.trim();
    final instructions = '${paymentOption?['instructions'] ?? ''}'.trim();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _PaymentNoticeCard(
              text:
                  '৳${order['grand_total'] ?? 0} পাঠিয়ে Transaction ID দিন। স্ক্রিনশট দিলে admin দ্রুত verify করতে পারবে।',
            ),
            if (number.isNotEmpty) ...[
              const SizedBox(height: 10),
              SelectableText(
                number,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            if (instructions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(instructions, style: const TextStyle(height: 1.4)),
            ],
            const SizedBox(height: 12),
            _ManualPaymentProofCard(
              transactionId: transactionId,
              proof: proof,
              proofRequired: paymentOption?['requires_proof'] == true,
              onPick: onPick,
              onRemove: onRemove,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: submitting ? null : onSubmit,
                icon: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_user_outlined),
                label: Text(
                  submitting ? 'পাঠানো হচ্ছে...' : 'পেমেন্ট তথ্য জমা দিন',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BkashTokenizedPayCard extends StatelessWidget {
  const _BkashTokenizedPayCard({
    required this.order,
    required this.submitting,
    required this.onPay,
  });

  final Map<String, dynamic> order;
  final bool submitting;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.open_in_browser_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'bKash Checkout পেমেন্ট',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _PaymentNoticeCard(
              text:
                  '৳${order['grand_total'] ?? 0} bKash checkout পেজে পেমেন্ট করুন। পেমেন্ট শেষে app-এ ফিরে verify করুন।',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: submitting ? null : onPay,
                icon: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.account_balance_wallet_rounded),
                label: Text(
                  submitting
                      ? 'পেমেন্ট যাচাই হচ্ছে...'
                      : 'bKash দিয়ে পেমেন্ট করুন',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BkashPaymentResult {
  const BkashPaymentResult({this.paymentId, this.status});

  final String? paymentId;
  final String? status;
}

String _bkashResultMessage(String status) {
  switch (status) {
    case 'success':
      return 'bKash পেমেন্ট সফল হয়েছে।';
    case 'failure':
    case 'failed':
      return 'bKash পেমেন্ট সফল হয়নি। আবার চেষ্টা করুন।';
    case 'cancel':
    case 'cancelled':
      return 'bKash পেমেন্ট বাতিল করা হয়েছে।';
    default:
      return 'bKash পেমেন্ট স্ট্যাটাস: $status';
  }
}

class BkashPaymentWebViewScreen extends StatefulWidget {
  const BkashPaymentWebViewScreen({
    super.key,
    required this.initialUrl,
    required this.callbackUrl,
  });

  final String initialUrl;
  final String callbackUrl;

  @override
  State<BkashPaymentWebViewScreen> createState() =>
      _BkashPaymentWebViewScreenState();
}

class _BkashPaymentWebViewScreenState extends State<BkashPaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => _loading = true);
            _handleCallback(url);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            if (_handleCallback(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  bool _handleCallback(String url) {
    if (_completed || !url.startsWith(widget.callbackUrl)) return false;
    _completed = true;
    final uri = Uri.tryParse(url);
    Navigator.of(context).pop(
      BkashPaymentResult(
        paymentId: uri?.queryParameters['paymentID'],
        status: uri?.queryParameters['status'],
      ),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'bKash পেমেন্ট',
        subtitle: 'নিরাপদ checkout',
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const LinearProgressIndicator(minHeight: 3),
        ],
      ),
    );
  }
}

class _MedicinePaymentInfoCard extends StatelessWidget {
  const _MedicinePaymentInfoCard({
    required this.order,
    required this.proofUrl,
    required this.onOpenProof,
  });

  final Map<String, dynamic> order;
  final String proofUrl;
  final VoidCallback? onOpenProof;

  @override
  Widget build(BuildContext context) {
    final method = '${order['payment_method'] ?? 'cash_on_delivery'}';
    final status = '${order['payment_status'] ?? 'unpaid'}';
    return _InfoCard(
      title: 'পেমেন্ট',
      icon: Icons.payments_outlined,
      lines: [
        'পদ্ধতি: ${_medicinePaymentLabel(method)}',
        'স্ট্যাটাস: ${_medicineStatusLabel(status)}',
        if (('${order['manual_transaction_id'] ?? ''}').trim().isNotEmpty)
          'Transaction ID: ${order['manual_transaction_id']}',
        if (proofUrl.isNotEmpty) 'Payment proof uploaded',
      ],
      action: proofUrl.isEmpty
          ? null
          : OutlinedButton.icon(
              onPressed: onOpenProof,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: const Text('Proof দেখুন'),
            ),
    );
  }
}

class _MedicineStatusChip extends StatelessWidget {
  const _MedicineStatusChip({required this.status, this.compact = false});

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isGood = normalized == 'paid' || normalized == 'delivered';
    final isBad = normalized == 'cancelled' || normalized == 'failed';
    final bg = isGood
        ? const Color(0xffdcfce7)
        : isBad
        ? const Color(0xffffe4e6)
        : const Color(0xfffff7ed);
    final fg = isGood
        ? const Color(0xff166534)
        : isBad
        ? const Color(0xffbe123c)
        : const Color(0xff9a3412);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _medicineStatusLabel(status),
        style: TextStyle(
          color: fg,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _medicineStatusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'মেডিসিন অর্ডার পাঠানো হয়েছে';
    case 'accepted':
      return 'মেডিসিন অর্ডার গ্রহণ হয়েছে';
    case 'processing':
    case 'preparing':
      return 'মেডিসিন প্রস্তুত করা হচ্ছে';
    case 'assigned':
      return 'রাইডার অ্যাসাইন হয়েছে';
    case 'picked_up':
      return 'মেডিসিন নেওয়া হয়েছে';
    case 'on_the_way':
      return 'মেডিসিন ডেলিভারির পথে';
    case 'delivered':
      return 'মেডিসিন ডেলিভারি সম্পন্ন';
    case 'cancelled':
      return 'মেডিসিন অর্ডার বাতিল';
    case 'rejected':
      return 'মেডিসিন অর্ডার গ্রহণ করা হয়নি';
    case 'paid':
      return 'পেমেন্ট সম্পন্ন';
    case 'unpaid':
      return 'পেমেন্ট বাকি';
    default:
      return status.replaceAll('_', ' ');
  }
}

String _medicinePaymentLabel(String method) {
  switch (method) {
    case 'cash_on_delivery':
      return 'Cash on delivery';
    case 'manual_bkash':
      return 'bKash manual';
    case 'bkash_tokenized':
      return 'bKash checkout';
    case 'manual_nagad':
      return 'Nagad manual';
    case 'online':
      return 'Online';
    default:
      return method.replaceAll('_', ' ');
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
            if (proof != null) ...[
              const SizedBox(height: 10),
              PickedImageHeroPreview(
                image: proof,
                height: 150,
                onTap: onPick,
                onRemove: onRemove,
              ),
            ],
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
    final status = '${order['status'] ?? 'pending'}';
    final paymentStatus = '${order['payment_status'] ?? 'unpaid'}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff087464),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order['order_no'] ?? 'Medicine Order'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _MedicineStatusChip(status: status, compact: true),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '৳${order['grand_total'] ?? 0}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _MedicineStatusChip(status: paymentStatus, compact: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _medicinePaymentLabel(
                    '${order['payment_method'] ?? 'cash_on_delivery'}',
                  ),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ),
            ],
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
    Widget fallback({IconData icon = Icons.local_pharmacy_rounded}) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffeefdf7), Color(0xffdff4ee)],
          ),
        ),
        child: Center(
          child: Icon(icon, color: const Color(0xff087464), size: size * 0.5),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xffe7f5f0),
        child: hasImage
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return fallback(icon: Icons.medication_outlined);
                },
              )
            : fallback(),
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
    this.action,
  });

  final String title;
  final List<String> lines;
  final IconData icon;
  final Widget? action;

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
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            ?action,
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
