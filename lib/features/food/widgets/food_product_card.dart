import 'package:flutter/material.dart';

class FoodProductCard extends StatelessWidget {
  const FoodProductCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onRestaurantTap,
    required this.onAdd,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback? onRestaurantTap;
  final ValueChanged<BuildContext> onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final restaurant = item['restaurant'] is Map
        ? Map<String, dynamic>.from(item['restaurant'] as Map)
        : <String, dynamic>{};
    final price = item['discount_price'] ?? item['price'];
    final oldPrice = item['discount_price'] == null ? null : item['price'];
    final isPromoted = _isTruthy(item['is_promoted']);
    final isPopular = _isTruthy(item['is_popular']);
    final badgeLabel = isPromoted ? 'Promoted' : (isPopular ? 'জনপ্রিয়' : null);
    final badgeIcon = isPromoted
        ? Icons.campaign_rounded
        : Icons.local_fire_department_rounded;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFFFD7C2).withValues(alpha: 0.76),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF39150D).withValues(alpha: 0.045),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _FoodCardImage(
                    url: item['image_url']?.toString(),
                    height: 126,
                    width: double.infinity,
                  ),
                  if (badgeLabel != null)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              badgeIcon,
                              size: 13,
                              color: const Color(0xFFB91C1C),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              badgeLabel,
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name']?.toString() ?? 'খাবার',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF23130F),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    InkWell(
                      onTap: onRestaurantTap,
                      borderRadius: BorderRadius.circular(999),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            color: Color(0xFFB91C1C),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              restaurant['name']?.toString() ?? 'রেস্টুরেন্ট',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '৳$price',
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (oldPrice != null) ...[
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '৳$oldPrice',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Builder(
                          builder: (buttonContext) => Material(
                            color: const Color(0xFFB91C1C),
                            borderRadius: BorderRadius.circular(11),
                            child: InkWell(
                              onTap: () => onAdd(buttonContext),
                              borderRadius: BorderRadius.circular(11),
                              child: const SizedBox(
                                width: 31,
                                height: 31,
                                child: Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isTruthy(dynamic value) {
  if (value == true || value == 1) return true;
  final text = value?.toString().toLowerCase().trim();
  return text == '1' || text == 'true' || text == 'yes';
}

class _FoodCardImage extends StatelessWidget {
  const _FoodCardImage({
    required this.url,
    required this.width,
    required this.height,
  });

  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: const Color(0xFFFFF2EA),
      child: const Icon(Icons.restaurant_menu_rounded, size: 34),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return Image.network(
      url!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
