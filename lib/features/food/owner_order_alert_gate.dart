import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/storage/session_storage.dart';
import 'food_home_screen.dart';
import 'widgets/food_product_card.dart';

enum _OwnerOrderAlertAction { later, allOrders, viewOrder }

class OwnerOrderAlertGate extends StatefulWidget {
  const OwnerOrderAlertGate({super.key, required this.child});

  final Widget child;

  @override
  State<OwnerOrderAlertGate> createState() => _OwnerOrderAlertGateState();
}

class _OwnerOrderAlertGateState extends State<OwnerOrderAlertGate>
    with WidgetsBindingObserver {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  StreamSubscription<Map<String, dynamic>>? _foregroundSubscription;
  StreamSubscription<Map<String, dynamic>>? _tapSubscription;
  Timer? _recoveryTimer;
  bool _checking = false;
  bool _showing = false;
  bool? _isRestaurantOwner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foregroundSubscription = NotificationService.foregroundEvents.listen(
      _handleForegroundEvent,
    );
    _tapSubscription = NotificationService.tapEvents.listen(_handleTapEvent);
    _recoveryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isRestaurantOwner != false) unawaited(_checkForNewOrders());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pendingTap = NotificationService.takePendingTapData();
      if (pendingTap != null) await _handleTapEvent(pendingTap);
      await _checkForNewOrders();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkForNewOrders(force: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _foregroundSubscription?.cancel();
    _tapSubscription?.cancel();
    _recoveryTimer?.cancel();
    super.dispose();
  }

  bool _isOwnerOrderEvent(Map<String, dynamic> data) {
    return data['type']?.toString() == 'food_order' &&
        data['role']?.toString() == 'restaurant_owner' &&
        data['event']?.toString() == 'new_order';
  }

  Future<void> _handleForegroundEvent(Map<String, dynamic> data) async {
    if (!_isOwnerOrderEvent(data)) return;
    _isRestaurantOwner = true;
    await _checkForNewOrders(force: true);
  }

  Future<void> _handleTapEvent(Map<String, dynamic> data) async {
    if (!_isOwnerOrderEvent(data)) return;
    _isRestaurantOwner = true;
    final orderId = int.tryParse('${data['order_id'] ?? ''}');
    if (orderId == null) {
      await _openAllOrders();
      return;
    }
    await _openOrder(orderId);
  }

  Future<void> _checkForNewOrders({bool force = false}) async {
    if (_checking || _showing || (!force && _isRestaurantOwner == false)) {
      return;
    }
    _checking = true;
    try {
      final response = await _api.get('/food/owner/order-alerts');
      if (!mounted || response is! Map) return;
      final payload = Map<String, dynamic>.from(response);
      _isRestaurantOwner = payload['is_owner'] == true;
      final rawOrders = (payload['data'] as List?) ?? const [];
      final orders = rawOrders
          .whereType<Map>()
          .map((order) => Map<String, dynamic>.from(order))
          .toList();
      if (orders.isEmpty) return;
      await _presentOrders(orders);
    } catch (_) {
      // Recovery is best-effort; push delivery and the owner order list remain available.
    } finally {
      _checking = false;
    }
  }

  Future<void> _presentOrders(List<Map<String, dynamic>> orders) async {
    if (!mounted || _showing || orders.isEmpty) return;
    _showing = true;
    final orderIds = orders
        .map((order) => int.tryParse('${order['id'] ?? ''}'))
        .whereType<int>()
        .toList();
    final action = await showModalBottomSheet<_OwnerOrderAlertAction>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.52),
      builder: (_) => _OwnerNewOrderSheet(orders: orders),
    );

    await _markSeen(orderIds);
    _showing = false;
    if (!mounted) return;

    if (action == _OwnerOrderAlertAction.viewOrder) {
      final id = int.tryParse('${orders.first['id'] ?? ''}');
      if (id != null) await _openOrder(id);
    } else if (action == _OwnerOrderAlertAction.allOrders) {
      await _openAllOrders();
    }

    unawaited(_checkForNewOrders(force: true));
  }

  Future<void> _markSeen(List<int> orderIds) async {
    if (orderIds.isEmpty) return;
    try {
      await _api.post(
        '/food/owner/order-alerts/seen',
        body: {'order_ids': orderIds},
      );
    } catch (_) {}
  }

  Future<void> _openOrder(int orderId) async {
    final navigator = Navigator.of(context);
    try {
      final response = await _api.get('/food/owner/orders/$orderId');
      if (!mounted || response is! Map) return;
      final order = Map<String, dynamic>.from(response);
      await navigator.push(
        MaterialPageRoute(
          builder: (_) =>
              FoodOwnerOrderDetailsScreen(order: order, onChanged: () async {}),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('অর্ডারটি খোলা যায়নি: $error')));
    }
  }

  Future<void> _openAllOrders() async {
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FoodOwnerOrdersScreen()));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _OwnerNewOrderSheet extends StatelessWidget {
  const _OwnerNewOrderSheet({required this.orders});

  final List<Map<String, dynamic>> orders;

  String _paymentLabel(String value) {
    return switch (value) {
      'cash_on_delivery' => 'ক্যাশ অন ডেলিভারি',
      'manual_bkash' => 'বিকাশ',
      'manual_nagad' => 'নগদ',
      'online' => 'অনলাইন পেমেন্ট',
      _ => value.replaceAll('_', ' '),
    };
  }

  @override
  Widget build(BuildContext context) {
    final order = orders.first;
    final restaurant = order['restaurant'] is Map
        ? Map<String, dynamic>.from(order['restaurant'] as Map)
        : <String, dynamic>{};
    final items = (order['items'] as List?) ?? const [];
    final itemQuantity = items.fold<int>(0, (total, raw) {
      if (raw is! Map) return total;
      return total + (int.tryParse('${raw['quantity'] ?? 1}') ?? 1);
    });
    final extraCount = orders.length - 1;
    final orderType = order['order_type']?.toString() == 'pickup'
        ? 'পিকআপ'
        : 'ডেলিভারি';
    final note = order['order_note']?.toString().trim() ?? '';

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.tealSoft,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.teal,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'নতুন অর্ডার এসেছে',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            restaurant['name']?.toString() ??
                                'আপনার রেস্টুরেন্ট',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (extraCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '+$extraCount আরও',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${order['order_no'] ?? '#${order['id']}'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            '৳${order['grand_total'] ?? 0}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _OwnerAlertPill(
                            icon: Icons.restaurant_menu_rounded,
                            text: '$itemQuantityটি আইটেম',
                          ),
                          _OwnerAlertPill(
                            icon: Icons.delivery_dining_rounded,
                            text: orderType,
                          ),
                          _OwnerAlertPill(
                            icon: Icons.account_balance_wallet_outlined,
                            text: _paymentLabel(
                              '${order['payment_method'] ?? 'cash_on_delivery'}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: AppColors.inkMuted,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              order['delivery_address']?.toString() ??
                                  'পিকআপ অর্ডার',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.inkMuted,
                                fontSize: 12.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0xFFF2D49A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          size: 19,
                          color: Color(0xFF9A6700),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF704B00),
                              fontSize: 12.5,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(_OwnerOrderAlertAction.later),
                        child: const Text('পরে দেখব'),
                      ),
                    ),
                    if (extraCount > 0) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pop(_OwnerOrderAlertAction.allOrders),
                          child: const Text('সব অর্ডার'),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(_OwnerOrderAlertAction.viewOrder),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('অর্ডার দেখুন'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerAlertPill extends StatelessWidget {
  const _OwnerAlertPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.teal),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.inkMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
