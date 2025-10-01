import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/marketplace_service.dart';

class ProductListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final Function(Map<String, dynamic>) onProductTap;
  final VoidCallback? onProductDeleted;

  const ProductListWidget({
    Key? key,
    required this.products,
    required this.onProductTap,
    this.onProductDeleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(context, product);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: 'inventory_2',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 10.w,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'No Products Found',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          const Text('Products matching this filter will appear here'),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    final title = product['title'] ?? 'Unknown Product';
    final price = (product['price'] ?? 0.0).toDouble();
    final listingStatus = product['listing_status'] ?? 'pending';
    final status = product['status'] ?? 'active';
    final viewCount = product['view_count'] ?? 0;
    final favoriteCount = product['favorite_count'] ?? 0;
    final createdAt = product['created_at'] ?? '';

    // Get first image if available
    final images = product['product_images'] as List<dynamic>? ?? [];
    final imageUrl =
        images.isNotEmpty
            ? images.first['image_url']
            : 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=200';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => onProductTap(product),
        borderRadius: BorderRadius.circular(3.w),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(2.w),
                child: SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CustomImageWidget(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              SizedBox(width: 3.w),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTheme.lightTheme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        _buildStatusChip(listingStatus),
                      ],
                    ),

                    SizedBox(height: 1.h),

                    // Price
                    Text(
                      'B\$${price.toStringAsFixed(2)}',
                      style: AppTheme.lightTheme.textTheme.titleMedium
                          ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),

                    SizedBox(height: 1.h),

                    // Stats Row
                    Row(
                      children: [
                        const CustomIconWidget(
                          iconName: 'visibility',
                          size: 16,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '$viewCount',
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    AppTheme
                                        .lightTheme
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                        ),
                        SizedBox(width: 3.w),
                        const CustomIconWidget(
                          iconName: 'favorite_border',
                          size: 16,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '$favoriteCount',
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    AppTheme
                                        .lightTheme
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                        ),

                        const Spacer(),

                        Text(
                          _formatDate(createdAt),
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    AppTheme
                                        .lightTheme
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Menu
              PopupMenuButton<String>(
                icon: const CustomIconWidget(iconName: 'more_vert'),
                onSelected:
                    (value) => _handleMenuAction(context, value, product),
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            CustomIconWidget(iconName: 'edit', size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: status == 'active' ? 'deactivate' : 'activate',
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName:
                                  status == 'active' ? 'pause' : 'play_arrow',
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              status == 'active' ? 'Deactivate' : 'Activate',
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'content_copy',
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'delete',
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'approved':
        color = Colors.green;
        text = 'Live';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejected';
        break;
      case 'suspended':
        color = Colors.purple;
        text = 'Suspended';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(1.w),
      ),
      child: Text(
        text,
        style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 30) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    Map<String, dynamic> product,
  ) {
    switch (action) {
      case 'edit':
        onProductTap(product);
        break;
      case 'activate':
      case 'deactivate':
        _toggleProductStatus(context, product, action);
        break;
      case 'duplicate':
        _duplicateProduct(context, product);
        break;
      case 'delete':
        _deleteProduct(context, product);
        break;
    }
  }

  void _toggleProductStatus(
    BuildContext context,
    Map<String, dynamic> product,
    String action,
  ) {
    final newStatus = action == 'activate' ? 'active' : 'inactive';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              '${action == 'activate' ? 'Activate' : 'Deactivate'} Product',
            ),
            content: Text(
              'Are you sure you want to $action "${product['title']}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await MarketplaceService().updateProductListing(
                      productId: product['id'],
                      status: newStatus,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Product ${action}d successfully'),
                      ),
                    );
                    onProductDeleted?.call();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to $action product: $e')),
                    );
                  }
                },
                child: Text(action == 'activate' ? 'Activate' : 'Deactivate'),
              ),
            ],
          ),
    );
  }

  void _duplicateProduct(BuildContext context, Map<String, dynamic> product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Duplicate "${product['title']}" feature coming soon!'),
      ),
    );
  }

  void _deleteProduct(BuildContext context, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Product'),
            content: Text(
              'Are you sure you want to delete "${product['title']}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await MarketplaceService().deleteProductListing(
                      product['id'],
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product deleted successfully'),
                      ),
                    );
                    onProductDeleted?.call();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete product: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}