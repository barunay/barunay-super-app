import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/product_service.dart';

class FavoritesSectionWidget extends StatefulWidget {
  const FavoritesSectionWidget({Key? key}) : super(key: key);

  @override
  State<FavoritesSectionWidget> createState() => _FavoritesSectionWidgetState();
}

class _FavoritesSectionWidgetState extends State<FavoritesSectionWidget> {
  final ProductService _productService = ProductService();
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final favorites = await _productService.getUserFavorites();
      setState(() {
        _favorites = favorites;
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
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
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
                  'My Favorites',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (_favorites.isNotEmpty)
                  TextButton(
                    onPressed: () => _showAllFavorites(),
                    child: Text(
                      'See All (${_favorites.length})',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: 1.h),

          // Content
          if (_isLoading)
            Container(
              height: 15.h,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Container(
              height: 15.h,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 8.w),
                    SizedBox(height: 1.h),
                    Text(
                      'Failed to load favorites',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    TextButton(onPressed: _loadFavorites, child: Text('Retry')),
                  ],
                ),
              ),
            )
          else if (_favorites.isEmpty)
            Container(
              height: 15.h,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      size: 10.w,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'No favorites yet',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Items you like will appear here',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 20.h, // Fixed height to prevent overflow
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: _favorites.take(5).length, // Show max 5 items
                itemBuilder: (context, index) {
                  final favorite = _favorites[index];
                  final product = favorite['product'];
                  if (product == null) return SizedBox.shrink();

                  return _buildFavoriteCard(product);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> product) {
    final images = product['images'] as List<dynamic>? ?? [];
    final primaryImage =
        images.isNotEmpty
            ? images.firstWhere(
              (img) => img['is_primary'] == true,
              orElse: () => images.first,
            )
            : null;

    return Container(
      width: 35.w,
      margin: EdgeInsets.only(right: 3.w),
      child: GestureDetector(
        onTap:
            () => Navigator.pushNamed(
              context,
              AppRoutes.productDetailScreen,
              arguments: product['id'],
            ).then((_) => _loadFavorites()), // Refresh when coming back
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
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

                    // Remove Favorite Button
                    Positioned(
                      top: 1.w,
                      right: 1.w,
                      child: GestureDetector(
                        onTap: () => _removeFavorite(product['id']),
                        child: Container(
                          width: 7.w,
                          height: 7.w,
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
                            Icons.favorite,
                            color: Colors.red,
                            size: 4.w,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Product Details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(2.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Title
                      Text(
                        product['title'] ?? 'Unknown Product',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      Spacer(),

                      // Price
                      Text(
                        'B\$${product['price']?.toString() ?? '0.00'}',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryLight,
                        ),
                      ),

                      // Status
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 1.5.w,
                          vertical: 0.2.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            product['status'],
                          ).withAlpha(26),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          _formatStatus(product['status']),
                          style: GoogleFonts.inter(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(product['status']),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeFavorite(String productId) async {
    try {
      await _productService.toggleFavorite(productId);
      _loadFavorites(); // Refresh the list

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from favorites'),
          backgroundColor: Colors.grey,
          duration: Duration(milliseconds: 1500),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove favorite: $e')));
    }
  }

  void _showAllFavorites() {
    Navigator.pushNamed(context, AppRoutes.userFavoritesScreen);
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'sold':
        return Colors.orange;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String? status) {
    switch (status) {
      case 'active':
        return 'Available';
      case 'sold':
        return 'Sold';
      case 'inactive':
        return 'Inactive';
      default:
        return 'Unknown';
    }
  }
}
