import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import 'modern_app_bar.dart';
import '../home/worker_details_screen.dart';
import '../doctor/doctor_details_screen.dart';
import '../hospital/hospital_details_screen.dart';
import '../hotel/hotel_details_screen.dart';
import '../restaurant/restaurant_details_screen.dart';
import '../education/education_details_screen.dart';
import '../car_rental/car_rental_details_screen.dart';
import '../courier/courier_office_list_screen.dart';
import '../electricity/electricity_office_details_screen.dart';
import '../teacher/teacher_details_screen.dart';
import '../home/business_details_screen.dart';
import '../home/marketplace_item_details_screen.dart';
import 'module_layout.dart';
import 'ui_states.dart';

class ApiListScreen extends StatefulWidget {
  const ApiListScreen({
    super.key,
    required this.title,
    required this.endpoint,
    this.query,
    this.layout = ModuleLayout.generic,
    this.floatingActionButton,
  });

  final String title;
  final String endpoint;
  final Map<String, String>? query;
  final ModuleLayout layout;
  final Widget? floatingActionButton;

  @override
  State<ApiListScreen> createState() => _ApiListScreenState();
}

class _ApiListScreenState extends State<ApiListScreen> {
  late final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _businessCategorySearchController = TextEditingController();
  final TextEditingController _marketplaceCategorySearchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _locationFilterController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  bool _loadingBusinessCategories = false;
  bool _loadingMarketplaceCategories = false;
  String? _error;
  String? _businessCategoryError;
  String? _marketplaceCategoryError;
  List<dynamic> _items = [];
  List<Map<String, dynamic>> _businessCategories = [];
  List<Map<String, dynamic>> _marketplaceCategories = [];
  int _currentPage = 1;
  int _lastPage = 1;
  int? _selectedBusinessCategoryId;
  int? _selectedMarketplaceCategoryId;
  String _selectedCondition = 'all';
  String _selectedSort = 'newest';

  bool get _hasMore => _currentPage < _lastPage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.layout == ModuleLayout.business) {
      _loadBusinessCategories();
    }
    if (widget.layout == ModuleLayout.marketplace) {
      _loadMarketplaceCategories();
    }
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _businessCategorySearchController.dispose();
    _marketplaceCategorySearchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _locationFilterController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || !_hasMore || _loading) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent - 120;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  Future<void> _load({required bool reset}) async {
    setState(() {
      if (reset) {
        _loading = true;
      }
      _error = null;
    });

    try {
      final res = await _api.get(widget.endpoint, query: _buildQuery(1));
      _applyResponse(res, reset: true);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডেটা লোড করা যায়নি';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final res = await _api.get(widget.endpoint, query: _buildQuery(nextPage));
      _applyResponse(res, reset: false);
    } catch (_) {
      // silent fail for load-more
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Map<String, String> _buildQuery(int page) {
    final query = <String, String>{...?(widget.query)};
    query['page'] = '$page';
    if (widget.layout == ModuleLayout.business && _selectedBusinessCategoryId != null) {
      query['category_id'] = '${_selectedBusinessCategoryId!}';
    }
    if (widget.layout == ModuleLayout.marketplace) {
      if (_selectedMarketplaceCategoryId != null) {
        query['category_id'] = '${_selectedMarketplaceCategoryId!}';
      }
      if (_minPriceController.text.trim().isNotEmpty) {
        query['min_price'] = _minPriceController.text.trim();
      }
      if (_maxPriceController.text.trim().isNotEmpty) {
        query['max_price'] = _maxPriceController.text.trim();
      }
      if (_locationFilterController.text.trim().isNotEmpty) {
        query['location'] = _locationFilterController.text.trim();
      }
      if (_selectedCondition != 'all') {
        query['condition'] = _selectedCondition;
      }
      if (_selectedSort != 'newest') {
        query['sort'] = _selectedSort;
      }
    }
    return query;
  }

  Future<void> _loadBusinessCategories() async {
    setState(() {
      _loadingBusinessCategories = true;
      _businessCategoryError = null;
    });

    try {
      final res = await _api.get('/business/categories');
      if (res is List) {
        _businessCategories = res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _businessCategoryError = 'ক্যাটাগরি লোড হয়নি';
      }
    } on ApiException catch (e) {
      _businessCategoryError = e.message;
    } catch (_) {
      _businessCategoryError = 'ক্যাটাগরি লোড হয়নি';
    } finally {
      if (mounted) {
        setState(() => _loadingBusinessCategories = false);
      }
    }
  }

  Future<void> _loadMarketplaceCategories() async {
    setState(() {
      _loadingMarketplaceCategories = true;
      _marketplaceCategoryError = null;
    });

    try {
      final res = await _api.get('/items/category');
      if (res is List) {
        _marketplaceCategories = res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _marketplaceCategoryError = 'ক্যাটাগরি লোড হয়নি';
      }
    } on ApiException catch (e) {
      _marketplaceCategoryError = e.message;
    } catch (_) {
      _marketplaceCategoryError = 'ক্যাটাগরি লোড হয়নি';
    } finally {
      if (mounted) {
        setState(() => _loadingMarketplaceCategories = false);
      }
    }
  }

  void _applyResponse(dynamic res, {required bool reset}) {
    if (res is Map<String, dynamic> && res['data'] is List) {
      final fetched = res['data'] as List<dynamic>;
      final currentPage = (res['current_page'] as num?)?.toInt() ?? 1;
      final lastPage = (res['last_page'] as num?)?.toInt() ?? 1;

      setState(() {
        _currentPage = currentPage;
        _lastPage = lastPage;
        _items = reset ? fetched : [..._items, ...fetched];
      });
      return;
    }

    if (res is List) {
      setState(() {
        _currentPage = 1;
        _lastPage = 1;
        _items = res;
      });
      return;
    }

    setState(() {
      _currentPage = 1;
      _lastPage = 1;
      _items = [res];
    });
  }

  List<dynamic> get _filteredItems {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _items;

    return _items.where((item) {
      if (item is Map<String, dynamic>) {
        return item.entries.any((e) => '${e.key} ${e.value}'.toLowerCase().contains(q));
      }
      return item.toString().toLowerCase().contains(q);
    }).toList();
  }

  Color _statusColor(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    final value = status.toLowerCase();
    if (value.contains('approved') || value.contains('success') || value.contains('done') || value.contains('active')) {
      return scheme.primary;
    }
    if (value.contains('pending') || value.contains('review')) {
      return scheme.tertiary;
    }
    if (value.contains('cancel') || value.contains('reject') || value.contains('failed') || value.contains('inactive')) {
      return scheme.error;
    }
    return scheme.secondary;
  }

  String? _normalizeImageUrl(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty || value == '-') return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      try {
        final uri = Uri.parse(value);
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          final apiUri = Uri.parse(AppConfig.apiBaseUrl);
          final origin = '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
          return '$origin${uri.path}';
        }
      } catch (_) {}
      return value;
    }

    final apiUri = Uri.parse(AppConfig.apiBaseUrl);
    final origin = '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';

    if (value.startsWith('/')) {
      return '$origin$value';
    }

    return '$origin/storage/$value';
  }

  String? _extractImageUrl(Map<String, dynamic> item) {
    const keys = [
      'image_url',
      'photo_url',
      'logo_url',
      'worker_photo_url',
      'image',
      'photo',
      'logo',
      'url',
    ];

    for (final key in keys) {
      final v = item[key]?.toString();
      final normalized = _normalizeImageUrl(v);
      if (normalized != null) return normalized;
    }

    if (item['images'] is List && (item['images'] as List).isNotEmpty) {
      final first = (item['images'] as List).first?.toString();
      return _normalizeImageUrl(first);
    }

    return null;
  }

  Future<void> _showPhoneDialog(BuildContext context, String phone) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: scheme.surface,
          title: Text('কর্মীর ফোন নম্বর', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Text(
                  phone,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.onSurface),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('বন্ধ করুন', style: TextStyle(color: scheme.onSurface)),
            ),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: phone));
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('নম্বর কপি হয়েছে')));
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('কপি করুন'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRatingDialog(BuildContext context, int workerId) async {
    int selected = 5;
    final commentController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: scheme.surface,
          title: Text('রেটিং দিন', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700)),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final idx = i + 1;
                      return IconButton(
                        onPressed: () => setState(() => selected = idx),
                        icon: Icon(
                          idx <= selected ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber.shade700,
                        ),
                      );
                    }),
                  ),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      labelText: 'কমেন্ট (ঐচ্ছিক)',
                      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('বাতিল', style: TextStyle(color: scheme.onSurface)),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await _api.post(
                    '/reviews/worker',
                    body: {
                      'target_id': workerId,
                      'rating': selected,
                      'comment': commentController.text.trim().isEmpty ? null : commentController.text.trim(),
                    },
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রেটিং জমা হয়েছে')));
                  }
                } on ApiException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রেটিং জমা হয়নি')));
                  }
                }
              },
              child: const Text('সাবমিট'),
            ),
          ],
        );
      },
    );
  }

  Widget _thumb({
    required BuildContext context,
    required String? imageUrl,
    double width = 52,
    double height = 52,
    double radius = 12,
    IconData fallbackIcon = Icons.image_outlined,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        color: scheme.surfaceContainer,
        child: imageUrl == null
            ? Icon(fallbackIcon, color: scheme.onSurfaceVariant, size: 20)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(fallbackIcon, color: scheme.onSurfaceVariant, size: 20),
              ),
      ),
    );
  }

  Widget _metaChip(
    BuildContext context,
    String label, {
    IconData? icon,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(14),
    EdgeInsets margin = const EdgeInsets.only(bottom: 12),
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  Widget _searchSection(BuildContext context) {
    return _sectionCard(
      context: context,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'তালিকা থেকে খুঁজুন',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }

  Widget _headerSection(BuildContext context, int count) {
    final scheme = Theme.of(context).colorScheme;
    return _sectionCard(
      context: context,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.view_list_rounded, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'মোট ফলাফল: $count',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  _hasMore ? 'আরও ডেটা লোড করা যাবে' : 'সব ডেটা দেখানো হয়েছে',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          _metaChip(context, 'পৃষ্ঠা $_currentPage/$_lastPage', icon: Icons.layers_outlined),
        ],
      ),
    );
  }

  Widget _businessFilterSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedName = _businessCategories
        .firstWhere(
          (c) => (c['id'] as num?)?.toInt() == _selectedBusinessCategoryId,
          orElse: () => {'name': 'সব ক্যাটাগরি'},
        )['name']
        ?.toString();

    return _sectionCard(
      context: context,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.filter_list_rounded, color: scheme.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ক্যাটাগরি ফিল্টার', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  selectedName?.isNotEmpty == true ? selectedName! : 'সব ক্যাটাগরি',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                ),
                if (_businessCategoryError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_businessCategoryError!, style: TextStyle(color: scheme.error, fontSize: 12)),
                  ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _loadingBusinessCategories ? null : () => _openBusinessCategoryPicker(context),
            icon: _loadingBusinessCategories
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.tune_rounded),
            label: const Text('বাছাই'),
          ),
        ],
      ),
    );
  }

  Widget _marketplaceFilterSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedName = _marketplaceCategories
        .firstWhere(
          (c) => (c['id'] as num?)?.toInt() == _selectedMarketplaceCategoryId,
          orElse: () => {'name': 'সব ক্যাটাগরি'},
        )['name']
        ?.toString();

    return _sectionCard(
      context: context,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.filter_list_rounded, color: scheme.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ফিল্টার', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  selectedName?.isNotEmpty == true ? selectedName! : 'সব ক্যাটাগরি',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                ),
                if (_marketplaceCategoryError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_marketplaceCategoryError!, style: TextStyle(color: scheme.error, fontSize: 12)),
                  ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _loadingMarketplaceCategories ? null : () => _openMarketplaceFilter(context),
            icon: _loadingMarketplaceCategories
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.tune_rounded),
            label: const Text('ফিল্টার'),
          ),
        ],
      ),
    );
  }

  Future<void> _openMarketplaceFilter(BuildContext context) async {
    _marketplaceCategorySearchController.clear();
    var filtered = List<Map<String, dynamic>>.from(_marketplaceCategories);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.85,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 46,
                        height: 4,
                        decoration: BoxDecoration(
                          color: scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _marketplaceCategorySearchController,
                          decoration: InputDecoration(
                            hintText: 'ক্যাটাগরি সার্চ করুন',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _marketplaceCategorySearchController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _marketplaceCategorySearchController.clear();
                                      setSheetState(() => filtered = List<Map<String, dynamic>>.from(_marketplaceCategories));
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                          onChanged: (value) {
                            final query = value.trim().toLowerCase();
                            setSheetState(() {
                              if (query.isEmpty) {
                                filtered = List<Map<String, dynamic>>.from(_marketplaceCategories);
                              } else {
                                filtered = _marketplaceCategories.where((c) {
                                  final name = c['name']?.toString().toLowerCase() ?? '';
                                  return name.contains(query);
                                }).toList();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            Text('ক্যাটাগরি', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            _categoryOption(
                              context,
                              label: 'সব ক্যাটাগরি',
                              selected: _selectedMarketplaceCategoryId == null,
                              onTap: () => setSheetState(() => _selectedMarketplaceCategoryId = null),
                            ),
                            const SizedBox(height: 8),
                            ...filtered.map((category) {
                              final id = (category['id'] as num?)?.toInt();
                              final name = category['name']?.toString() ?? '-';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _categoryOption(
                                  context,
                                  label: name,
                                  selected: id != null && id == _selectedMarketplaceCategoryId,
                                  onTap: () => setSheetState(() => _selectedMarketplaceCategoryId = id),
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                            Text('দাম (৳)', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _minPriceController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(hintText: 'সর্বনিম্ন'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _maxPriceController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(hintText: 'সর্বোচ্চ'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('লোকেশন', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _locationFilterController,
                              decoration: const InputDecoration(hintText: 'জেলা/এলাকা লিখুন'),
                            ),
                            const SizedBox(height: 12),
                            Text('অবস্থা', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('সব'),
                                  selected: _selectedCondition == 'all',
                                  onSelected: (_) => setSheetState(() => _selectedCondition = 'all'),
                                  selectedColor: scheme.primaryContainer,
                                ),
                                ChoiceChip(
                                  label: const Text('নতুন'),
                                  selected: _selectedCondition == 'new',
                                  onSelected: (_) => setSheetState(() => _selectedCondition = 'new'),
                                  selectedColor: scheme.primaryContainer,
                                ),
                                ChoiceChip(
                                  label: const Text('ব্যবহৃত'),
                                  selected: _selectedCondition == 'used',
                                  onSelected: (_) => setSheetState(() => _selectedCondition = 'used'),
                                  selectedColor: scheme.primaryContainer,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('সোর্ট', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('নতুন'),
                                  selected: _selectedSort == 'newest',
                                  onSelected: (_) => setSheetState(() => _selectedSort = 'newest'),
                                  selectedColor: scheme.primaryContainer,
                                ),
                                ChoiceChip(
                                  label: const Text('দাম কম'),
                                  selected: _selectedSort == 'price_asc',
                                  onSelected: (_) => setSheetState(() => _selectedSort = 'price_asc'),
                                  selectedColor: scheme.primaryContainer,
                                ),
                                ChoiceChip(
                                  label: const Text('দাম বেশি'),
                                  selected: _selectedSort == 'price_desc',
                                  onSelected: (_) => setSheetState(() => _selectedSort = 'price_desc'),
                                  selectedColor: scheme.primaryContainer,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setSheetState(() {
                                        _selectedMarketplaceCategoryId = null;
                                        _minPriceController.clear();
                                        _maxPriceController.clear();
                                        _locationFilterController.clear();
                                        _selectedCondition = 'all';
                                        _selectedSort = 'newest';
                                      });
                                    },
                                    child: const Text('রিসেট'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _load(reset: true);
                                    },
                                    child: const Text('এপ্লাই'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _categoryOption(BuildContext context, {required String label, required bool selected, required VoidCallback onTap}) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: selected
            ? Icon(Icons.check_circle, color: scheme.primary)
            : Icon(Icons.arrow_forward_ios, size: 14, color: scheme.outline),
        onTap: onTap,
      ),
    );
  }

  Future<void> _openBusinessCategoryPicker(BuildContext context) async {
    _businessCategorySearchController.clear();
    var filtered = List<Map<String, dynamic>>.from(_businessCategories);

    final selected = await showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 46,
                        height: 4,
                        decoration: BoxDecoration(
                          color: scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _businessCategorySearchController,
                          decoration: InputDecoration(
                            hintText: 'ক্যাটাগরি সার্চ করুন',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _businessCategorySearchController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _businessCategorySearchController.clear();
                                      setSheetState(() => filtered = List<Map<String, dynamic>>.from(_businessCategories));
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                          onChanged: (value) {
                            final query = value.trim().toLowerCase();
                            setSheetState(() {
                              if (query.isEmpty) {
                                filtered = List<Map<String, dynamic>>.from(_businessCategories);
                              } else {
                                filtered = _businessCategories.where((c) {
                                  final name = c['name']?.toString().toLowerCase() ?? '';
                                  return name.contains(query);
                                }).toList();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              final selected = _selectedBusinessCategoryId == null;
                              return Material(
                                color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Text(
                                    'সব ক্যাটাগরি',
                                    style: TextStyle(
                                      color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: selected
                                      ? Icon(Icons.check_circle, color: scheme.primary)
                                      : Icon(Icons.arrow_forward_ios, size: 14, color: scheme.outline),
                                  onTap: () => Navigator.of(context).pop(null),
                                ),
                              );
                            }

                            final category = filtered[index - 1];
                            final id = (category['id'] as num?)?.toInt();
                            final name = category['name']?.toString() ?? '-';
                            final selected = id != null && id == _selectedBusinessCategoryId;
                            return Material(
                              color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              child: ListTile(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: selected
                                    ? Icon(Icons.check_circle, color: scheme.primary)
                                    : Icon(Icons.arrow_forward_ios, size: 14, color: scheme.outline),
                                onTap: () => Navigator.of(context).pop(id),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (selected != _selectedBusinessCategoryId) {
      setState(() => _selectedBusinessCategoryId = selected);
      _load(reset: true);
    }
  }

  Widget _renderMapItem(BuildContext context, Map<String, dynamic> item) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = _extractImageUrl(item);

    String getS(String key, [String fallback = '-']) => (item[key]?.toString().trim().isNotEmpty ?? false)
        ? item[key].toString()
        : fallback;

    switch (widget.layout) {
      case ModuleLayout.business:
        final name = getS('name', 'ব্যবসা');
        final category = getS('category_name', '-');
        final address = getS('address', '-');
        final phone = getS('phone', '');
        final businessId = (item['id'] as num?)?.toInt() ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: businessId > 0
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => BusinessDetailsScreen(businessId: businessId)),
                  );
                }
              : null,
          child: _sectionCard(
            context: context,
            child: Row(
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(imageUrl, width: 52, height: 52, fit: BoxFit.cover),
                  )
                else
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.characters.first.toUpperCase(),
                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(address, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                      const SizedBox(height: 4),
                      Text(category, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
                if (phone.isNotEmpty && phone != '-')
                  IconButton(
                    onPressed: () => _showPhoneDialog(context, phone),
                    icon: Icon(Icons.call_outlined, color: scheme.primary),
                  ),
              ],
            ),
          ),
        );

      case ModuleLayout.directory:
        final name = getS('name', getS('worker_name', 'নাম নেই'));
        final phone = getS('phone', '');
        final subtitle = getS('address', getS('district', getS('location', '-')));
        final ratingValue = getS('user_rating', getS('rating', '')).trim();
        final rating = double.tryParse(ratingValue);
        final workerId = (item['id'] as num?)?.toInt() ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: workerId > 0
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => WorkerDetailsScreen(workerId: workerId)),
                  );
                }
              : null,
          child: _sectionCard(
            context: context,
            child: Column(
              children: [
              Row(
                children: [
                  if (imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(imageUrl, width: 52, height: 52, fit: BoxFit.cover),
                    )
                  else
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name.substring(0, 1).toUpperCase(),
                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  if (phone != '-')
                    IconButton(
                      onPressed: () => _showPhoneDialog(context, phone),
                      icon: Icon(Icons.call_outlined, color: scheme.primary),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (rating != null) _metaChip(context, rating.toStringAsFixed(1), icon: Icons.star_rounded, color: Colors.amber.shade700),
                  _metaChip(context, getS('category', 'Directory'), icon: Icons.badge_outlined),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: workerId > 0 ? () => _showRatingDialog(context, workerId) : null,
                  icon: const Icon(Icons.star_rate_rounded),
                  label: const Text('রেটিং দিন'),
                ),
              ),
              ],
            ),
          ),
        );

      case ModuleLayout.doctor:
        final name = getS('name', 'ডাক্তার');
        final category = getS('category_name', '-');
        final hospital = getS('hospital', '-');
        final fees = getS('fees', '');
        final doctorId = (item['id'] as num?)?.toInt() ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: doctorId > 0
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DoctorDetailsScreen(doctorId: doctorId)),
                  );
                }
              : null,
          child: _sectionCard(
            context: context,
            child: Row(
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(imageUrl, width: 52, height: 52, fit: BoxFit.cover),
                  )
                else
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.characters.first.toUpperCase(),
                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(hospital, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                      const SizedBox(height: 4),
                      Text(category, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
                if (fees.isNotEmpty && fees != '-')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('৳ $fees', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
              ],
            ),
          ),
        );

      case ModuleLayout.hospital:
        final name = getS('name', 'হাসপাতাল');
        final category = getS('category_name', '-');
        final district = getS('district', '-');
        final id = (item['id'] as num?)?.toInt() ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: id > 0
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => HospitalDetailsScreen(hospitalId: id)),
                  )
              : null,
          child: _sectionCard(
            context: context,
            child: Row(
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(imageUrl, width: 52, height: 52, fit: BoxFit.cover),
                  )
                else
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.characters.first.toUpperCase(),
                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(district, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                      const SizedBox(height: 4),
                      Text(category, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case ModuleLayout.hotel:
        final name = getS('name', 'হোটেল');
        final category = getS('category_name', '-');
        final district = getS('district', '-');
        final id = (item['id'] as num?)?.toInt() ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: id > 0
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => HotelDetailsScreen(hotelId: id)),
                  )
              : null,
          child: _sectionCard(
            context: context,
            child: Row(
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(imageUrl, width: 52, height: 52, fit: BoxFit.cover),
                  )
                else
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.characters.first.toUpperCase(),
                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(district, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                      const SizedBox(height: 4),
                      Text(category, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case ModuleLayout.restaurant:
        final name = getS('name', 'রেস্টুরেন্ট');
        final category = getS('category_name', '-');
        final district = getS('district', '-');
        final id = (item['id'] as num?)?.toInt() ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: id > 0
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => RestaurantDetailsScreen(restaurantId: id)),
                  )
              : null,
          child: _sectionCard(
            context: context,
            child: Row(
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(imageUrl, width: 52, height: 52, fit: BoxFit.cover),
                  )
                else
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.characters.first.toUpperCase(),
                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(district, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                      const SizedBox(height: 4),
                      Text(category, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case ModuleLayout.education:
        final name = getS('name', 'শিক্ষা প্রতিষ্ঠান');
        final category = getS('category_name', '-');
        final district = getS('district', '-');
        final id = (item['id'] as num?)?.toInt() ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: id > 0
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => EducationDetailsScreen(instituteId: id)),
                  )
              : null,
          child: _sectionCard(
            context: context,
            child: Row(
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(imageUrl, width: 52, height: 52, fit: BoxFit.cover),
                  )
                else
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    child: Icon(Icons.school, color: scheme.primary),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(district, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                      const SizedBox(height: 4),
                      Text(category, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case ModuleLayout.carRental:
        final title = getS('title', 'গাড়ি');
        final district = getS('district', '-');
        final price = getS('price_per_day', '');
        final id = (item['id'] as num?)?.toInt() ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: id > 0
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CarRentalDetailsScreen(rentalId: id)),
                  )
              : null,
          child: _sectionCard(
            context: context,
            child: Row(
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(imageUrl, width: 52, height: 52, fit: BoxFit.cover),
                  )
                else
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      title.characters.first.toUpperCase(),
                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(district, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                    ],
                  ),
                ),
                if (price.isNotEmpty && price != 'null')
                  Text('৳ $price/দিন', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );

      case ModuleLayout.courier:
        final name = getS('name', 'কুরিয়ার');
        final rating = double.tryParse(getS('rating', '0')) ?? 0;
        final offices = getS('offices_count', '0');
        final id = (item['id'] as num?)?.toInt() ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: id > 0
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CourierOfficeListScreen(companyId: id, companyName: name)),
                  )
              : null,
          child: _sectionCard(
            context: context,
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.characters.first.toUpperCase(),
                    style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('অফিস: $offices', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 2),
                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        );

      case ModuleLayout.electricity:
        final name = getS('name', 'বিদ্যুৎ অফিস');
        final provider = getS('provider', '-');
        final district = getS('district', '-');
        final id = (item['id'] as num?)?.toInt() ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: id > 0
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ElectricityOfficeDetailsScreen(officeId: id)),
                  )
              : null,
          child: _sectionCard(
            context: context,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.electrical_services_outlined, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(provider, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                      const SizedBox(height: 4),
                      Text(district, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case ModuleLayout.teacher:
        final name = getS('name', 'শিক্ষক');
        final title = getS('title', '');
        final rating = double.tryParse(getS('rating', '0')) ?? 0;
        final id = (item['id'] as num?)?.toInt() ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: id > 0
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TeacherDetailsScreen(teacherId: id)),
                  )
              : null,
          child: _sectionCard(
            context: context,
            child: Row(
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(imageUrl, width: 52, height: 52, fit: BoxFit.cover),
                  )
                else
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    child: Icon(Icons.school, color: scheme.primary),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      if (title.isNotEmpty) Text(title, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 2),
                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        );

      case ModuleLayout.marketplace:
        final itemId = (item['id'] as num?)?.toInt() ?? 0;
        final title = getS('title', 'আইটেম');
        final price = getS('price', '0');
        final location = getS('location', 'লোকেশন নেই');
        final condition = getS('condition', 'ব্যবহৃত');
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: itemId > 0
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => MarketplaceItemDetailsScreen(itemId: itemId)),
                  );
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: imageUrl == null
                      ? Container(
                          height: 120,
                          color: scheme.surfaceContainer,
                          child: Center(
                            child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
                          ),
                        )
                      : Image.network(
                          imageUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text('৳ $price', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 13, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _metaChip(context, condition == 'new' ? 'নতুন' : 'ব্যবহৃত', icon: Icons.inventory_2_outlined),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case ModuleLayout.jobs:
        return _sectionCard(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _thumb(context: context, imageUrl: imageUrl, width: 34, height: 34, radius: 9, fallbackIcon: Icons.work_outline_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      getS('title', 'চাকরি'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(getS('salary', '-'), style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _metaChip(context, getS('company', '-'), icon: Icons.apartment_outlined),
                  _metaChip(context, getS('location', '-'), icon: Icons.location_on_outlined),
                  _metaChip(context, getS('job_type', 'ফুল-টাইম'), icon: Icons.schedule_outlined),
                ],
              ),
            ],
          ),
        );

      case ModuleLayout.property:
        return _sectionCard(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null) ...[
                _thumb(
                  context: context,
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 130,
                  radius: 12,
                  fallbackIcon: Icons.home_work_outlined,
                ),
                const SizedBox(height: 10),
              ],
              Text(getS('title', 'প্রোপার্টি'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _metaChip(context, getS('type', '-'), icon: Icons.home_work_outlined),
                  _metaChip(context, getS('location', '-'), icon: Icons.location_city_outlined),
                  _metaChip(context, getS('size', 'N/A'), icon: Icons.square_foot_outlined),
                ],
              ),
              const SizedBox(height: 10),
              Text('৳ ${getS('price', '0')}', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
        );

      case ModuleLayout.blood:
        final available = getS('available', '1') == '1' || getS('available').toLowerCase() == 'true';
        return _sectionCard(
          context: context,
          child: Row(
            children: [
              if (imageUrl != null)
                CircleAvatar(radius: 22, backgroundImage: NetworkImage(imageUrl))
              else
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.errorContainer,
                  child: Text(
                    getS('blood_group', '?'),
                    style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(getS('location', 'লোকেশন নেই'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('শেষ ডোনেশন: ${getS('last_donation', '-')}', style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              _metaChip(
                context,
                available ? 'Available' : 'Unavailable',
                icon: available ? Icons.favorite : Icons.block,
                color: available ? scheme.primary : scheme.error,
              ),
            ],
          ),
        );

      case ModuleLayout.emergency:
        return _sectionCard(
          context: context,
          child: Row(
            children: [
              _thumb(context: context, imageUrl: imageUrl, width: 40, height: 40, radius: 12, fallbackIcon: Icons.local_hospital_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(getS('name', 'Emergency'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(getS('category', '-'), style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () {},
                icon: const Icon(Icons.call, size: 16),
                label: Text(getS('phone', 'কল')),
              ),
            ],
          ),
        );

      case ModuleLayout.news:
        return _sectionCard(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null) ...[
                _thumb(
                  context: context,
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 140,
                  radius: 12,
                  fallbackIcon: Icons.newspaper_outlined,
                ),
                const SizedBox(height: 10),
              ],
              Text(getS('title', 'সংবাদ'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              Text(
                getS('content', '-'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _metaChip(context, getS('author', 'ডেস্ক'), icon: Icons.person_outline_rounded),
                  const SizedBox(width: 8),
                  _metaChip(context, getS('published_at', 'আজ'), icon: Icons.schedule_outlined),
                ],
              ),
            ],
          ),
        );

      case ModuleLayout.notices:
        final category = getS('category', 'General');
        return _sectionCard(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(getS('title', 'নোটিশ'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  if (imageUrl != null) ...[
                    _thumb(context: context, imageUrl: imageUrl, width: 34, height: 34, radius: 8),
                    const SizedBox(width: 8),
                  ],
                  _metaChip(context, category, icon: Icons.campaign_outlined),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                getS('description', '-'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        );

      case ModuleLayout.bookings:
        final status = getS('status', 'pending');
        return _sectionCard(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('কর্মী: ${getS('worker_name', '-')}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  _metaChip(context, status, icon: Icons.verified_outlined, color: _statusColor(context, status)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _metaChip(context, getS('service_date', '-'), icon: Icons.calendar_today_outlined),
                  _metaChip(context, getS('service_time', '-'), icon: Icons.access_time_outlined),
                ],
              ),
            ],
          ),
        );

      case ModuleLayout.categories:
        return _sectionCard(
          context: context,
          child: Row(
            children: [
              _thumb(context: context, imageUrl: imageUrl, width: 38, height: 38, radius: 11, fallbackIcon: Icons.category_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(getS('name', 'ক্যাটাগরি'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('ID: ${getS('id', '-')}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: scheme.onSurfaceVariant, size: 15),
            ],
          ),
        );

      case ModuleLayout.generic:
        final entries = item.entries.toList();
        return _sectionCard(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null) ...[
                _thumb(context: context, imageUrl: imageUrl, width: double.infinity, height: 140, radius: 12),
                const SizedBox(height: 10),
              ],
              ...entries.take(8).map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(text: '${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: '${e.value}'),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return Scaffold(
      appBar: ModernAppBar(title: widget.title, subtitle: 'তালিকা ও তথ্য'),
      floatingActionButton: widget.floatingActionButton,
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: _loading
            ? const SkeletonList()
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 40),
                      EmptyStateIllustration(
                        icon: Icons.cloud_off_rounded,
                        title: 'সংযোগ সমস্যা',
                        subtitle: _error!,
                      ),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () => _load(reset: true),
                          icon: const Icon(Icons.refresh),
                          label: const Text('আবার চেষ্টা করুন'),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    children: [
                      _searchSection(context),
                      if (widget.layout == ModuleLayout.business) _businessFilterSection(context),
                      if (widget.layout == ModuleLayout.marketplace) _marketplaceFilterSection(context),
                      _headerSection(context, filtered.length),
                      if (filtered.isEmpty)
                        const EmptyStateIllustration(
                          icon: Icons.inbox_rounded,
                          title: 'কোনো তথ্য নেই',
                          subtitle: 'এই সেকশনে এখনো কোনো কনটেন্ট পাওয়া যায়নি।',
                        ),
                      if (widget.layout == ModuleLayout.marketplace && filtered.isNotEmpty)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.62,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final child = item is Map<String, dynamic>
                                ? _renderMapItem(context, item)
                                : _sectionCard(context: context, child: Text(item.toString()));
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: Duration(milliseconds: 220 + (index * 25)),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, rendered) {
                                return Opacity(
                                  opacity: value.clamp(0, 1),
                                  child: Transform.translate(
                                    offset: Offset(0, 16 * (1 - value)),
                                    child: rendered,
                                  ),
                                );
                              },
                              child: child,
                            );
                          },
                        )
                      else
                        ...filtered.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final child = item is Map<String, dynamic>
                              ? _renderMapItem(context, item)
                              : _sectionCard(context: context, child: Text(item.toString()));

                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 220 + (index * 25)),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, rendered) {
                              return Opacity(
                                opacity: value.clamp(0, 1),
                                child: Transform.translate(
                                  offset: Offset(0, 16 * (1 - value)),
                                  child: rendered,
                                ),
                              );
                            },
                            child: child,
                          );
                        }),
                      if (_loadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (!_loadingMore && _hasMore)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextButton.icon(
                            onPressed: _loadMore,
                            icon: const Icon(Icons.expand_more_rounded),
                            label: const Text('আরো দেখুন'),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
