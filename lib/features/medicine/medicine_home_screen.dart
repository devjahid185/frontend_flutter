import 'dart:async';

import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';

class MedicineHomeScreen extends StatefulWidget {
  const MedicineHomeScreen({super.key});

  @override
  State<MedicineHomeScreen> createState() => _MedicineHomeScreenState();
}

class _MedicineHomeScreenState extends State<MedicineHomeScreen> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  final _search = TextEditingController();
  Timer? _debounce;
  bool _loading = true;
  bool _searching = false;
  int _cartCount = 0;
  Map<String, dynamic> _home = {};
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (mounted) _loadItems();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('/medicine/home');
      final count = await _api.get('/medicine/cart-count');
      if (!mounted) return;
      setState(() {
        _home = Map<String, dynamic>.from(data as Map);
        _items = (_home['items'] as List?) ?? [];
        _cartCount = (count['count'] as num?)?.toInt() ?? 0;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadItems() async {
    setState(() => _searching = true);
    try {
      final data = await _api.get(
        '/medicine/items',
        query: {'q': _search.text.trim(), 'per_page': '60'},
      );
      if (!mounted) return;
      setState(() => _items = (data['data'] as List?) ?? []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _addToCart(Map<String, dynamic> item) async {
    await _api.post(
      '/medicine/cart/items',
      body: {'medicine_item_id': item['id'], 'quantity': 1},
    );
    final count = await _api.get('/medicine/cart-count');
    if (!mounted) return;
    setState(() => _cartCount = (count['count'] as num?)?.toInt() ?? _cartCount + 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['brand_name']} কার্টে যোগ হয়েছে')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final promoted = (_home['promoted_items'] as List?) ?? [];
    return Scaffold(
      backgroundColor: const Color(0xfff7fbf9),
      appBar: ModernAppBar(
        title: 'মেডিসিন ডেলিভারি',
        subtitle: 'ওষুধ খুঁজুন, per pcs price দেখে অর্ডার করুন',
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const MedicineCartScreen()))
                    .then((_) => _load()),
                icon: const Icon(Icons.shopping_bag_outlined),
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 3,
                  top: 3,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.red,
                    child: Text('$_cartCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'মেডিসিন, জেনেরিক বা কোম্পানি খুঁজুন',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searching
                          ? const Padding(padding: EdgeInsets.all(14), child: LogoLoader(size: 18))
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: scheme.outlineVariant)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: scheme.outlineVariant)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _MedicineHero(total: (_home['total_items'] as num?)?.toInt() ?? 0),
                  if (promoted.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _SectionTitle(title: 'Promoted Medicine', subtitle: 'প্রয়োজনীয় আইটেম দ্রুত খুঁজুন'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 174,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (_, i) => SizedBox(width: 220, child: _MedicineCard(item: Map<String, dynamic>.from(promoted[i] as Map), compact: true, onAdd: _addToCart)),
                        separatorBuilder: (_, index) => const SizedBox(width: 12),
                        itemCount: promoted.length,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  _SectionTitle(title: 'সব মেডিসিন', subtitle: 'খুচরা per pcs price অনুযায়ী'),
                  const SizedBox(height: 12),
                  if (_items.isEmpty)
                    const _EmptyMedicine()
                  else
                    ..._items.map((raw) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MedicineCard(item: Map<String, dynamic>.from(raw as Map), onAdd: _addToCart),
                        )),
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
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _loading = true;
  bool _placing = false;
  Map<String, dynamic> _cart = {};

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.get('/medicine/cart');
    if (!mounted) return;
    setState(() {
      _cart = Map<String, dynamic>.from(data as Map);
      _loading = false;
    });
  }

  Future<void> _qty(int id, int quantity) async {
    await _api.post('/medicine/cart/items/$id', body: {'quantity': quantity});
    await _load();
  }

  Future<void> _remove(int id) async {
    await _api.delete('/medicine/cart/items/$id');
    await _load();
  }

  Future<void> _checkout() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty || _address.text.trim().isEmpty) return;
    setState(() => _placing = true);
    try {
      final res = await _api.post('/medicine/checkout', body: {
        'receiver_name': _name.text.trim(),
        'receiver_phone': _phone.text.trim(),
        'delivery_address': _address.text.trim(),
        'payment_method': 'cash_on_delivery',
      });
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MedicineOrderDetailsScreen(order: Map<String, dynamic>.from(res['order'] as Map))));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (_cart['items'] as List?) ?? [];
    return Scaffold(
      backgroundColor: const Color(0xfff7fbf9),
      appBar: const ModernAppBar(title: 'মেডিসিন কার্ট', subtitle: 'অর্ডার কনফার্ম করুন'),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (items.isEmpty)
                  const _EmptyMedicine(text: 'কার্টে কোনো মেডিসিন নেই')
                else
                  ...items.map((raw) {
                    final item = Map<String, dynamic>.from(raw as Map);
                    final medicine = Map<String, dynamic>.from((item['medicine_item'] as Map?) ?? {});
                    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text('${medicine['brand_name'] ?? 'Medicine'}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text('${medicine['strength'] ?? ''} • ৳${item['unit_price']} x $qty'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(onPressed: qty > 1 ? () => _qty(item['id'], qty - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
                          Text('$qty'),
                          IconButton(onPressed: () => _qty(item['id'], qty + 1), icon: const Icon(Icons.add_circle_outline)),
                          IconButton(onPressed: () => _remove(item['id']), icon: const Icon(Icons.delete_outline)),
                        ]),
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                _CheckoutField(controller: _name, label: 'রিসিভারের নাম'),
                _CheckoutField(controller: _phone, label: 'মোবাইল নম্বর', keyboardType: TextInputType.phone),
                _CheckoutField(controller: _address, label: 'ডেলিভারি ঠিকানা', maxLines: 3),
                const SizedBox(height: 10),
                _TotalRow(label: 'মেডিসিন', value: _cart['items_total']),
                _TotalRow(label: 'ডেলিভারি চার্জ', value: _cart['delivery_fee']),
                _TotalRow(label: 'মোট', value: _cart['grand_total'], bold: true),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: items.isEmpty || _placing ? null : _checkout,
                  icon: _placing ? const LogoLoader(size: 18) : const Icon(Icons.local_shipping_outlined),
                  label: const Text('অর্ডার করুন'),
                ),
              ],
            ),
    );
  }
}

class MedicineOrderDetailsScreen extends StatelessWidget {
  const MedicineOrderDetailsScreen({super.key, required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List?) ?? [];
    return Scaffold(
      backgroundColor: const Color(0xfff7fbf9),
      appBar: ModernAppBar(title: '${order['order_no'] ?? 'Medicine Order'}', subtitle: 'অর্ডার ডিটেইলস'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(title: 'স্ট্যাটাস', lines: ['অর্ডার: ${order['status']}', 'পেমেন্ট: ${order['payment_status']}', 'মোট: ৳${order['grand_total']}']),
          const SizedBox(height: 12),
          _InfoCard(title: 'মেডিসিন', lines: items.map((e) {
            final item = Map<String, dynamic>.from(e as Map);
            return '${item['brand_name']} - ${item['quantity']} pcs • ৳${item['total_price']}';
          }).toList()),
          const SizedBox(height: 12),
          _InfoCard(title: 'ডেলিভারি', lines: ['${order['receiver_name']}', '${order['receiver_phone']}', '${order['delivery_address']}']),
        ],
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({required this.item, required this.onAdd, this.compact = false});

  final Map<String, dynamic> item;
  final bool compact;
  final Future<void> Function(Map<String, dynamic>) onAdd;

  @override
  Widget build(BuildContext context) {
    final price = item['unit_price'] == null ? 'Price update soon' : '৳${item['unit_price']} / pcs';
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MedicineDetailsScreen(id: (item['id'] as num).toInt()))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xffdbeee8))),
        child: Row(
          children: [
            _MedicineImage(url: item['image_url']?.toString()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                if (item['is_promoted'] == true) const _Badge(text: 'Promoted'),
                Text('${item['brand_name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                Text([item['strength'], item['dosage_form']].where((e) => e != null && '$e'.isNotEmpty).join(' • '), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${item['generic_name'] ?? item['company'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                Text(price, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xff087464))),
              ]),
            ),
            IconButton.filledTonal(onPressed: () => onAdd(item), icon: const Icon(Icons.add_shopping_cart)),
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.get('/medicine/items/${widget.id}');
    if (mounted) setState(() => _item = Map<String, dynamic>.from(data as Map));
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return Scaffold(
      backgroundColor: const Color(0xfff7fbf9),
      appBar: ModernAppBar(title: item?['brand_name']?.toString() ?? 'Medicine', subtitle: item?['generic_name']?.toString() ?? 'Details'),
      body: item == null
          ? const Center(child: LogoLoader(showLabel: true))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xffdbeee8))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Center(child: _MedicineImage(url: item['image_url']?.toString(), size: 96)),
                    const SizedBox(height: 14),
                    Text('${item['brand_name']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    Text([item['strength'], item['dosage_form']].where((e) => e != null && '$e'.isNotEmpty).join(' • ')),
                    const SizedBox(height: 8),
                    Text('৳${item['unit_price'] ?? 'N/A'} / pcs', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xff087464))),
                    if (item['pack_sizes'] != null) Text('Pack: ${item['pack_sizes']}'),
                    if (item['company'] != null) Text('Company: ${item['company']}'),
                  ]),
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
                      child: _InfoCard(title: entry.key, lines: ['${entry.value}']),
                    ),
                FilledButton.icon(
                  onPressed: () async {
                    await _api.post('/medicine/cart/items', body: {'medicine_item_id': item['id'], 'quantity': 1});
                    if (context.mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MedicineCartScreen()));
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('কার্টে যোগ করুন'),
                ),
              ],
            ),
    );
  }
}

class _MedicineHero extends StatelessWidget {
  const _MedicineHero({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xff087464), Color(0xff2bb99f)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(children: [
        const Icon(Icons.medication_liquid, color: Colors.white, size: 44),
        const SizedBox(width: 14),
        Expanded(child: Text('$total+ বাংলাদেশি মেডিসিন\nবাসায় ডেলিভারির জন্য প্রস্তুত', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
      ]),
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xffe7f5f0),
        child: hasImage
            ? Image.network(url!, fit: BoxFit.cover)
            : const Icon(Icons.local_pharmacy, color: Color(0xff087464), size: 30),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
    ]);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xfffff1d6), borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xff9a5a00), fontSize: 11)),
      );
}

class _EmptyMedicine extends StatelessWidget {
  const _EmptyMedicine({this.text = 'কোনো মেডিসিন পাওয়া যায়নি'});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [const Icon(Icons.search_off, size: 42), const SizedBox(height: 8), Text(text)]),
      );
}

class _CheckoutField extends StatelessWidget {
  const _CheckoutField({required this.controller, required this.label, this.maxLines = 1, this.keyboardType});
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
          decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
        ),
      );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.bold = false});
  final String label;
  final dynamic value;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w500)),
          Text('৳${value ?? 0}', style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w700)),
        ]),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.lines});
  final String title;
  final List<String> lines;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xffe0ece7))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...lines.map((line) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(line))),
        ]),
      );
}
