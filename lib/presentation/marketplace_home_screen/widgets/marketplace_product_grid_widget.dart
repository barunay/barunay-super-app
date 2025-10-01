import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/product_service.dart';
import '../../../services/seller_service.dart';

class MarketplaceProductGridWidget extends StatefulWidget {
  final String? categoryId;
  final String? searchQuery;
  final int limit;

  const MarketplaceProductGridWidget({
    super.key,
    this.categoryId,
    this.searchQuery,
    this.limit = 20,
  });

  @override
  State<MarketplaceProductGridWidget> createState() =>
      _MarketplaceProductGridWidgetState();
}

class _MarketplaceProductGridWidgetState
    extends State<MarketplaceProductGridWidget> {
  final ProductService _productService = ProductService();
  final SellerService _sellerService = SellerService();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void didUpdateWidget(MarketplaceProductGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId ||
        oldWidget.searchQuery != widget.searchQuery) {
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Only show approved products in marketplace home
      final products = await _productService.getProducts(
        categoryId: widget.categoryId,
        searchQuery: widget.searchQuery,
        limit: widget.limit,
        orderBy: 'created_at',
        ascending: false,
      );

      // Additional filter to ensure only approved products are shown
      final approvedProducts =
          products
              .where(
                (product) =>
                    product['listing_status'] == 'approved' &&
                    product['status'] == 'active',
              )
              .toList();

      setState(() {
        _products = approvedProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(4.h),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(4.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 12.w, color: Colors.red),
              SizedBox(height: 2.h),
              Text(
                'Failed to load products',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                _error!,
                style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              ElevatedButton(onPressed: _loadProducts, child: Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(4.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 12.w, color: Colors.grey),
              SizedBox(height: 2.h),
              Text(
                widget.searchQuery?.isNotEmpty == true
                    ? 'No products found'
                    : 'No products available',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                widget.searchQuery?.isNotEmpty == true
                    ? 'Try adjusting your search terms'
                    : 'Check back later for new products',
                style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: GridView.builder(
        padding: EdgeInsets.all(2.w), // Reduced padding
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 2.w, // Reduced spacing
          mainAxisSpacing: 2.h, // Reduced spacing
          childAspectRatio: 0.75, // Slightly taller for better proportions
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final images = product['images'] as List<dynamic>? ?? [];
    final primaryImage =
        images.isNotEmpty
            ? images.firstWhere(
              (img) => img['is_primary'] == true,
              orElse: () => images.first,
            )
            : null;

    final favoriteCount = product['favorite_count'] ?? 0;
    final viewCount = product['view_count'] ?? 0;

    return GestureDetector(
      onTap:
          () => Navigator.pushNamed(
            context,
            AppRoutes.productDetailScreen,
            arguments: product['id'],
          ),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Favorite Button
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12.0),
                      ),
                      child: CustomImageWidget(
                        imageUrl:
                            primaryImage?['image_url'] ??
                            'https://images.unsplash.com/photo-1560472354-b33ff0c44a43',
                        fit: BoxFit.cover,
                        height: double.infinity,
                      ),
                    ),
                  ),

                  // Favorite Button with Heart Icon
                  Positioned(
                    top: 1.w,
                    right: 1.w,
                    child: _buildFavoriteButton(product),
                  ),

                  // Stats overlay
                  Positioned(
                    bottom: 1.w,
                    left: 1.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 1.5.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(153),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite, color: Colors.red, size: 3.w),
                          SizedBox(width: 0.5.w),
                          Text(
                            '$favoriteCount',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 1.w),
                          Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 3.w,
                          ),
                          SizedBox(width: 0.5.w),
                          Text(
                            '$viewCount',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product Details - More compact
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(2.w), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Title
                    Text(
                      product['title'] ?? 'Unknown Product',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp, // Reduced font size
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h), // Reduced spacing
                    // Price
                    Text(
                      'B\$${product['price']?.toString() ?? '0.00'}',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp, // Reduced font size
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryLight,
                      ),
                    ),

                    Spacer(),

                    // Condition and Location - Single line
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 1.5.w,
                            vertical: 0.2.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getConditionColor(
                              product['condition'],
                            ).withAlpha(26),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            _formatCondition(product['condition']),
                            style: GoogleFonts.inter(
                              fontSize: 8.sp, // Reduced font size
                              fontWeight: FontWeight.w500,
                              color: _getConditionColor(product['condition']),
                            ),
                          ),
                        ),

                        Expanded(
                          child: Text(
                            product['location_text'] ?? 'No location',
                            style: GoogleFonts.inter(
                              fontSize: 8.sp, // Reduced font size
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
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

  Widget _buildFavoriteButton(Map<String, dynamic> product) {
    return FutureBuilder<bool>(
      future: _productService.isProductFavorited(product['id']),
      builder: (context, snapshot) {
        final isFavorited = snapshot.data ?? false;

        return GestureDetector(
          onTap: () => _toggleFavorite(product['id']),
          child: Container(
            width: 8.w, // Compact size
            height: 8.w,
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
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: isFavorited ? Colors.red : Colors.grey.shade600,
              size: 5.w,
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleFavorite(String productId) async {
    try {
      await _productService.toggleFavorite(productId);
      // Refresh the widget to update favorite status
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update favorite: $e')));
    }
  }

  bool _hasMultipleImages(Map<String, dynamic> product) {
    if (product['product_images'] != null) {
      return (product['product_images'] as List).length > 1;
    }
    if (product['images'] != null) {
      return (product['images'] as List).length > 1;
    }
    return false;
  }

  int _getImageCount(Map<String, dynamic> product) {
    if (product['product_images'] != null) {
      return (product['product_images'] as List).length;
    }
    if (product['images'] != null) {
      return (product['images'] as List).length;
    }
    return 0;
  }

  String _getConditionText(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'new':
        return 'New';
      case 'like_new':
        return 'Like New';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor';
      default:
        return 'Used';
    }
  }

  Color _getConditionColor(String? condition) {
    switch (condition) {
      case 'new':
        return Colors.green;
      case 'like_new':
        return Colors.blue;
      case 'good':
        return Colors.orange;
      case 'fair':
        return Colors.yellow.shade700;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatCondition(String? condition) {
    switch (condition) {
      case 'like_new':
        return 'Like New';
      case 'new':
      case 'good':
      case 'fair':
      case 'poor':
        return condition?.capitalize() ?? 'Unknown';
      default:
        return 'Unknown';
    }
  }

  String _getProductImageUrl(Map<String, dynamic> product) {
    // Handle both product_images relationship and direct images
    if (product['product_images'] != null) {
      final images = product['product_images'] as List<dynamic>;
      if (images.isNotEmpty) {
        // Find primary image first
        final primaryImage = images.firstWhere(
          (img) => img['is_primary'] == true,
          orElse: () => images.first,
        );
        return primaryImage['image_url'] ?? '';
      }
    }

    // Fallback to direct images field
    if (product['images'] != null) {
      final images = product['images'] as List<dynamic>;
      if (images.isNotEmpty) {
        final primaryImage = images.firstWhere(
          (img) => img['is_primary'] == true,
          orElse: () => images.first,
        );
        return primaryImage['image_url'] ?? '';
      }
    }

    return 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=800&h=600&fit=crop';
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
