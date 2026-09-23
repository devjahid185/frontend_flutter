part of '../food_home_screen.dart';

/// ---------------------------------------------------------------------------
/// Shared flow header
/// ---------------------------------------------------------------------------
/// One flat, pinned sliver app bar used by both the cart and checkout
/// screens, in the same visual language as the rest of the redesigned app
/// (see food_home_screen.dart / food_item_details_screen.dart) — replaces
/// the old plain SafeArea + big-circle-button header.
Widget _flowSliverAppBar(
  BuildContext context, {
  required String title,
  required VoidCallback onBack,
}) {
  return SliverAppBar(
    pinned: true,
    floating: false,
    elevation: 0,
    scrolledUnderElevation: 1,
    shadowColor: AppColors.ink.withValues(alpha: 0.08),
    backgroundColor: AppColors.surfaceAlt,
    surfaceTintColor: AppColors.surfaceAlt,
    centerTitle: false,
    titleSpacing: 4,
    leadingWidth: 62,
    leading: Padding(
      padding: const EdgeInsets.only(left: 12),
      child: PressableScale(
        onTap: onBack,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadow.card,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: AppColors.ink,
          ),
        ),
      ),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 19,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

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
      backgroundColor: AppColors.surfaceAlt,
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
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  _flowSliverAppBar(
                    context,
                    title: 'আপনার কার্ট',
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  if (items.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyFoodState(text: 'কার্ট খালি আছে'),
                    ),
                  if (items.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: FadeSlideIn(
                          child: _FoodCartRestaurantCard(cart: _cart),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final raw = items[index];
                          final item = Map<String, dynamic>.from(raw as Map);
                          final id = (item['id'] as num).toInt();
                          final quantity = (item['quantity'] as num).toInt();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FadeSlideIn(
                              index: index,
                              child: _FoodCartItemCard(
                                item: item,
                                onMinus: () => _qty(id, quantity - 1),
                                onPlus: () => _qty(id, quantity + 1),
                                onRemove: () => _remove(id),
                              ),
                            ),
                          );
                        }, childCount: items.length),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _AddMoreFoodButton(
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _FoodBillSummaryCard(
                          cart: _cart,
                          loading: false,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
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
  final _coupon = TextEditingController();
  final _paymentProofPicker = ImagePicker();
  Map<String, dynamic> _cart = {};
  List<dynamic> _addresses = [];
  int? _addressId;
  bool _loading = true;
  bool _placing = false;
  bool _locating = false;
  bool _feeLoading = false;
  bool _couponLoading = false;
  bool _couponApplied = false;
  bool _deliveryLocationConfirmed = false;
  double? _deliveryLat;
  double? _deliveryLng;
  String? _locationStatus;
  String? _couponMessage;
  String? _paymentMethod;
  XFile? _paymentProofPhoto;

  @override
  void initState() {
    super.initState();
    _coupon.addListener(_onCouponTextChanged);
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
    _coupon.removeListener(_onCouponTextChanged);
    _coupon.dispose();
    super.dispose();
  }

  void _onCouponTextChanged() {
    if (!mounted) return;
    setState(() {
      if (_couponApplied) {
        _couponApplied = false;
        _couponMessage = null;
      }
    });
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
        final address = Map<String, dynamic>.from(selected.first as Map);
        _applyAddressToForm(address);
      }
      _loading = false;
    });
    if (_deliveryLat != null && _deliveryLng != null) {
      await _refreshDeliveryCharge();
    }
  }

  Future<void> _saveAddress() async {
    final res = await _api.post(
      '/food/addresses',
      body: {
        if (_addressId != null) 'id': _addressId,
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
    if (address is Map) {
      final saved = Map<String, dynamic>.from(address);
      setState(() {
        _addressId = (saved['id'] as num).toInt();
        final index = _addresses.indexWhere(
          (raw) => raw is Map && raw['id'] == saved['id'],
        );
        if (index >= 0) {
          _addresses[index] = saved;
        } else {
          _addresses = [saved, ..._addresses];
        }
        _applyAddressToForm(saved);
      });
    }
  }

  Future<void> _selectAddress(int id) async {
    final selected = _addresses
        .where((raw) => raw is Map && (raw['id'] as num?)?.toInt() == id)
        .cast<Map>()
        .toList();
    if (selected.isEmpty) return;

    final address = Map<String, dynamic>.from(selected.first);
    setState(() {
      _addressId = id;
      _applyAddressToForm(address);
      _couponApplied = false;
      _couponMessage = null;
      if (_deliveryLat == null || _deliveryLng == null) {
        _cart = _cartWithoutDeliveryLocation();
      }
    });
    if (_deliveryLat != null && _deliveryLng != null) {
      await _refreshDeliveryCharge();
    }
  }

  void _startNewReceiver() {
    setState(() {
      _addressId = null;
      _name.clear();
      _phone.clear();
      _area.clear();
      _address.clear();
      _landmark.clear();
      _deliveryLat = null;
      _deliveryLng = null;
      _deliveryLocationConfirmed = false;
      _locationStatus = null;
      _couponApplied = false;
      _couponMessage = null;
      _cart = _cartWithoutDeliveryLocation();
    });
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
        _deliveryLocationConfirmed = true;
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
      _deliveryLocationConfirmed = true;
      _locationStatus =
          'ম্যাপ থেকে লোকেশন নেওয়া হয়েছে: ${picked.lat.toStringAsFixed(5)}, ${picked.lng.toStringAsFixed(5)}';
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
          'discount_amount': 0,
          'admin_discount_amount': 0,
          'restaurant_discount_amount': 0,
          'delivery_discount_amount': 0,
          'grand_total': res['grand_total'],
        };
      });
      if (_coupon.text.trim().isNotEmpty) {
        await _previewCoupon(showSnack: false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cart = {
          ..._cart,
          'delivery_charge_label':
              'ডেলিভারি চার্জ অর্ডার কনফার্ম করার সময় হিসাব হবে',
        };
      });
    } finally {
      if (mounted) setState(() => _feeLoading = false);
    }
  }

  Future<void> _previewCoupon({bool showSnack = true}) async {
    final code = _coupon.text.trim();
    if (code.isEmpty) {
      setState(() {
        _couponApplied = false;
        _couponMessage = null;
        _cart = {
          ..._cart,
          'discount_amount': 0,
          'admin_discount_amount': 0,
          'restaurant_discount_amount': 0,
          'delivery_discount_amount': 0,
          'coupon_code': null,
          'grand_total':
              (num.tryParse('${_cart['items_total'] ?? 0}') ?? 0) +
              (num.tryParse('${_cart['delivery_fee'] ?? 0}') ?? 0),
        };
      });
      return;
    }
    if (_deliveryLat == null || _deliveryLng == null) {
      setState(
        () => _couponMessage = 'Coupon হিসাব করতে আগে delivery location দিন।',
      );
      return;
    }

    setState(() => _couponLoading = true);
    try {
      final res = await _api.post(
        '/food/coupon-preview',
        body: {
          'coupon_code': code,
          'delivery_lat': _deliveryLat,
          'delivery_lng': _deliveryLng,
        },
      );
      if (!mounted) return;
      setState(() {
        _couponApplied = true;
        _couponMessage = '${res['message'] ?? 'Coupon applied'}';
        _cart = {
          ..._cart,
          'delivery_fee': res['delivery_fee'],
          'delivery_distance_km': res['delivery_distance_km'],
          'delivery_charge_mode': res['delivery_charge_mode'],
          'delivery_charge_label': res['delivery_charge_label'],
          'discount_amount': res['discount_amount'],
          'admin_discount_amount': res['admin_discount_amount'],
          'restaurant_discount_amount': res['restaurant_discount_amount'],
          'delivery_discount_amount': res['delivery_discount_amount'],
          'discount_breakdown': res['discount_breakdown'],
          'coupon_code': code.toUpperCase(),
          'grand_total': res['grand_total'],
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _couponApplied = false;
        _couponMessage = '$e';
        _cart = {
          ..._cart,
          'discount_amount': 0,
          'admin_discount_amount': 0,
          'restaurant_discount_amount': 0,
          'delivery_discount_amount': 0,
          'coupon_code': null,
          'grand_total':
              (num.tryParse('${_cart['items_total'] ?? 0}') ?? 0) +
              (num.tryParse('${_cart['delivery_fee'] ?? 0}') ?? 0),
        };
      });
      if (showSnack) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _couponLoading = false);
    }
  }

  void _removeCoupon() {
    _coupon.clear();
    _previewCoupon(showSnack: false);
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
    if (!_deliveryLocationConfirmed ||
        _deliveryLat == null ||
        _deliveryLng == null) {
      setState(
        () => _locationStatus =
            'অর্ডার করতে বর্তমান লোকেশন অথবা ম্যাপ থেকে লোকেশন নিতে হবে।',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'অর্ডার করতে বর্তমান লোকেশন অথবা ম্যাপ থেকে লোকেশন দিন',
          ),
        ),
      );
      return;
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
        if (_coupon.text.trim().isNotEmpty) 'coupon_code': _coupon.text.trim(),
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
      backgroundColor: AppColors.surfaceAlt,
      bottomNavigationBar: _FoodFlowBottomAction(
        label: _placing ? 'অর্ডার হচ্ছে...' : 'অর্ডার নিশ্চিত করুন',
        amount: _cart['grand_total'],
        onPressed: _placing ? null : _place,
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : CustomScrollView(
              slivers: [
                _flowSliverAppBar(
                  context,
                  title: 'চেকআউট',
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      FadeSlideIn(
                        index: 0,
                        child: _CheckoutAddressCard(
                          selectedAddress: selectedAddress,
                          addresses: _addresses,
                          addressId: _addressId,
                          onAddressChanged: _selectAddress,
                          onAddNew: _startNewReceiver,
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
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        index: 1,
                        child: _CheckoutSectionCard(
                          title: 'ডেলিভারি সময়',
                          child: _CheckoutDropdownLikeRow(
                            icon: Icons.schedule_rounded,
                            title:
                                _cart['delivery_time']?.toString() ??
                                'যত দ্রুত সম্ভব',
                            subtitle: _cart['delivery_distance_km'] == null
                                ? null
                                : 'দূরত্ব ${_cart['delivery_distance_km']} KM',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        index: 2,
                        child: _CheckoutCouponCard(
                          controller: _coupon,
                          loading: _couponLoading,
                          applied: _couponApplied,
                          message: _couponMessage,
                          discountAmount: _cart['discount_amount'],
                          adminDiscountAmount: _cart['admin_discount_amount'],
                          restaurantDiscountAmount:
                              _cart['restaurant_discount_amount'],
                          deliveryDiscountAmount:
                              _cart['delivery_discount_amount'],
                          breakdown: _cart['discount_breakdown'],
                          onApply: () => _previewCoupon(),
                          onRemove: _removeCoupon,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        index: 3,
                        child: _CheckoutSectionCard(
                          title: 'পেমেন্ট মাধ্যম',
                          child: CheckoutPaymentSection(
                            options:
                                (_cart['payment_options'] as List?) ?? const [],
                            selectedMethod: _paymentMethod,
                            total: _cart['grand_total'],
                            onChanged: (method) =>
                                setState(() => _paymentMethod = method),
                          ),
                        ),
                      ),
                      if (_paymentMethod == 'manual_bkash' ||
                          _paymentMethod == 'manual_nagad') ...[
                        const SizedBox(height: 12),
                        _ManualPaymentProofCard(
                          transactionId: _manualTransactionId,
                          proof: _paymentProofPhoto,
                          onPick: _pickPaymentProof,
                          onRemove: () =>
                              setState(() => _paymentProofPhoto = null),
                        ),
                      ],
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        index: 4,
                        child: _CheckoutSectionCard(
                          title: 'অর্ডার নোট',
                          child: _FoodStyledTextField(
                            controller: _note,
                            label: 'রেস্টুরেন্টের জন্য নোট',
                            maxLines: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        index: 5,
                        child: _CheckoutOrderSummaryCard(
                          cart: _cart,
                          itemCount: items.length,
                          loading: _feeLoading,
                        ),
                      ),
                      const SizedBox(height: 110),
                    ]),
                  ),
                ),
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

  void _applyAddressToForm(Map<String, dynamic> address) {
    _name.text = '${address['receiver_name'] ?? ''}';
    _phone.text = '${address['receiver_phone'] ?? ''}';
    _area.text = '${address['area'] ?? ''}';
    _address.text = '${address['address'] ?? ''}';
    _landmark.text = '${address['landmark'] ?? ''}';
    _deliveryLat = readDouble(address['lat']);
    _deliveryLng = readDouble(address['lng']);
    _deliveryLocationConfirmed = _deliveryLat != null && _deliveryLng != null;
    _locationStatus = _deliveryLocationConfirmed
        ? 'এই রিসিভারের সেভ করা লোকেশন ব্যবহার হচ্ছে। চাইলে ম্যাপ থেকে পরিবর্তন করতে পারেন।'
        : 'অর্ডারের জন্য বর্তমান অথবা ম্যাপ লোকেশন দিন।';
  }

  Map<String, dynamic> _cartWithoutDeliveryLocation() {
    return {
      ..._cart,
      'delivery_fee': null,
      'delivery_distance_km': null,
      'delivery_charge_mode': null,
      'delivery_charge_label': 'লোকেশন দিলে ডেলিভারি চার্জ দেখা যাবে',
      'discount_amount': 0,
      'admin_discount_amount': 0,
      'restaurant_discount_amount': 0,
      'delivery_discount_amount': 0,
      'coupon_code': null,
    };
  }
}

/// Floating, elevated bottom action shared by cart & checkout — rises into
/// place and the price re-renders with a quick cross-fade whenever it
/// changes (delivery fee arriving, quantity changing) instead of snapping.
class _FoodFlowBottomAction extends StatefulWidget {
  const _FoodFlowBottomAction({
    required this.label,
    required this.amount,
    required this.onPressed,
  });

  final String label;
  final dynamic amount;
  final VoidCallback? onPressed;

  @override
  State<_FoodFlowBottomAction> createState() => _FoodFlowBottomActionState();
}

class _FoodFlowBottomActionState extends State<_FoodFlowBottomAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _entrance, curve: AppMotion.enter);
    return SafeArea(
      top: false,
      child: AnimatedBuilder(
        animation: curve,
        builder: (context, child) => Opacity(
          opacity: curve.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - curve.value) * 26),
            child: child,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadow.raised,
          ),
          padding: const EdgeInsets.all(8),
          child: PressableScale(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.onPressed == null
                    ? AppColors.inkMuted4
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedSwitcher(
                duration: AppMotion.base,
                child: Text(
                  '${widget.label} (৳${widget.amount ?? 0})',
                  key: ValueKey('${widget.label}-${widget.amount}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
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
              width: 54,
              height: 54,
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
                    color: AppColors.ink,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 13,
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

/// A cart line item — now swipeable to delete (with a matching trash icon
/// kept for discoverability), a small photo thumbnail, and an animated
/// quantity stepper.
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

    return Dismissible(
      key: ValueKey('cart-item-${item['id']}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: _FoodWhiteCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _FoodImage(
                url: item['image_url']?.toString(),
                width: 60,
                height: 60,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['name']}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15.5,
                      height: 1.18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      details,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 12.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '৳${item['line_total'] ?? item['total'] ?? item['unit_price']}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PressableScale(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _CartQtyControl(
                  quantity: (item['quantity'] as num?)?.toInt() ?? 1,
                  onMinus: onMinus,
                  onPlus: onPlus,
                ),
              ],
            ),
          ],
        ),
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
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TinyIconAction(icon: Icons.remove_rounded, onTap: onMinus),
          SizedBox(
            width: 26,
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
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
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 26,
        height: 26,
        child: Icon(icon, size: 17, color: AppColors.ink),
      ),
    );
  }
}

class _AddMoreFoodButton extends StatelessWidget {
  const _AddMoreFoodButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text(
              'আরো খাবার যোগ করুন',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
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
    final itemsTotal = _readMoney(cart['items_total']);
    final deliveryFee = _readNullableMoney(cart['delivery_fee']);
    final discount = num.tryParse('${cart['discount_amount'] ?? 0}') ?? 0;
    final adminDiscount =
        num.tryParse('${cart['admin_discount_amount'] ?? 0}') ?? 0;
    final restaurantDiscount =
        num.tryParse('${cart['restaurant_discount_amount'] ?? 0}') ?? 0;
    final deliveryDiscount =
        num.tryParse('${cart['delivery_discount_amount'] ?? 0}') ?? 0;
    final payableTotal = deliveryFee == null
        ? _readMoney(cart['grand_total'])
        : _payableTotal(
            itemsTotal: itemsTotal,
            deliveryFee: deliveryFee,
            discount: discount,
          );
    return _FoodWhiteCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'বিল বিবরণী',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _BillRow(label: 'খাবারের মূল্য', value: itemsTotal),
          _BillRow(
            label: 'ডেলিভারি চার্জ',
            value: loading ? '...' : deliveryFee,
            pendingText: cart['delivery_fee'] == null ? 'লোকেশন লাগবে' : null,
          ),
          if (deliveryFee != null)
            _BillRow(label: 'উপমোট', value: itemsTotal + deliveryFee),
          if (discount > 0)
            _BillRow(
              label: 'মোট ছাড়',
              value: -discount,
              valueColor: AppColors.danger,
            ),
          if (adminDiscount > 0)
            _BillRow(
              label: 'অ্যাডমিন কুপন',
              value: -adminDiscount,
              valueColor: AppColors.danger,
            ),
          if (restaurantDiscount > 0)
            _BillRow(
              label: 'রেস্টুরেন্ট কুপন',
              value: -restaurantDiscount,
              valueColor: AppColors.danger,
            ),
          if (deliveryDiscount > 0)
            _BillRow(
              label: 'ডেলিভারি ছাড়',
              value: -deliveryDiscount,
              valueColor: AppColors.danger,
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
                color: AppColors.inkMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _BillRow(
            label: 'পরিশোধযোগ্য মোট',
            value: payableTotal,
            strong: true,
            valueColor: AppColors.primary,
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
    required this.onAddNew,
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
  final VoidCallback onAddNew;
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
    final phoneText = '${selectedAddress?['receiver_phone'] ?? ''}'.trim();

    return _CheckoutSectionCard(
      title: 'ডেলিভারি ঠিকানা',
      actionLabel: 'ম্যাপ থেকে',
      onAction: onPickMap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 26,
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
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (phoneText.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        phoneText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      addressText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 13.5,
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
          const SizedBox(height: 14),
          if (selectedAddress != null) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddNew,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('নতুন রিসিভার'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: addresses.length > 1 ? null : onAddNew,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: Text(
                      addresses.length > 1 ? 'নিচে সিলেক্ট করুন' : 'আরেকজন যোগ',
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text(
              'নতুন রিসিভারের তথ্য',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
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
          if (addresses.length > 1) ...[
            const SizedBox(height: 12),
            const Text(
              'অন্য রিসিভার নির্বাচন করুন',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
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
        ],
      ),
    );
  }
}

/// A schematic "map" preview — same idea as before (a decorative road
/// pattern, no real map tiles), redesigned with the shared tokens and a
/// small bounce animation whenever a location is captured or picked.
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
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _CheckoutMapPatternPainter()),
                ),
                TweenAnimationBuilder<double>(
                  key: ValueKey('map-pin-$hasLocation-$lat-$lng'),
                  tween: Tween(begin: hasLocation ? 0.4 : 1, end: 1),
                  duration: AppMotion.slow,
                  curve: AppMotion.pop,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Icon(
                    hasLocation
                        ? Icons.location_on_rounded
                        : Icons.add_location_alt_outlined,
                    color: hasLocation
                        ? AppColors.primary
                        : AppColors.inkMuted4,
                    size: 40,
                  ),
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
                  color: hasLocation ? AppColors.primary : AppColors.danger,
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
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: LogoLoader(size: 16),
                        )
                      : const Icon(Icons.gps_fixed_rounded, size: 18),
                  label: Text(locating ? 'নেওয়া হচ্ছে' : 'বর্তমান লোকেশন'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: locating ? null : onPickMap,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.inkMuted4,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${address['receiver_name']} - ${address['address']}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink3,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
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
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.inkMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.inkMuted,
          ),
        ],
      ),
    );
  }
}

class _CheckoutCouponCard extends StatelessWidget {
  const _CheckoutCouponCard({
    required this.controller,
    required this.loading,
    required this.applied,
    required this.message,
    required this.discountAmount,
    required this.adminDiscountAmount,
    required this.restaurantDiscountAmount,
    required this.deliveryDiscountAmount,
    required this.breakdown,
    required this.onApply,
    required this.onRemove,
  });

  final TextEditingController controller;
  final bool loading;
  final bool applied;
  final String? message;
  final dynamic discountAmount;
  final dynamic adminDiscountAmount;
  final dynamic restaurantDiscountAmount;
  final dynamic deliveryDiscountAmount;
  final dynamic breakdown;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final discount = num.tryParse('${discountAmount ?? 0}') ?? 0;
    final adminDiscount = num.tryParse('${adminDiscountAmount ?? 0}') ?? 0;
    final restaurantDiscount =
        num.tryParse('${restaurantDiscountAmount ?? 0}') ?? 0;
    final deliveryDiscount =
        num.tryParse('${deliveryDiscountAmount ?? 0}') ?? 0;
    final couponBreakdown = breakdown is Map
        ? Map<String, dynamic>.from(breakdown as Map)
        : <String, dynamic>{};
    final couponTitle =
        couponBreakdown['title']?.toString() ??
        couponBreakdown['code']?.toString() ??
        controller.text.trim().toUpperCase();
    final hasCode = controller.text.trim().isNotEmpty;
    final hasMessage = message != null && message!.trim().isNotEmpty;
    final stateColor = applied
        ? AppColors.success
        : (hasMessage ? AppColors.danger : AppColors.primary);
    final stateBg = stateColor.withValues(alpha: 0.09);

    return _CheckoutSectionCard(
      title: 'কুপন ও অফার',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_offer_rounded, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'রেস্টুরেন্ট বা অ্যাডমিন দেওয়া কুপন কোড থাকলে এখানে ব্যবহার করুন।',
                    style: TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (applied && hasCode) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$couponTitle ব্যবহার হচ্ছে',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close_rounded, size: 17),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: controller,
            enabled: !loading && !applied,
            onSubmitted: (_) {
              if (!loading && !applied && hasCode) onApply();
            },
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
            decoration: InputDecoration(
              labelText: 'কুপন কোড',
              hintText: 'যেমন: FOOD50',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(
                applied
                    ? Icons.verified_rounded
                    : Icons.confirmation_number_outlined,
                color: applied ? AppColors.success : AppColors.primary,
              ),
              suffixIcon: hasCode && !applied
                  ? IconButton(
                      onPressed: loading ? null : onRemove,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Clear',
                    )
                  : null,
              labelStyle: const TextStyle(
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w700,
              ),
              hintStyle: const TextStyle(
                color: AppColors.inkMuted6,
                fontWeight: FontWeight.w700,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.4,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: applied ? AppColors.success : AppColors.border,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: loading || applied || !hasCode ? null : onApply,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.inkMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(applied ? Icons.check_rounded : Icons.sell_outlined),
              label: Text(
                applied
                    ? 'কুপন applied'
                    : (hasCode ? 'কুপন Apply করুন' : 'কুপন কোড লিখুন'),
              ),
            ),
          ),
          if (!hasCode && !applied) ...[
            const SizedBox(height: 8),
            const Text(
              'কোড লিখলে Apply button active হবে। ডেলিভারি লোকেশন দিলে discount হিসাব আরও নির্ভুল হবে।',
              style: TextStyle(
                color: AppColors.inkMuted,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (hasMessage) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: stateBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: stateColor.withValues(alpha: 0.22)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    applied
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    size: 19,
                    color: stateColor,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applied ? 'কুপন প্রয়োগ হয়েছে' : 'কুপন প্রয়োগ হয়নি',
                          style: TextStyle(
                            color: stateColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          applied && discount > 0
                              ? '${message!} মোট ৳${discount.toStringAsFixed(0)} ছাড়।'
                              : message!,
                          style: TextStyle(
                            color: stateColor,
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (applied) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onRemove,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: AppColors.danger,
                      tooltip: 'Remove coupon',
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (applied && discount > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _CouponMiniMetric(
                  label: 'মোট ছাড়',
                  value: '-৳${discount.toStringAsFixed(0)}',
                  icon: Icons.savings_outlined,
                ),
                if (adminDiscount > 0)
                  _CouponMiniMetric(
                    label: 'অ্যাডমিন দিচ্ছে',
                    value: '৳${adminDiscount.toStringAsFixed(0)}',
                    icon: Icons.admin_panel_settings_outlined,
                  ),
                if (restaurantDiscount > 0)
                  _CouponMiniMetric(
                    label: 'রেস্টুরেন্ট দিচ্ছে',
                    value: '৳${restaurantDiscount.toStringAsFixed(0)}',
                    icon: Icons.storefront_outlined,
                  ),
                if (deliveryDiscount > 0)
                  _CouponMiniMetric(
                    label: 'ডেলিভারি ছাড়',
                    value: '৳${deliveryDiscount.toStringAsFixed(0)}',
                    icon: Icons.delivery_dining_rounded,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CouponMiniMetric extends StatelessWidget {
  const _CouponMiniMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final width = ((MediaQuery.sizeOf(context).width - 72) / 2)
        .clamp(140.0, 220.0)
        .toDouble();
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.tealSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.teal, size: 18),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
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
    final itemsTotal = _readMoney(cart['items_total']);
    final deliveryFee = _readNullableMoney(cart['delivery_fee']);
    final discount = num.tryParse('${cart['discount_amount'] ?? 0}') ?? 0;
    final adminDiscount =
        num.tryParse('${cart['admin_discount_amount'] ?? 0}') ?? 0;
    final restaurantDiscount =
        num.tryParse('${cart['restaurant_discount_amount'] ?? 0}') ?? 0;
    final deliveryDiscount =
        num.tryParse('${cart['delivery_discount_amount'] ?? 0}') ?? 0;
    final payableTotal = deliveryFee == null
        ? _readMoney(cart['grand_total'])
        : _payableTotal(
            itemsTotal: itemsTotal,
            deliveryFee: deliveryFee,
            discount: discount,
          );
    return _CheckoutSectionCard(
      title: 'অর্ডারের সংক্ষিপ্ত বিবরণ',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedCountLabel(
                  value: itemCount,
                  suffix: ' টি খাবার',
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatTaka(payableTotal),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _BillRow(label: 'খাবারের মূল্য', value: itemsTotal),
          _BillRow(
            label: 'ডেলিভারি চার্জ',
            value: loading ? '...' : deliveryFee,
            pendingText: cart['delivery_fee'] == null ? 'লোকেশন লাগবে' : null,
          ),
          if (deliveryFee != null)
            _BillRow(label: 'উপমোট', value: itemsTotal + deliveryFee),
          if (discount > 0)
            _BillRow(
              label: 'মোট কুপন ছাড়',
              value: -discount,
              valueColor: AppColors.danger,
            ),
          if (adminDiscount > 0)
            _BillRow(
              label: 'অ্যাডমিন দিচ্ছে',
              value: -adminDiscount,
              valueColor: AppColors.danger,
            ),
          if (restaurantDiscount > 0)
            _BillRow(
              label: 'রেস্টুরেন্ট দিচ্ছে',
              value: -restaurantDiscount,
              valueColor: AppColors.danger,
            ),
          if (deliveryDiscount > 0)
            _BillRow(
              label: 'ডেলিভারি ছাড়',
              value: -deliveryDiscount,
              valueColor: AppColors.danger,
            ),
          if (deliveryFee != null) ...[
            const SizedBox(height: 4),
            _CheckoutCalculationLine(
              itemsTotal: itemsTotal,
              deliveryFee: deliveryFee,
              discount: discount,
              payableTotal: payableTotal,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _BillRow(
            label: 'পরিশোধযোগ্য মোট',
            value: payableTotal,
            strong: true,
            valueColor: AppColors.primary,
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
                    color: AppColors.ink,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
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
      style: const TextStyle(fontSize: 14.5),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
        ),
      ),
    );
  }
}

num _readMoney(dynamic value) {
  if (value == null || value == '...') return 0;
  if (value is num) return value;
  final text = value.toString().replaceAll('৳', '').trim();
  return num.tryParse(text) ?? 0;
}

num? _readNullableMoney(dynamic value) {
  if (value == null || value == '...') return null;
  if (value is num) return value;
  final text = value.toString().replaceAll('৳', '').trim();
  return num.tryParse(text);
}

num _payableTotal({
  required num itemsTotal,
  required num deliveryFee,
  required num discount,
}) {
  return (itemsTotal + deliveryFee - discount).clamp(0, double.infinity);
}

String _formatTaka(dynamic value) {
  if (value == '...') return '...';
  final amount = _readMoney(value);
  final sign = amount < 0 ? '-' : '';
  final absolute = amount.abs();
  final formatted = absolute % 1 == 0
      ? absolute.toStringAsFixed(0)
      : absolute.toStringAsFixed(2);
  return '$sign৳$formatted';
}

class _CheckoutCalculationLine extends StatelessWidget {
  const _CheckoutCalculationLine({
    required this.itemsTotal,
    required this.deliveryFee,
    required this.discount,
    required this.payableTotal,
  });

  final num itemsTotal;
  final num deliveryFee;
  final num discount;
  final num payableTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '${_formatTaka(itemsTotal)} + ${_formatTaka(deliveryFee)} - ${_formatTaka(discount)} = ${_formatTaka(payableTotal)}',
        style: const TextStyle(
          color: AppColors.inkMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.35,
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
                color: strong ? AppColors.ink : AppColors.inkMuted,
                fontSize: strong ? 16 : 14,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: AppMotion.fast,
            child: Text(
              pendingText ?? _formatTaka(value),
              key: ValueKey('$value-$pendingText'),
              style: TextStyle(
                color: valueColor ?? AppColors.ink,
                fontSize: strong ? 16 : 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Flat white card, shared by both screens — the closest thing to a "unit"
/// of this design: soft border, restrained shadow, no gradient.
class _FoodWhiteCard extends StatelessWidget {
  const _FoodWhiteCard({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.card,
      ),
      child: child,
    );
  }
}

class _CheckoutMapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final accentPaint = Paint()
      ..color = AppColors.tealMuted
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
