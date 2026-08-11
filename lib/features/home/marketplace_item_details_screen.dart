import 'package:frontend_flutter/core/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../common/modern_app_bar.dart';
import 'seller_profile_screen.dart';
import 'chat_screen.dart';

class MarketplaceItemDetailsScreen extends StatefulWidget {
  const MarketplaceItemDetailsScreen({super.key, required this.itemId});

  final int itemId;

  @override
  State<MarketplaceItemDetailsScreen> createState() =>
      _MarketplaceItemDetailsScreenState();
}

class _MarketplaceItemDetailsScreenState
    extends State<MarketplaceItemDetailsScreen> {
  late final ApiClient _api = ApiClient(getToken: SessionStorage().getToken);

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _item;
  int _galleryIndex = 0;

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
      final res = await _api.get('/items/${widget.itemId}');
      if (res is Map<String, dynamic>) {
        _item = res;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'ডেটা লোড করা যায়নি';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _normalizeImageUrl(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty || value == '-') return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      try {
        final uri = Uri.parse(value);
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          final apiUri = Uri.parse(AppConfig.apiBaseUrl);
          final origin =
              '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
          return '$origin${uri.path}';
        }
      } catch (_) {}
      return value;
    }

    final apiUri = Uri.parse(AppConfig.apiBaseUrl);
    final origin =
        '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
    if (value.startsWith('/')) return '$origin$value';

    return '$origin/storage/$value';
  }

  Future<void> _showPhoneDialog(String phone) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: scheme.surface,
          title: Text(
            'ফোন নম্বর',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              phone,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'বন্ধ করুন',
                style: TextStyle(color: scheme.onSurface),
              ),
            ),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: phone));
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('কপি করা হয়েছে')),
                  );
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

  Future<void> _callSeller(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _reportItem() async {
    final controller = TextEditingController();
    final scheme = Theme.of(context).colorScheme;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('রিপোর্ট করুন'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'সমস্যা লিখুন'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('বাতিল'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('জমা দিন'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    final reason = controller.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('কারণ লিখুন')));
      return;
    }

    try {
      await _api.post(
        '/items/report',
        body: {'item_id': widget.itemId, 'reason': reason},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('রিপোর্ট জমা হয়েছে')));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('রিপোর্ট জমা হয়নি')));
      }
    }
  }

  void _openGallery(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    if (images.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) {
          return _GalleryViewer(
            images: images,
            initialIndex: initialIndex.clamp(0, images.length - 1),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const ModernAppBar(
        title: 'আইটেম ডিটেইলস',
        subtitle: 'বিক্রির তথ্য',
      ),
      body: _loading
          ? const Center(child: LogoLoader(showLabel: true))
          : _error != null
          ? Center(child: Text(_error!))
          : _item == null
          ? const Center(child: Text('তথ্য পাওয়া যায়নি'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildGallery(context, scheme),
                const SizedBox(height: 12),
                _buildSummary(context, scheme),
                const SizedBox(height: 12),
                _buildSeller(context, scheme),
                const SizedBox(height: 12),
                _buildDescription(context, scheme),
                const SizedBox(height: 12),
                _buildActions(context, scheme),
              ],
            ),
    );
  }

  Widget _buildGallery(BuildContext context, ColorScheme scheme) {
    final images = (_item?['images'] as List?)?.cast<String>() ?? [];
    final imageUrl = _normalizeImageUrl(_item?['image_url']?.toString());
    final allImages = [
      if (imageUrl != null) imageUrl,
      ...images.map(_normalizeImageUrl).whereType<String>(),
    ].toSet().toList();

    if (allImages.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Center(
          child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
        ),
      );
    }

    final controller = PageController(
      initialPage: _galleryIndex.clamp(0, allImages.length - 1),
    );

    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _openGallery(context, allImages, _galleryIndex),
            child: PageView.builder(
              controller: controller,
              itemCount: allImages.length,
              onPageChanged: (index) => setState(() => _galleryIndex = index),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(allImages[index], fit: BoxFit.cover),
                );
              },
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(allImages.length, (index) {
                final active = index == _galleryIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: active ? 18 : 6,
                  decoration: BoxDecoration(
                    color: active
                        ? scheme.onSurface
                        : scheme.onSurface.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, ColorScheme scheme) {
    String getS(String key, [String fallback = '-']) =>
        (_item?[key]?.toString().trim().isNotEmpty ?? false)
        ? _item![key].toString()
        : fallback;

    final title = getS('title', 'আইটেম');
    final price = getS('price', '0');
    final condition = getS('condition', '-');
    final location = getS('location', '-');
    final brand = getS('brand', '-');
    final model = getS('model', '-');
    final negotiable =
        (_item?['negotiable'] == true || _item?['negotiable'] == 1)
        ? 'হ্যাঁ'
        : 'না';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '৳ $price',
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(context, condition == 'new' ? 'নতুন' : 'ব্যবহৃত'),
              _chip(context, location),
              if (brand != '-') _chip(context, 'ব্র্যান্ড: $brand'),
              if (model != '-') _chip(context, 'মডেল: $model'),
              _chip(context, 'দাম আলোচনা: $negotiable'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeller(BuildContext context, ColorScheme scheme) {
    final sellerId = (_item?['seller_id'] as num?)?.toInt() ?? 0;
    final sellerName = _item?['seller_name']?.toString() ?? '-';
    final sellerPhone = _item?['seller_phone']?.toString() ?? '';
    final district = _item?['seller_district']?.toString() ?? '';
    final upazila = _item?['seller_upazila']?.toString() ?? '';
    final isOwner = _item?['is_owner'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: scheme.primary.withValues(alpha: 0.12),
            child: Text(
              sellerName.isNotEmpty ? sellerName.characters.first : 'S',
              style: TextStyle(color: scheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sellerName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  [district, upazila].where((e) => e.isNotEmpty).join(', '),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              if (sellerId > 0)
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SellerProfileScreen(sellerId: sellerId),
                    ),
                  ),
                  child: const Text('প্রোফাইল'),
                ),
              if (!isOwner && sellerPhone.isNotEmpty)
                IconButton(
                  onPressed: () => _callSeller(sellerPhone),
                  icon: Icon(Icons.call_outlined, color: scheme.primary),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context, ColorScheme scheme) {
    final desc = _item?['description']?.toString() ?? 'বিবরণ নেই';
    final delivery = _item?['delivery']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'বিস্তারিত',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(desc),
          if (delivery.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'ডেলিভারি/হ্যান্ডওভার',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(delivery),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ColorScheme scheme) {
    final sellerId = (_item?['seller_id'] as num?)?.toInt() ?? 0;
    final sellerName = _item?['seller_name']?.toString() ?? 'Seller';
    final sellerPhone = _item?['seller_phone']?.toString() ?? '';
    final isOwner = _item?['is_owner'] == true;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: sellerPhone.isNotEmpty
                    ? () => _showPhoneDialog(sellerPhone)
                    : null,
                icon: const Icon(Icons.call),
                label: const Text('ফোন দেখুন'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isOwner || sellerId <= 0
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            receiverId: sellerId,
                            receiverName: sellerName,
                          ),
                        ),
                      ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('মেসেজ'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: isOwner ? null : _reportItem,
          icon: const Icon(Icons.flag_outlined),
          label: const Text('রিপোর্ট করুন'),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GalleryViewer extends StatefulWidget {
  const _GalleryViewer({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 3.5,
                  child: Center(
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: active ? 18 : 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
