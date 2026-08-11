import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'blood_donor_details_screen.dart';
import 'blood_donor_form_screen.dart';
import 'blood_request_details_screen.dart';
import 'blood_request_form_screen.dart';

class BloodHomeScreen extends StatefulWidget {
  const BloodHomeScreen({super.key});

  @override
  State<BloodHomeScreen> createState() => _BloodHomeScreenState();
}

class _BloodHomeScreenState extends State<BloodHomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<_DonorListTabState> _donorKey =
      GlobalKey<_DonorListTabState>();
  final GlobalKey<_RequestListTabState> _requestKey =
      GlobalKey<_RequestListTabState>();

  Future<void> _openActions() async {
    final scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.volunteer_activism_outlined),
                  title: const Text('ডোনার প্রোফাইল তৈরি/আপডেট'),
                  subtitle: const Text('আপনার তথ্য যুক্ত করুন'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BloodDonorFormScreen(),
                      ),
                    );
                    _donorKey.currentState?.reload();
                  },
                ),
                const SizedBox(height: 6),
                ListTile(
                  leading: const Icon(Icons.campaign_outlined),
                  title: const Text('রক্তের অনুরোধ পোস্ট করুন'),
                  subtitle: const Text('রোগীর জন্য অনুরোধ'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BloodRequestFormScreen(),
                      ),
                    );
                    _requestKey.currentState?.reload();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const ModernAppBar(
          title: 'রক্তদান',
          subtitle: 'ডোনার ও অনুরোধ',
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openActions,
          icon: const Icon(Icons.add),
          label: const Text('নতুন'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TabBar(
                indicatorColor: scheme.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: scheme.onSurface,
                unselectedLabelColor: scheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'ডোনার তালিকা'),
                  Tab(text: 'রক্তের অনুরোধ'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  DonorListTab(key: _donorKey),
                  RequestListTab(key: _requestKey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DonorListTab extends StatefulWidget {
  const DonorListTab({super.key});

  @override
  State<DonorListTab> createState() => _DonorListTabState();
}

class _DonorListTabState extends State<DonorListTab> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _locationController = TextEditingController();
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _lastPage = 1;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  String? _bloodGroup;
  String? _district;

  bool get _hasMore => _page < _lastPage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> reload() async => _load(reset: true);

  Future<void> _load({bool reset = true}) async {
    setState(() {
      if (reset) {
        _page = 1;
        _loading = true;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });

    try {
      final res = await _api.get(
        '/blood-donors',
        query: {
          'page': reset ? '1' : (_page + 1).toString(),
          'per_page': '50',
          if (_bloodGroup != null && _bloodGroup!.isNotEmpty)
            'blood_group': _bloodGroup!,
          if (_district != null && _district!.isNotEmpty)
            'district': _district!,
          if (_locationController.text.trim().isNotEmpty)
            'location': _locationController.text.trim(),
        },
      );
      final list = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _items = reset ? list : [..._items, ...list];
      _page = (res['current_page'] as num?)?.toInt() ?? _page;
      _lastPage = (res['last_page'] as num?)?.toInt() ?? _lastPage;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডেটা লোড করা যায়নি';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    await _load(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _filterCard(context),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: const Center(child: LogoLoader(showLabel: true)),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(_error!, style: TextStyle(color: scheme.error)),
              ),
            )
          else if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('কোনো ডোনার পাওয়া যায়নি')),
            )
          else ...[
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 240 + (index * 25)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - value)),
                    child: child,
                  ),
                ),
                child: _donorCard(context, item),
              );
            }),
            if (_hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 22),
                child: OutlinedButton.icon(
                  onPressed: _loadingMore ? null : _loadMore,
                  icon: _loadingMore
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: LogoLoader(size: 16),
                        )
                      : const Icon(Icons.expand_more_rounded),
                  label: Text(_loadingMore ? 'লোড হচ্ছে...' : 'আরও দেখুন'),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _filterCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _bloodGroup,
                  decoration: const InputDecoration(labelText: 'রক্তের গ্রুপ'),
                  items:
                      const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _bloodGroup = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'জেলা'),
                  onChanged: (value) =>
                      _district = value.trim().isEmpty ? null : value.trim(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'লোকেশন বা ঠিকানা',
              suffixIcon: IconButton(
                onPressed: () {
                  _locationController.clear();
                  _load(reset: true);
                },
                icon: const Icon(Icons.clear),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _load(reset: true),
              icon: const Icon(Icons.search),
              label: const Text('খুঁজুন'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _donorCard(BuildContext context, Map<String, dynamic> item) {
    final scheme = Theme.of(context).colorScheme;
    final name = (item['name'] ?? 'ডোনার').toString();
    final group = (item['blood_group'] ?? '-').toString();
    final location = (item['location'] ?? item['district'] ?? '').toString();
    final lastDonation = (item['last_donation'] ?? '-').toString();
    final available = item['available'] == true || item['available'] == 1;

    return InkWell(
      onTap: () {
        final id = (item['id'] as num?)?.toInt() ?? 0;
        if (id > 0) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BloodDonorDetailsScreen(donorId: id),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: scheme.primary,
              child: Text(
                group,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location.isEmpty ? 'লোকেশন নেই' : location,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'শেষ ডোনেশন: $lastDonation',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: available ? scheme.primary : scheme.error,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                available ? 'Available' : 'Unavailable',
                style: TextStyle(color: scheme.onPrimary, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RequestListTab extends StatefulWidget {
  const RequestListTab({super.key});

  @override
  State<RequestListTab> createState() => _RequestListTabState();
}

class _RequestListTabState extends State<RequestListTab> {
  final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _lastPage = 1;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  String? _bloodGroup;
  String _status = 'open';

  bool get _hasMore => _page < _lastPage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() async => _load(reset: true);

  Future<void> _load({bool reset = true}) async {
    setState(() {
      if (reset) {
        _page = 1;
        _loading = true;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });

    try {
      final res = await _api.get(
        '/blood-requests',
        query: {
          'page': reset ? '1' : (_page + 1).toString(),
          'per_page': '50',
          if (_bloodGroup != null && _bloodGroup!.isNotEmpty)
            'blood_group': _bloodGroup!,
          if (_status.isNotEmpty) 'status': _status,
        },
      );
      final list = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _items = reset ? list : [..._items, ...list];
      _page = (res['current_page'] as num?)?.toInt() ?? _page;
      _lastPage = (res['last_page'] as num?)?.toInt() ?? _lastPage;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডেটা লোড করা যায়নি';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    await _load(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _filterCard(context),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: const Center(child: LogoLoader(showLabel: true)),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(_error!, style: TextStyle(color: scheme.error)),
              ),
            )
          else if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('কোনো অনুরোধ পাওয়া যায়নি')),
            )
          else ...[
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 240 + (index * 25)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - value)),
                    child: child,
                  ),
                ),
                child: _requestCard(context, item),
              );
            }),
            if (_hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 22),
                child: OutlinedButton.icon(
                  onPressed: _loadingMore ? null : _loadMore,
                  icon: _loadingMore
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: LogoLoader(size: 16),
                        )
                      : const Icon(Icons.expand_more_rounded),
                  label: Text(_loadingMore ? 'লোড হচ্ছে...' : 'আরও দেখুন'),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _filterCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _bloodGroup,
              decoration: const InputDecoration(labelText: 'রক্তের গ্রুপ'),
              items: const [
                'A+',
                'A-',
                'B+',
                'B-',
                'AB+',
                'AB-',
                'O+',
                'O-',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) => setState(() => _bloodGroup = value),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'স্ট্যাটাস'),
              items: const [
                DropdownMenuItem(value: 'open', child: Text('Open')),
                DropdownMenuItem(value: 'closed', child: Text('Closed')),
              ],
              onChanged: (value) => setState(() => _status = value ?? 'open'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _load(reset: true),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }

  Widget _requestCard(BuildContext context, Map<String, dynamic> item) {
    final scheme = Theme.of(context).colorScheme;
    final group = (item['blood_group'] ?? '-').toString();
    final hospital = (item['hospital'] ?? 'হাসপাতাল নেই').toString();
    final neededAt = (item['needed_at'] ?? 'তারিখ নেই').toString();
    final status = (item['status'] ?? 'open').toString();

    return InkWell(
      onTap: () {
        final id = (item['id'] as num?)?.toInt() ?? 0;
        if (id > 0) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BloodRequestDetailsScreen(requestId: id),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                group,
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospital,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'প্রয়োজন: $neededAt',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: status == 'open'
                    ? scheme.primary
                    : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status == 'open' ? 'Open' : 'Closed',
                style: TextStyle(color: scheme.onPrimary, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
