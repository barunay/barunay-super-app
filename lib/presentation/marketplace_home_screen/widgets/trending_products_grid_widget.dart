import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/product_service.dart';

class TrendingProductsGridWidget extends StatefulWidget {
  final List<Map<String, dynamic>>? trendingProducts;
  final Function(Map<String, dynamic>)? onProductTap;
  final Function(Map<String, dynamic>)? onProductLongPress;

  const TrendingProductsGridWidget({
    Key? key,
    this.trendingProducts,
    this.onProductTap,
    this.onProductLongPress,
  }) : super(key: key);

  @override
  State<TrendingProductsGridWidget> createState() =>
      _TrendingProductsGridWidgetState();
}

class _TrendingProductsGridWidgetState
    extends State<TrendingProductsGridWidget> {
  final ProductService _productService = ProductService();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.trendingProducts != null &&
        widget.trendingProducts!.isNotEmpty) {
      _products = widget.trendingProducts!;
      _isLoading = false;
    } else {
      _loadTrendingProducts();
    }
  }

  Future<void> _loadTrendingProducts() async {
    try {
      setState(() => _isLoading = true);

      // Load featured products as trending products
      final products = await _productService.getFeaturedProducts(limit: 6);

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      debugPrint('Failed to load trending products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty && _isLoading) {
      return _buildLoadingState();
    }

    if (_error != null && _products.isEmpty) {
      return _buildErrorState();
    }

    if (_products.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trending Products',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to see all trending products
                    Navigator.pushNamed(context, '/products', arguments: {
                      'filter': 'trending',
                      'title': 'Trending Products'
                    });
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // Products Grid
          Container(
            height: 52.h, // Fixed height for the grid
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              scrollDirection: Axis.horizontal,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 2.w,
                mainAxisSpacing: 3.w,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return _buildProductCard(product);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final primaryImage = _getPrimaryImage(product);
    final title = product['title']?.toString() ?? 'Product';
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final originalPrice = (product['original_price'] as num?)?.toDouble();
    final condition = product['condition']?.toString() ?? 'good';
    final seller = product['seller'] as Map<String, dynamic>?;
    final sellerProfile = product['seller_profile'] as Map<String, dynamic>?;
    final isVerified = sellerProfile?['is_verified'] == true;

    return GestureDetector(
      onTap: () => widget.onProductTap?.call(product),
      onLongPress: () => widget.onProductLongPress?.call(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(3.w),
                  ),
                ),
                child: Stack(
                  children: [
                    // Main Image
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(3.w),
                      ),
                      child: primaryImage.isNotEmpty
                          ? CustomImageWidget(
                              imageUrl: primaryImage,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.image_not_supported,
                                size: 12.w,
                                color: Colors.grey[400],
                              ),
                            ),
                    ),

                    // Condition Badge
                    Positioned(
                      top: 2.w,
                      left: 2.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 1.w,
                        ),
                        decoration: BoxDecoration(
                          color: _getConditionColor(condition),
                          borderRadius: BorderRadius.circular(1.w),
                        ),
                        child: Text(
                          condition.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // Favorite Button
                    Positioned(
                      top: 2.w,
                      right: 2.w,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_outline,
                          size: 4.w,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 1.w),

                    // Price
                    Row(
                      children: [
                        Text(
                          'BND \$${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightTheme.colorScheme.primary,
                          ),
                        ),
                        if (originalPrice != null && originalPrice > price) ...[
                          SizedBox(width: 2.w),
                          Text(
                            'BND \$${originalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 9.sp,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),

                    Spacer(),

                    // Seller Info
                    Row(
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 3.w,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 1.w),
                        Expanded(
                          child: Text(
                            sellerProfile?['business_name'] ??
                                seller?['full_name'] ??
                                'Seller',
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          SizedBox(width: 1.w),
                          Icon(
                            Icons.verified,
                            size: 3.w,
                            color: Colors.blue,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPrimaryImage(Map<String, dynamic> product) {
    final images = product['images'] as List<dynamic>? ?? [];
    if (images.isEmpty) return '';

    // Find primary image
    final primaryImage = images.firstWhere(
      (img) => img['is_primary'] == true,
      orElse: () => null,
    );

    if (primaryImage != null) {
      return primaryImage['image_url'] ?? '';
    }

    // If no primary image, get the first one
    return images.isNotEmpty ? images.first['image_url'] ?? '' : '';
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'like_new':
        return Colors.blue;
      case 'good':
        return Colors.orange;
      case 'fair':
        return Colors.amber;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildLoadingState() {
    return Container(
      height: 52.h,
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Placeholder
          Container(
            width: 40.w,
            height: 6.h,
            color: Colors.grey[300],
          ),

          SizedBox(height: 2.h),

          // Grid Loading Placeholder
          Expanded(
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 2.w,
                mainAxisSpacing: 3.w,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(3.w),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(3.w),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 3.h,
                                color: Colors.grey[300],
                              ),
                              SizedBox(height: 1.w),
                              Container(
                                width: 20.w,
                                height: 2.h,
                                color: Colors.grey[300],
                              ),
                              Spacer(),
                              Container(
                                width: 15.w,
                                height: 2.h,
                                color: Colors.grey[300],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 20.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 12.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 2.h),
          Text(
            'Failed to load trending products',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          ElevatedButton(
            onPressed: _loadTrendingProducts,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            ),
            child: Text(
              'Retry',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}