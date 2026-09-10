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
    final scheme = Theme.of(context).colorScheme;
    final items = (_cart['items'] as List?) ?? [];
    return Scaffold(
      appBar: const ModernAppBar(
        title: '\u0986\u09ae\u09be\u09b0 \u0995\u09be\u09b0\u09cd\u099f',
        subtitle:
            '\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u099a\u09c7\u0995 \u0995\u09b0\u09c1\u09a8',
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
                            '\u09ae\u09cb\u099f \u09ac\u09bf\u09b2',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\u09f3${_cart['grand_total'] ?? 0}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 136,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FoodCheckoutScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text(
                          '\u099a\u09c7\u0995\u0986\u0989\u099f',
                        ),
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
                    const _EmptyFoodState(
                      text:
                          '\u0995\u09be\u09b0\u09cd\u099f \u0996\u09be\u09b2\u09bf \u0986\u099b\u09c7',
                    ),
                  if (items.isNotEmpty) ...[
                    _FoodSectionHeader(
                      icon: Icons.shopping_bag_outlined,
                      title:
                          '\u0995\u09be\u09b0\u09cd\u099f\u09c7\u09b0 \u0996\u09be\u09ac\u09be\u09b0',
                      subtitle:
                          '${items.length} \u099f\u09bf item \u09af\u09cb\u0997 \u09b9\u09df\u09c7\u099b\u09c7',
                    ),
                    const SizedBox(height: 12),
                  ],
                  ...items.map((raw) {
                    final item = Map<String, dynamic>.from(raw as Map);
                    final id = (item['id'] as num).toInt();
                    final quantity = (item['quantity'] as num).toInt();
                    return _CartItemTile(
                      item: item,
                      onMinus: () => _qty(id, quantity - 1),
                      onPlus: () => _qty(id, quantity + 1),
                      onRemove: () => _remove(id),
                    );
                  }),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _PriceBox(cart: _cart),
                    const SizedBox(height: 90),
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
    return Scaffold(
      appBar: const ModernAppBar(
        title: "\u099a\u09c7\u0995\u0986\u0989\u099f",
        subtitle:
            "\u09a0\u09bf\u0995\u09be\u09a8\u09be \u0993 \u09aa\u09c7\u09ae\u09c7\u09a8\u09cd\u099f",
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _placing ? null : _place,
            child: Text(
              _placing
                  ? "\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u09b9\u099a\u09cd\u099b\u09c7..."
                  : "\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u0995\u09a8\u09ab\u09be\u09b0\u09cd\u09ae \u0995\u09b0\u09c1\u09a8",
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PriceBox(cart: _cart, loading: _feeLoading),
                const SizedBox(height: 14),
                _DeliveryLocationCard(
                  locating: _locating,
                  lat: _deliveryLat,
                  lng: _deliveryLng,
                  status: _locationStatus,
                  onTap: _captureLocation,
                  onPickMap: _pickLocationOnMap,
                ),
                const SizedBox(height: 14),
                Text(
                  "\u09a1\u09c7\u09b2\u09bf\u09ad\u09be\u09b0\u09bf \u09a0\u09bf\u0995\u09be\u09a8\u09be",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ..._addresses.map((a) {
                  final id = (a['id'] as num).toInt();
                  final selected = _addressId == id;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _addressId = id),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${a['receiver_name']} - ${a['receiver_phone']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${a['address']}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Text(
                  "\u09a8\u09a4\u09c1\u09a8 \u09a0\u09bf\u0995\u09be\u09a8\u09be",
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText:
                        "\u09b0\u09bf\u09b8\u09bf\u09ad\u09be\u09b0\u09c7\u09b0 \u09a8\u09be\u09ae",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText:
                        "\u09ae\u09cb\u09ac\u09be\u0987\u09b2 \u09a8\u09ae\u09cd\u09ac\u09b0",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _area,
                  decoration: const InputDecoration(
                    labelText: "\u098f\u09b2\u09be\u0995\u09be",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _address,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText:
                        "\u09b8\u09ae\u09cd\u09aa\u09c2\u09b0\u09cd\u09a3 \u09a0\u09bf\u0995\u09be\u09a8\u09be",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _landmark,
                  decoration: const InputDecoration(
                    labelText:
                        "\u09b2\u09cd\u09af\u09be\u09a8\u09cd\u09a1\u09ae\u09be\u09b0\u09cd\u0995",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText:
                        "\u0985\u09b0\u09cd\u09a1\u09be\u09b0 \u09a8\u09cb\u099f",
                  ),
                ),
                const SizedBox(height: 12),
                CheckoutPaymentSection(
                  options: (_cart['payment_options'] as List?) ?? const [],
                  selectedMethod: _paymentMethod,
                  total: _cart['grand_total'],
                  onChanged: (method) =>
                      setState(() => _paymentMethod = method),
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
              ],
            ),
    );
  }
}
