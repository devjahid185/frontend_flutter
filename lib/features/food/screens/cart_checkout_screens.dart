part of '../food_home_screen.dart';

class FoodCartScreen extends StatefulWidget {
  const FoodCartScreen({super.key});

  @override
  State<FoodCartScreen> createState() => _FoodCartScreenState();
}

class _FoodCartScreenState extends State<FoodCartScreen> {
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
      final data = await _api.get('/food/cart');
      setState(() => _cart = Map<String, dynamic>.from(data as Map));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _qty(int id, int q) async {
    if (q < 1) return;
    await _api.post('/food/cart/items/$id', body: {'quantity': q});
    _load();
  }

  Future<void> _remove(int id) async {
    await _api.delete('/food/cart/items/$id');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = (_cart['items'] as List?) ?? [];
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      bottomNavigationBar: items.isEmpty
          ? null
          : _FoodFlowBottomAction(
              label: 'চেকআউট করুন',
              amount: _cart['grand_total'],
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FoodCheckoutScreen()),
              ),
            ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                children: [
                  _FoodFlowHeader(
                    title: 'আপনার কার্ট',
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  if (items.isEmpty)
                    const _EmptyFoodState(
                      text:
                          '\u0995\u09be\u09b0\u09cd\u099f \u0996\u09be\u09b2\u09bf \u0986\u099b\u09c7',
                    ),
                  if (items.isNotEmpty) ...[
                    _FoodCartRestaurantCard(cart: _cart),
                    const SizedBox(height: 14),
                  ],
                  ...items.map((raw) {
                    final item = Map<String, dynamic>.from(raw as Map);
                    final id = (item['id'] as num).toInt();
                    final quantity = (item['quantity'] as num).toInt();
                    return _FoodCartItemCard(
                      item: item,
                      onMinus: () => _qty(id, quantity - 1),
                      onPlus: () => _qty(id, quantity + 1),
                      onRemove: () => _remove(id),
                    );
                  }),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _AddMoreFoodButton(
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 14),
                    _FoodBillSummaryCard(cart: _cart, loading: false),
                    const SizedBox(height: 96),
                  ],
                ],
              ),
            ),
    );
  }
}

class FoodCheckoutScreen extends StatefulWidget {
  const FoodCheckoutScreen({super.key});

  @override
  State<FoodCheckoutScreen> createState() => _FoodCheckoutScreenState();
}

class _FoodCheckoutScreenState extends State<FoodCheckoutScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _area = TextEditingController();
  final _address = TextEditingController();
  final _landmark = TextEditingController();
  final _note = TextEditingController();
  final _manualTransactionId = TextEditingController();
  final _paymentProofPicker = ImagePicker();
  Map<String, dynamic> _cart = {};
  List<dynamic> _addresses = [];
  int? _addressId;
  bool _loading = true;
  bool _placing = false;
  bool _locating = false;
  bool _feeLoading = false;
  double? _deliveryLat;
  double? _deliveryLng;
  String? _locationStatus;
  String? _paymentMethod;
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
    _landmark.dispose();
    _note.dispose();
    _manualTransactionId.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cart = await _api.get('/food/cart');
    final addresses = await _api.get('/food/addresses');
    setState(() {
      _cart = Map<String, dynamic>.from(cart as Map);
      _addresses = (addresses as List?) ?? [];
      final paymentOptions = (_cart['payment_options'] as List?) ?? [];
      if (paymentOptions.isNotEmpty &&
          !paymentOptions.any((option) => option['method'] == _paymentMethod)) {
        _paymentMethod = paymentOptions.first['method']?.toString();
      }
      final def = _addresses.where((a) => a['is_default'] == true).toList();
      _addressId = def.isNotEmpty
          ? (def.first['id'] as num).toInt()
          : (_addresses.isNotEmpty
                ? (_addresses.first['id'] as num).toInt()
                : null);
      final selected = _addresses
          .cast<dynamic>()
          .where((a) => a['id'] == _addressId)
          .toList();
      if (selected.isNotEmpty) {
        final address = selected.first;
        _deliveryLat =
            double.tryParse('${address['lat'] ?? ''}') ?? _deliveryLat;
        _deliveryLng =
            double.tryParse('${address['lng'] ?? ''}') ?? _deliveryLng;
      }
      _loading = false;
    });
    await _refreshDeliveryCharge();
  }

  Future<void> _saveAddress() async {
    final res = await _api.post(
      '/food/addresses',
      body: {
        'receiver_name': _name.text.trim(),
        'receiver_phone': _phone.text.trim(),
        'area': _area.text.trim(),
        'address': _address.text.trim(),
        'landmark': _landmark.text.trim(),
        if (_deliveryLat != null) 'lat': _deliveryLat,
        if (_deliveryLng != null) 'lng': _deliveryLng,
        'is_default': true,
      },
    );
    final address = res['address'];
    setState(() => _addressId = (address['id'] as num).toInt());
    await _load();
  }

  Future<bool> _captureLocation() async {
    setState(() {
      _locating = true;
      _locationStatus = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(
          () => _locationStatus =
              '\u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u09b8\u09be\u09b0\u09cd\u09ad\u09bf\u09b8 \u09ac\u09a8\u09cd\u09a7 \u0986\u099b\u09c7\u0964 \u0985\u09a8\u09c1\u0997\u09cd\u09b0\u09b9 \u0995\u09b0\u09c7 \u099a\u09be\u09b2\u09c1 \u0995\u09b0\u09c1\u09a8\u0964',
        );
        await Geolocator.openLocationSettings();
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(
          () => _locationStatus =
              '\u09b2\u09cb\u0995\u09c7\u09b6\u09a8 permission \u09a8\u09be \u09a6\u09bf\u09b2\u09c7 delivery location \u09a8\u09c7\u0993\u09df\u09be \u09af\u09be\u09ac\u09c7 \u09a8\u09be\u0964',
        );
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(
          () => _locationStatus =
              '\u09b2\u09cb\u0995\u09c7\u09b6\u09a8 permission permanently \u09ac\u09a8\u09cd\u09a7 \u0986\u099b\u09c7\u0964 App settings \u09a5\u09c7\u0995\u09c7 \u099a\u09be\u09b2\u09c1 \u0995\u09b0\u09c1\u09a8\u0964',
        );
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
            '\u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u09a8\u09c7\u0993\u09df\u09be \u09b9\u09df\u09c7\u099b\u09c7: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      });
      await _refreshDeliveryCharge();
      return true;
    } catch (_) {
      setState(
        () => _locationStatus =
            '\u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u09a8\u09c7\u0993\u09df\u09be \u09af\u09be\u09df\u09a8\u09bf\u0964 \u0986\u09ac\u09be\u09b0 \u099a\u09c7\u09b7\u09cd\u099f\u09be \u0995\u09b0\u09c1\u09a8\u0964',
      );
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
          title: 'ডেলিভারি লোকেশন',
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
    if (mounted) setState(() => _feeLoading = true);
    try {
      final res = await _api.post(
        '/food/delivery-charge-preview',
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cart = {
          ..._cart,
          'delivery_charge_label':
              'ডেলিভারি চার্জ অর্ডার কনফার্ম করার সময় হিসাব হবে',
        };
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u0995\u09b0\u09a4\u09c7 \u09ac\u09b0\u09cd\u09a4\u09ae\u09be\u09a8 \u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u09b2\u09be\u0997\u09ac\u09c7\u0964',
              ),
            ),
          );
        }
        return;
      }
    }

    if (!mounted) return;
    if (_addressId == null) {
      if (_name.text.trim().isEmpty ||
          _phone.text.trim().isEmpty ||
          _address.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\u09a8\u09be\u09ae, \u09ab\u09cb\u09a8 \u0993 \u09a0\u09bf\u0995\u09be\u09a8\u09be \u09a6\u09bf\u09a8',
            ),
          ),
        );
        return;
      }
      await _saveAddress();
    }
    setState(() => _placing = true);
    try {
      final isManualPayment =
          _paymentMethod == 'manual_bkash' || _paymentMethod == 'manual_nagad';
      final payload = {
        'food_address_id': _addressId,
        'order_type': 'delivery',
        'payment_method': _paymentMethod ?? 'cash_on_delivery',
        'order_note': _note.text.trim().isEmpty ? null : _note.text.trim(),
        'delivery_lat': _deliveryLat,
        'delivery_lng': _deliveryLng,
        'delivery_map_url':
            'https://www.google.com/maps/search/?api=1&query=$_deliveryLat,$_deliveryLng',
        if (isManualPayment && _manualTransactionId.text.trim().isNotEmpty)
          'manual_transaction_id': _manualTransactionId.text.trim(),
      };
      final res = _paymentProofPhoto == null
          ? await _api.post('/food/checkout', body: payload)
          : await _api.postMultipart(
              '/food/checkout',
              fields: payload.map(
                (key, value) => MapEntry(key, value == null ? '' : '$value'),
              ),
              files: {'payment_proof_photo': _paymentProofPhoto!.path},
            );
      final order = res['order'] is Map
          ? Map<String, dynamic>.from(res['order'] as Map)
          : <String, dynamic>{};
      unawaited(
        MetaAppEventsService.instance.logPurchase(
          value:
              num.tryParse('${order['grand_total'] ?? _cart['grand_total']}') ??
              0,
          orderId: '${order['id'] ?? ''}',
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              FoodOrderDetailsScreen(orderId: (order['id'] as num).toInt()),
        ),
        (route) => route.isFirst,
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
    final items = (_cart['items'] as List?) ?? const [];
    final selectedAddress = _selectedAddress();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      bottomNavigationBar: _FoodFlowBottomAction(
        label: _placing ? 'অর্ডার হচ্ছে...' : 'অর্ডার নিশ্চিত করুন',
        amount: _cart['grand_total'],
        onPressed: _placing ? null : _place,
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              children: [
                _FoodFlowHeader(
                  title: 'চেকআউট',
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                _CheckoutAddressCard(
                  selectedAddress: selectedAddress,
                  addresses: _addresses,
                  addressId: _addressId,
                  onAddressChanged: (id) => setState(() => _addressId = id),
                  name: _name,
                  phone: _phone,
                  area: _area,
                  address: _address,
                  landmark: _landmark,
                  locating: _locating,
                  lat: _deliveryLat,
                  lng: _deliveryLng,
                  status: _locationStatus,
                  onCurrentLocation: _captureLocation,
                  onPickMap: _pickLocationOnMap,
                ),
                const SizedBox(height: 14),
                _CheckoutSectionCard(
                  title: 'ডেলিভারি সময়',
                  child: _CheckoutDropdownLikeRow(
                    icon: Icons.schedule_rounded,
                    title:
                        _cart['delivery_time']?.toString() ?? 'যত দ্রুত সম্ভব',
                    subtitle: _cart['delivery_distance_km'] == null
                        ? null
                        : 'দূরত্ব ${_cart['delivery_distance_km']} KM',
                  ),
                ),
                const SizedBox(height: 14),
                _CheckoutSectionCard(
                  title: 'পেমেন্ট মাধ্যম',
                  child: CheckoutPaymentSection(
                    options: (_cart['payment_options'] as List?) ?? const [],
                    selectedMethod: _paymentMethod,
                    total: _cart['grand_total'],
                    onChanged: (method) =>
                        setState(() => _paymentMethod = method),
                  ),
                ),
                if (_paymentMethod == 'manual_bkash' ||
                    _paymentMethod == 'manual_nagad') ...[
                  const SizedBox(height: 12),
                  _ManualPaymentProofCard(
                    transactionId: _manualTransactionId,
                    proof: _paymentProofPhoto,
                    onPick: _pickPaymentProof,
                    onRemove: () => setState(() => _paymentProofPhoto = null),
                  ),
                ],
                const SizedBox(height: 14),
                _CheckoutSectionCard(
                  title: 'অর্ডার নোট',
                  child: _FoodStyledTextField(
                    controller: _note,
                    label: 'রেস্টুরেন্টের জন্য নোট',
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 14),
                _CheckoutOrderSummaryCard(
                  cart: _cart,
                  itemCount: items.length,
                  loading: _feeLoading,
                ),
                const SizedBox(height: 96),
              ],
            ),
    );
  }

  Map<String, dynamic>? _selectedAddress() {
    for (final raw in _addresses) {
      final address = Map<String, dynamic>.from(raw as Map);
      if (address['id'] == _addressId) return address;
    }
    return null;
  }
}

class _FoodFlowHeader extends StatelessWidget {
  const _FoodFlowHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 92,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onBack,
                child: const SizedBox(
                  width: 54,
                  height: 54,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF1F2937),
                    size: 23,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 26,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodFlowBottomAction extends StatelessWidget {
  const _FoodFlowBottomAction({
    required this.label,
    required this.amount,
    required this.onPressed,
  });

  final String label;
  final dynamic amount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00765B),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            '$label (৳${amount ?? 0})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _FoodCartRestaurantCard extends StatelessWidget {
  const _FoodCartRestaurantCard({required this.cart});

  final Map<String, dynamic> cart;

  @override
  Widget build(BuildContext context) {
    final restaurant = Map<String, dynamic>.from(
      (cart['restaurant'] as Map?) ?? {},
    );
    final name =
        '${restaurant['name'] ?? cart['restaurant_name'] ?? 'খাবারের কার্ট'}';
    final subtitle =
        '${restaurant['address'] ?? cart['restaurant_address'] ?? 'অর্ডারের খাবারগুলো'}';

    return _FoodWhiteCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _FoodImage(
              url: restaurant['image_url']?.toString(),
              width: 58,
              height: 58,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodCartItemCard extends StatelessWidget {
  const _FoodCartItemCard({
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
    final details = [
      if ('${item['size'] ?? ''}'.trim().isNotEmpty) '${item['size']}',
      if ('${item['spice_level'] ?? ''}'.trim().isNotEmpty)
        '${item['spice_level']}',
      if ('${item['note'] ?? ''}'.trim().isNotEmpty) '${item['note']}',
    ].join(', ');

    return _FoodWhiteCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['name']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 17,
                    height: 1.18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    details,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      height: 1.25,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  '৳${item['line_total'] ?? item['total'] ?? item['unit_price']}',
                  style: const TextStyle(
                    color: Color(0xFF00765B),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              _CartQtyControl(
                quantity: (item['quantity'] as num?)?.toInt() ?? 1,
                onMinus: onMinus,
                onPlus: onPlus,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onRemove,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('মুছুন'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartQtyControl extends StatelessWidget {
  const _CartQtyControl({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F4),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TinyIconAction(icon: Icons.remove_rounded, onTap: onMinus),
          SizedBox(
            width: 30,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _TinyIconAction(icon: Icons.add_rounded, onTap: onPlus),
        ],
      ),
    );
  }
}

class _TinyIconAction extends StatelessWidget {
  const _TinyIconAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 30,
        height: 30,
        child: Icon(icon, size: 20, color: const Color(0xFF1F2937)),
      ),
    );
  }
}

class _AddMoreFoodButton extends StatelessWidget {
  const _AddMoreFoodButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF5F0),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: const SizedBox(
          height: 58,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: Color(0xFF00765B), size: 24),
              SizedBox(width: 10),
              Text(
                'আরো খাবার যোগ করুন',
                style: TextStyle(
                  color: Color(0xFF00765B),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodBillSummaryCard extends StatelessWidget {
  const _FoodBillSummaryCard({required this.cart, this.loading = false});

  final Map<String, dynamic> cart;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return _FoodWhiteCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'বিল বিবরণী',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _BillRow(label: 'খাবারের মূল্য', value: cart['items_total']),
          _BillRow(
            label: 'ডেলিভারি চার্জ',
            value: loading ? '...' : cart['delivery_fee'],
            pendingText: cart['delivery_fee'] == null ? 'লোকেশন লাগবে' : null,
          ),
          if ((num.tryParse('${cart['discount_amount'] ?? 0}') ?? 0) > 0)
            _BillRow(
              label: 'ছাড়',
              value: '-${cart['discount_amount']}',
              valueColor: const Color(0xFFEF4444),
            ),
          if (cart['delivery_distance_km'] != null ||
              cart['delivery_charge_label'] != null) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (cart['delivery_distance_km'] != null)
                  'দূরত্ব ${cart['delivery_distance_km']} KM',
                if (cart['delivery_charge_label'] != null)
                  '${cart['delivery_charge_label']}',
              ].join(' • '),
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
          _BillRow(
            label: 'সর্বমোট বিল',
            value: cart['grand_total'],
            strong: true,
            valueColor: const Color(0xFF00765B),
          ),
        ],
      ),
    );
  }
}

class _CheckoutAddressCard extends StatelessWidget {
  const _CheckoutAddressCard({
    required this.selectedAddress,
    required this.addresses,
    required this.addressId,
    required this.onAddressChanged,
    required this.name,
    required this.phone,
    required this.area,
    required this.address,
    required this.landmark,
    required this.locating,
    required this.lat,
    required this.lng,
    required this.status,
    required this.onCurrentLocation,
    required this.onPickMap,
  });

  final Map<String, dynamic>? selectedAddress;
  final List<dynamic> addresses;
  final int? addressId;
  final ValueChanged<int> onAddressChanged;
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController area;
  final TextEditingController address;
  final TextEditingController landmark;
  final bool locating;
  final double? lat;
  final double? lng;
  final String? status;
  final Future<bool> Function() onCurrentLocation;
  final VoidCallback onPickMap;

  @override
  Widget build(BuildContext context) {
    final hasLocation = lat != null && lng != null;
    final addressText = selectedAddress == null
        ? 'নতুন ঠিকানা দিন'
        : '${selectedAddress!['address'] ?? ''}';

    return _CheckoutSectionCard(
      title: 'ডেলিভারি ঠিকানা',
      actionLabel: 'পরিবর্তন করুন',
      onAction: onPickMap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF5F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF00765B),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selectedAddress?['receiver_name'] ?? 'রিসিভার'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      addressText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CheckoutMapPreview(
            hasLocation: hasLocation,
            lat: lat,
            lng: lng,
            locating: locating,
            status: status,
            onCurrentLocation: onCurrentLocation,
            onPickMap: onPickMap,
          ),
          if (addresses.length > 1) ...[
            const SizedBox(height: 14),
            ...addresses.map((raw) {
              final item = Map<String, dynamic>.from(raw as Map);
              final id = (item['id'] as num).toInt();
              return _CheckoutAddressOption(
                address: item,
                selected: addressId == id,
                onTap: () => onAddressChanged(id),
              );
            }),
          ],
          if (selectedAddress == null) ...[
            const SizedBox(height: 16),
            _FoodStyledTextField(controller: name, label: 'রিসিভারের নাম'),
            const SizedBox(height: 10),
            _FoodStyledTextField(
              controller: phone,
              label: 'মোবাইল নম্বর',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            _FoodStyledTextField(controller: area, label: 'এলাকা'),
            const SizedBox(height: 10),
            _FoodStyledTextField(
              controller: address,
              label: 'সম্পূর্ণ ঠিকানা',
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            _FoodStyledTextField(controller: landmark, label: 'ল্যান্ডমার্ক'),
          ],
        ],
      ),
    );
  }
}

class _CheckoutMapPreview extends StatelessWidget {
  const _CheckoutMapPreview({
    required this.hasLocation,
    required this.locating,
    required this.onCurrentLocation,
    required this.onPickMap,
    this.lat,
    this.lng,
    this.status,
  });

  final bool hasLocation;
  final bool locating;
  final double? lat;
  final double? lng;
  final String? status;
  final Future<bool> Function() onCurrentLocation;
  final VoidCallback onPickMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8E2)),
      ),
      child: Column(
        children: [
          Container(
            height: 92,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _CheckoutMapPatternPainter()),
                ),
                Icon(
                  hasLocation
                      ? Icons.location_on_rounded
                      : Icons.add_location_alt_outlined,
                  color: hasLocation
                      ? const Color(0xFF00765B)
                      : const Color(0xFF9CA3AF),
                  size: 42,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (status != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                status!,
                style: TextStyle(
                  color: hasLocation
                      ? const Color(0xFF00765B)
                      : const Color(0xFFEF4444),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ),
          if (status != null) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: locating ? null : onCurrentLocation,
                  icon: locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: LogoLoader(size: 16),
                        )
                      : const Icon(Icons.gps_fixed_rounded, size: 18),
                  label: Text(locating ? 'নেওয়া হচ্ছে' : 'বর্তমান লোকেশন'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: locating ? null : onPickMap,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('ম্যাপ থেকে'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutAddressOption extends StatelessWidget {
  const _CheckoutAddressOption({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final Map<String, dynamic> address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected
                  ? const Color(0xFF00765B)
                  : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${address['receiver_name']} - ${address['address']}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutDropdownLikeRow extends StatelessWidget {
  const _CheckoutDropdownLikeRow({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B7280), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }
}

class _CheckoutOrderSummaryCard extends StatelessWidget {
  const _CheckoutOrderSummaryCard({
    required this.cart,
    required this.itemCount,
    required this.loading,
  });

  final Map<String, dynamic> cart;
  final int itemCount;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return _CheckoutSectionCard(
      title: 'অর্ডারের সংক্ষিপ্ত বিবরণ',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$itemCount টি খাবার',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '৳${cart['grand_total'] ?? 0}',
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
          _BillRow(
            label: 'ডেলিভারি চার্জ',
            value: loading ? '...' : cart['delivery_fee'],
            pendingText: cart['delivery_fee'] == null ? 'লোকেশন লাগবে' : null,
          ),
          if ((num.tryParse('${cart['discount_amount'] ?? 0}') ?? 0) > 0)
            _BillRow(
              label: 'ছাড়',
              value: '-${cart['discount_amount']}',
              valueColor: const Color(0xFFEF4444),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
          _BillRow(
            label: 'সর্বমোট',
            value: cart['grand_total'],
            strong: true,
            valueColor: const Color(0xFF00765B),
          ),
        ],
      ),
    );
  }
}

class _CheckoutSectionCard extends StatelessWidget {
  const _CheckoutSectionCard({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _FoodWhiteCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF00765B),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(actionLabel!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FoodStyledTextField extends StatelessWidget {
  const _FoodStyledTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00765B), width: 1.3),
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.label,
    required this.value,
    this.strong = false,
    this.pendingText,
    this.valueColor,
  });

  final String label;
  final dynamic value;
  final bool strong;
  final String? pendingText;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong
                    ? const Color(0xFF1F2937)
                    : const Color(0xFF6B7280),
                fontSize: strong ? 17 : 15,
                fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            pendingText ?? (value == '...' ? '...' : '৳${value ?? 0}'),
            style: TextStyle(
              color:
                  valueColor ??
                  (strong ? const Color(0xFF1F2937) : const Color(0xFF1F2937)),
              fontSize: strong ? 17 : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodWhiteCard extends StatelessWidget {
  const _FoodWhiteCard({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8E2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF153B31).withValues(alpha: 0.055),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CheckoutMapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFDDE6E1)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final accentPaint = Paint()
      ..color = const Color(0xFFBFDCD1)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.68)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.42,
        size.width * 0.58,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.64,
        size.width,
        size.height * 0.35,
      );
    canvas.drawPath(path, accentPaint);

    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.18 + i * 0.2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 20), roadPaint);
    }
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.12 + i * 0.24);
      canvas.drawLine(Offset(x, 0), Offset(x + 18, size.height), roadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
