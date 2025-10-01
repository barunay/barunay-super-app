import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/marketplace_service.dart';
import '../../services/product_service.dart';
import './widgets/customer_reviews_section.dart';
import './widgets/product_context_card.dart';
import './widgets/product_image_carousel.dart';
import './widgets/related_products_carousel.dart';
import './widgets/sticky_bottom_bar.dart';
import './widgets/vendor_info_card.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({Key? key}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  final MarketplaceService _marketplaceService = MarketplaceService();

  Map<String, dynamic>? product;
  List<Map<String, dynamic>> relatedProducts = [];
  bool isLoading = true;
  bool isFavorited = false;
  String? error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final productId = ModalRoute.of(context)!.settings.arguments as String?;
    if (productId != null) {
      _loadProductDetails(productId);
    }
  }

  Future<void> _loadProductDetails(String productId) async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final [productData, favoriteStatus, relatedData] = await Future.wait([
        _productService.getProductById(productId),
        _productService.isProductFavorited(productId),
        _productService.getRelatedProducts(productId),
      ]);

      setState(() {
        product = productData as Map<String, dynamic>?;
        isFavorited = favoriteStatus as bool;
        relatedProducts = relatedData as List<Map<String, dynamic>>;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null || product == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 12.w, color: Colors.red),
              SizedBox(height: 2.h),
              Text('Failed to load product'),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final images = product!['images'] as List<dynamic>? ?? [];
    final favoriteCount = product!['favorite_count'] ?? 0;
    final viewCount = product!['view_count'] ?? 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Favorite Button
          SliverAppBar(
            expandedHeight: 40.h, // Constrained height to prevent overflow
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            actions: [
              // Favorite Toggle Button
              IconButton(
                onPressed: _toggleFavorite,
                icon: AnimatedSwitcher(
                  duration: Duration(milliseconds: 200),
                  child: Icon(
                    isFavorited ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(isFavorited),
                    color: isFavorited ? Colors.red : Colors.grey.shade600,
                    size: 6.w,
                  ),
                ),
              ),

              // Share Button
              IconButton(
                onPressed: () => _shareProduct(),
                icon: Icon(Icons.share, size: 6.w),
              ),

              SizedBox(width: 2.w),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                constraints: BoxConstraints(
                  maxHeight: 40.h,
                ), // Prevent overflow
                child: ProductImageCarousel(
                  imageUrls: images.map((img) => img['image_url'] as String).toList(),
                  heroTag: product!['id'].toString(),
                ),
              ),
            ),
          ),

          // Product Content
          SliverToBoxAdapter(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 100.w,
              ), // Prevent horizontal overflow
              child: Padding(
                padding: EdgeInsets.all(4.w), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Header - Compact
                    _buildProductHeader(),
                    SizedBox(height: 1.h), // Reduced spacing
                    // Stats Row - Compact
                    _buildStatsRow(favoriteCount, viewCount),
                    SizedBox(height: 2.h), // Reduced spacing
                    // Price Section - Compact
                    _buildPriceSection(),
                    SizedBox(height: 2.h), // Reduced spacing
                    // Product Info - Constrained
                    Container(
                      width: double.infinity,
                      child: ProductContextCard(
                        product: product!,
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Seller Info - Constrained
                    Container(
                      width: double.infinity,
                      child: VendorInfoCard(
                        product: product!,
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Reviews - Constrained
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxHeight: 30.h,
                      ), // Prevent overflow
                      child: CustomerReviewsSection(
                        reviews: List<Map<String, dynamic>>.from(
                          product!['reviews'] ?? [],
                        ),
                        averageRating: (product!['average_rating'] as num?)?.toDouble() ?? 0.0,
                        ratingDistribution: {},
                        onWriteReview: () {},
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Related Products - Constrained
                    if (relatedProducts.isNotEmpty)
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxHeight: 25.h,
                        ), // Prevent overflow
                        child: RelatedProductsCarousel(
                          relatedProducts: relatedProducts,
                          onProductTap: (product) {
                            Navigator.pushNamed(
                              context,
                              '/product-detail',
                              arguments: product['id'],
                            );
                          },
                        ),
                      ),

                    // Bottom spacing for sticky bar
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Sticky Bottom Bar - Constrained
      bottomNavigationBar: Container(
        constraints: BoxConstraints(maxHeight: 8.h), // Prevent overflow
        child: StickyBottomBar(
          isInStock: true,
          hasQuantitySelector: false,
          currentQuantity: 1,
          maxQuantity: 10,
          onChatWithSeller: _handleContact,
          onContactSeller: _handleContact,
          onQuantityChanged: (quantity) {},
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title - constrained to prevent overflow
        Container(
          width: double.infinity,
          child: Text(
            product!['title'] ?? 'Unknown Product',
            style: GoogleFonts.inter(
              fontSize: 18.sp, // Reduced font size
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            maxLines: 3, // Limit lines to prevent overflow
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: 1.h),

        // Category and Brand Row
        Row(
          children: [
            if (product!['category'] != null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withAlpha(26),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  product!['category']['name'] ?? 'Unknown Category',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp, // Reduced font size
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
            ],

            if (product!['brand'] != null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(26),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  product!['brand']['name'] ?? 'Unknown Brand',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp, // Reduced font size
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(int favoriteCount, int viewCount) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 3.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.favorite, favoriteCount, 'Likes', Colors.red),
          Container(height: 3.h, width: 1, color: Colors.grey.shade300),
          _buildStatItem(Icons.visibility, viewCount, 'Views', Colors.blue),
          Container(height: 3.h, width: 1, color: Colors.grey.shade300),
          _buildStatItem(
            Icons.access_time,
            _getDaysAgo(product!['created_at']),
            'Days ago',
            Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int value, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 4.w),
            SizedBox(width: 1.w),
            Text(
              value.toString(),
              style: GoogleFonts.inter(
                fontSize: 12.sp, // Reduced font size
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp, // Reduced font size
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    final price = product!['price']?.toString() ?? '0.00';
    final originalPrice = product!['original_price']?.toString();
    final isNegotiable = product!['is_negotiable'] ?? false;

    return Container(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Current Price
          Expanded(
            child: Text(
              'B\$ $price',
              style: GoogleFonts.inter(
                fontSize: 20.sp, // Reduced font size
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Original Price and Negotiable
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (originalPrice != null && originalPrice != price) ...[
                Text(
                  'B\$ $originalPrice',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp, // Reduced font size
                    color: Colors.grey.shade600,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                SizedBox(height: 0.5.h),
              ],

              if (isNegotiable)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(26),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    'Negotiable',
                    style: GoogleFonts.inter(
                      fontSize: 9.sp, // Reduced font size
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    try {
      final newStatus = await _productService.toggleFavorite(product!['id']);
      setState(() {
        isFavorited = newStatus;
        // Update favorite count in real-time
        product!['favorite_count'] =
            (product!['favorite_count'] ?? 0) + (newStatus ? 1 : -1);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus ? 'Added to favorites' : 'Removed from favorites',
          ),
          backgroundColor: newStatus ? Colors.green : Colors.grey,
          duration: Duration(milliseconds: 1500),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update favorite: $e')));
    }
  }

  void _shareProduct() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share functionality will be implemented')),
    );
  }

  Future<void> _handleContact() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to contact seller')),
      );
      return;
    }

    try {
      final conversationId = await _marketplaceService.startConversation(
        productId: product!['id'],
        sellerId: product!['seller_id'],
        buyerId: user.id,
      );

      Navigator.pushNamed(
        context,
        AppRoutes.chatScreen,
        arguments: conversationId,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start conversation: $e')),
      );
    }
  }

  void _handleBuyNow() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Buy now functionality will be implemented')),
    );
  }

  int _getDaysAgo(String? createdAt) {
    if (createdAt == null) return 0;
    try {
      final created = DateTime.parse(createdAt);
      final now = DateTime.now();
      return now.difference(created).inDays;
    } catch (e) {
      return 0;
    }
  }
}