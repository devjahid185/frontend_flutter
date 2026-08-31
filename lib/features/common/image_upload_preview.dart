import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PickedImagePreviewGrid extends StatelessWidget {
  const PickedImagePreviewGrid({
    super.key,
    required this.images,
    this.onRemove,
    this.tileSize = 82,
  });

  final List<XFile> images;
  final void Function(int index)? onRemove;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(images.length, (index) {
        return PickedImagePreviewTile(
          image: images[index],
          indexLabel: '${index + 1}',
          size: tileSize,
          onRemove: onRemove == null ? null : () => onRemove!(index),
        );
      }),
    );
  }
}

class PickedImagePreviewTile extends StatelessWidget {
  const PickedImagePreviewTile({
    super.key,
    required this.image,
    this.indexLabel,
    this.size = 82,
    this.onRemove,
  });

  final XFile image;
  final String? indexLabel;
  final double size;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _PickedImageBytes(image: image),
              ),
            ),
          ),
          if (indexLabel != null)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  indexLabel!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          if (onRemove != null)
            Positioned(
              top: -8,
              right: -8,
              child: Material(
                color: scheme.surface,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 17,
                      color: scheme.error,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PickedImageHeroPreview extends StatelessWidget {
  const PickedImageHeroPreview({
    super.key,
    required this.image,
    this.height = 160,
    this.emptyTitle = 'ছবি আপলোড করুন',
    this.emptySubtitle = 'গ্যালারি বা ক্যামেরা থেকে ছবি বাছাই করুন',
    this.onTap,
    this.onRemove,
  });

  final XFile? image;
  final double height;
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: image == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: scheme.primary,
                      size: 34,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptyTitle,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      emptySubtitle,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _PickedImageBytes(image: image!),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        image!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (onRemove != null)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Material(
                        color: scheme.surface,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: onRemove,
                          icon: Icon(Icons.close_rounded, color: scheme.error),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _PickedImageBytes extends StatelessWidget {
  const _PickedImageBytes({required this.image});

  final XFile image;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<Uint8List>(
      future: image.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        if (snapshot.hasError) {
          return Center(
            child: Icon(Icons.broken_image_outlined, color: scheme.error),
          );
        }
        return Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.primary,
            ),
          ),
        );
      },
    );
  }
}
