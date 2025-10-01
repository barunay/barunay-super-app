import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/product_service.dart';

class UserFavoritesScreen extends StatefulWidget {
  const UserFavoritesScreen({Key? key}) : super(key: key);

  @override
  State<UserFavoritesScreen> createState() => _UserFavoritesScreenState();
}

class _UserFavoritesScreenState extends State<UserFavoritesScreen> {
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'My Favorites',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (_favorites.isNotEmpty)
            TextButton(
              onPressed: _clearAllFavorites,
              child: Text(
                'Clear All',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _loadFavorites, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 12.w, color: Colors.red),
            SizedBox(height: 2.h),
            Text(
              'Failed to load favorites',
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
            ElevatedButton(onPressed: _loadFavorites, child: Text('Retry')),
          ],
        ),
      );
    }

    if (_favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 20.w,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 2.h),
            Text(
              'No favorites yet',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Items you like will appear here',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed:
                  () => Navigator.pushNamed(
                    context,
                    AppRoutes.marketplaceHomeScreen,
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
              ),
              child: Text('Browse Products'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(4.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 0.75,
      ),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final favorite = _favorites[index];
        final product = favorite['product'];
        if (product == null) return SizedBox.shrink();

        return _buildFavoriteCard(product, index);
      },
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> product, int index) {
    final images = product['images'] as List<dynamic>? ?? [];
    final primaryImage =
        images.isNotEmpty
            ? images.firstWhere(
              (img) => img['is_primary'] == true,
              orElse: () => images.first,
            )
            : null;

    return GestureDetector(
      onTap:
          () => Navigator.pushNamed(
            context,
            AppRoutes.productDetailScreen,
            arguments: product['id'],
          ).then((_) => _loadFavorites()),
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
                    top: 2.w,
                    right: 2.w,
                    child: GestureDetector(
                      onTap: () => _removeFavorite(product['id'], index),
                      child: Container(
                        width: 8.w,
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
                          Icons.favorite,
                          color: Colors.red,
                          size: 5.w,
                        ),
                      ),
                    ),
                  ),

                  // Status Badge
                  Positioned(
                    bottom: 2.w,
                    left: 2.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(product['status']),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        _formatStatus(product['status']),
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
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
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Title
                    Text(
                      product['title'] ?? 'Unknown Product',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 1.h),

                    // Price
                    Text(
                      'B\$${product['price']?.toString() ?? '0.00'}',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryLight,
                      ),
                    ),

                    Spacer(),

                    // Condition and Location
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.3.h,
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
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w500,
                              color: _getConditionColor(product['condition']),
                            ),
                          ),
                        ),

                        Expanded(
                          child: Text(
                            product['location_text'] ?? 'No location',
                            style: GoogleFonts.inter(
                              fontSize: 8.sp,
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

  Future<void> _removeFavorite(String productId, int index) async {
    // Optimistically remove from UI
    setState(() {
      _favorites.removeAt(index);
    });

    try {
      await _productService.toggleFavorite(productId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from favorites'),
          backgroundColor: Colors.grey,
          duration: Duration(milliseconds: 1500),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () => _undoRemove(productId),
          ),
        ),
      );
    } catch (e) {
      // Revert optimistic update on error
      _loadFavorites();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove favorite: $e')));
    }
  }

  Future<void> _undoRemove(String productId) async {
    try {
      await _productService.toggleFavorite(productId);
      _loadFavorites(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to restore favorite: $e')));
    }
  }

  Future<void> _clearAllFavorites() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Clear All Favorites'),
            content: Text(
              'Are you sure you want to remove all favorites? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Clear All'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // Remove all favorites
        final productIds =
            _favorites.map((fav) => fav['product']['id'] as String).toList();

        for (final productId in productIds) {
          await _productService.toggleFavorite(productId);
        }

        setState(() {
          _favorites.clear();
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('All favorites cleared')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear favorites: $e')),
        );
      }
    }
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
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
