import 'package:flutter/material.dart';

class ProductPreviewWidget extends StatelessWidget {
  final String title;
  final String description;
  final double price;
  final double? originalPrice;
  final String condition;
  final String location;
  final bool isNegotiable;
  final List<String> tags;
  final List<String> imageUrls;
  final String category;

  const ProductPreviewWidget({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.condition,
    required this.location,
    required this.isNegotiable,
    required this.tags,
    required this.imageUrls,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images
            if (imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade200),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Title
            Text(
              title.isEmpty ? 'Untitled Product' : title,
              style:
                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // Price row
            Row(
              children: [
                Text('\$${price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium),
                const SizedBox(width: 8),
                if (originalPrice != null)
                  Text(
                    '\$${originalPrice!.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                const Spacer(),
                // Condition chip
                Chip(
                  label: Text(condition),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Category / Negotiable
            Row(
              children: [
                Text(
                  category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isNegotiable) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.handshake_outlined, size: 16),
                  const SizedBox(width: 2),
                  Text('Negotiable', style: theme.textTheme.bodySmall),
                ],
              ],
            ),

            const SizedBox(height: 6),

            // Description (clamped)
            Text(
              description.isEmpty ? 'No description provided.' : description,
              style: theme.textTheme.bodyMedium,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // Location
            if (location.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),

            // Tags (wrap, compact)
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: -4,
                children: tags
                    .take(8)
                    .map(
                      (t) => Chip(
                        label: Text(t),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
