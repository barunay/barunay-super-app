import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/product_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/global_bottom_navigation.dart';
import './widgets/category_filter_chips_widget.dart';
import './widgets/featured_vendor_carousel_widget.dart';
import './widgets/marketplace_product_grid_widget.dart';
import './widgets/nearby_businesses_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/trending_products_grid_widget.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final SupabaseService _supabaseService = SupabaseService.instance;
  final ProductService _productService = ProductService();

  bool _isLoading = false;
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _featuredProducts = [];
  List<Map<String, dynamic>> _categories = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load data concurrently
      await Future.wait([
        _loadRecentConversations(),
        _loadFeaturedProducts(),
        _loadCategories(),
      ]);
    } catch (e) {
      debugPrint('Failed to load data: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadRecentConversations() async {
    try {
      final currentUserId = _supabaseService.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final response = await _supabaseService.client
          .from('marketplace_conversations')
          .select('''
            *,
            participant_one:user_profiles!marketplace_conversations_participant_one_id_fkey(
              id, full_name, avatar_url
            ),
            participant_two:user_profiles!marketplace_conversations_participant_two_id_fkey(
              id, full_name, avatar_url
            )
          ''')
          .or(
            'participant_one_id.eq.$currentUserId,participant_two_id.eq.$currentUserId',
          )
          .eq('is_archived', false)
          .order('last_message_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Failed to load conversations: ${e.toString()}');
    }
  }

  Future<void> _loadFeaturedProducts() async {
    try {
      final products = await _productService.getFeaturedProducts(limit: 10);
      if (mounted) {
        setState(() {
          _featuredProducts = products;
        });
      }
    } catch (e) {
      debugPrint('Failed to load featured products: ${e.toString()}');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _productService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      debugPrint('Failed to load categories: ${e.toString()}');
    }
  }

  void _onCategorySelected(String category) {
    if (mounted) {
      setState(() {
        _selectedCategory = category;
      });
    }
    HapticFeedback.lightImpact();
  }

  void _onSearch(String query) {
    HapticFeedback.lightImpact();
    // Navigate to search results
    Navigator.pushNamed(
      context,
      '/search-results',
      arguments: {'query': query, 'category': _selectedCategory},
    );
  }

  void _onProductTap(Map<String, dynamic> product) {
    if (product['id'] != null) {
      AppRoutes.navigateToProductDetail(context, product: product);
    }
  }

  void _showQuickActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 50.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 2.h),
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(1.w),
              ),
            ),

            SizedBox(height: 3.h),

            // Title
            Text(
              'Quick Actions',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 3.h),

            // Action Items
            Expanded(
              child: GridView(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                children: [
                  _buildActionCard(
                    'Post Product',
                    'Sell your items',
                    'add_box',
                    AppTheme.lightTheme.colorScheme.primary,
                    () {
                      Navigator.pop(context);
                      _navigateToPostItemScreen();
                    },
                  ),
                  _buildActionCard(
                    'Seller Dashboard',
                    'Manage inventory',
                    'store',
                    Colors.orange,
                    () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.sellerInventoryManagementScreen,
                      );
                    },
                  ),
                  _buildActionCard(
                    'Request Delivery',
                    'Get items delivered',
                    'local_shipping',
                    Colors.blue,
                    () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.enhancedDeliveryRequestScreen,
                      );
                    },
                  ),
                  _buildActionCard(
                    'Customer Support',
                    'Get help',
                    'support_agent',
                    Colors.green,
                    () {
                      Navigator.pop(context);
                      _showSupportOptions();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPostItemScreen() {
    Navigator.pushNamed(
      context,
      AppRoutes.postItemScreen,
    ).then((_) {
      // Refresh marketplace products when returning from post item screen
      _loadData();
    });
  }

  void _showPostProductSheet() {
    // Replaced with navigation to PostItemScreen
    _navigateToPostItemScreen();
  }

  void _showSupportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customer Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(iconName: 'phone'),
              title: Text('Call Support'),
              subtitle: Text('+673 8888-999'),
            ),
            ListTile(
              leading: CustomIconWidget(iconName: 'email'),
              title: Text('Email Support'),
              subtitle: Text('support@marketplace.com'),
            ),
            ListTile(
              leading: CustomIconWidget(iconName: 'chat'),
              title: Text('Live Chat'),
              subtitle: Text('Available 9 AM - 9 PM'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToChat() {
    if (_conversations.isEmpty) {
      // Show empty state or navigate to general chat landing
      Navigator.pushNamed(context, AppRoutes.chatLandingScreen);
      return;
    }

    // Navigate to most recent conversation
    final recentConversation = _conversations.first;
    final currentUserId = _supabaseService.client.auth.currentUser?.id;

    // Determine the other participant
    Map<String, dynamic>? participant;
    if (recentConversation['participant_one_id'] == currentUserId) {
      participant = recentConversation['participant_two'];
    } else {
      participant = recentConversation['participant_one'];
    }

    if (participant != null) {
      AppRoutes.navigateToChat(
        context,
        conversationId: recentConversation['id'],
        participant: participant,
        chatType: recentConversation['chat_type'],
      );
    }
  }

  void _onRefresh() async {
    HapticFeedback.lightImpact();
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _onRefresh(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar with Search
              SliverAppBar(
                floating: true,
                backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
                elevation: 0,
                toolbarHeight: 12.h,
                automaticallyImplyLeading: false,
                flexibleSpace: Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Marketplace',
                              style: AppTheme
                                  .lightTheme.textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            onPressed: _navigateToChat,
                            icon: Stack(
                              children: [
                                CustomIconWidget(
                                  iconName: 'chat',
                                  size: 6.w,
                                  color:
                                      AppTheme.lightTheme.colorScheme.onSurface,
                                ),
                                if (_unreadCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: EdgeInsets.all(0.5.w),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(
                                          2.w,
                                        ),
                                      ),
                                      constraints: BoxConstraints(
                                        minWidth: 4.w,
                                        minHeight: 4.w,
                                      ),
                                      child: Text(
                                        '$_unreadCount',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      SearchBarWidget(
                        currentLocation: 'Current Location',
                        onNotificationTap: () {},
                        notificationCount: 0,
                        onSearchChanged: (query) => _onSearch(query),
                      ),
                    ],
                  ),
                ),
              ),

              // Category Filter Chips
              SliverToBoxAdapter(
                child: CategoryFilterChipsWidget(
                  categories: [
                    'All',
                    'Electronics',
                    'Fashion',
                    'Home',
                    'Sports',
                  ],
                  selectedCategory: _selectedCategory,
                  onCategorySelected: _onCategorySelected,
                ),
              ),

              // Featured/Trending Products
              if (_featuredProducts.isNotEmpty)
                SliverToBoxAdapter(
                  child: TrendingProductsGridWidget(
                    trendingProducts: _featuredProducts,
                    onProductTap: _onProductTap,
                    onProductLongPress: (product) => _onProductTap(product),
                  ),
                ),

              // Main Products Grid
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Products',
                        style:
                            AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      MarketplaceProductGridWidget(
                        categoryId: _selectedCategory == 'All'
                            ? null
                            : _getCategoryId(),
                        limit: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Featured Vendors Carousel
              if (_featuredProducts.isNotEmpty)
                SliverToBoxAdapter(
                  child: FeaturedVendorCarouselWidget(
                    featuredVendors: [],
                    onVendorTap: (vendor) {},
                  ),
                ),

              // Nearby Businesses
              SliverToBoxAdapter(
                child: NearbyBusinessesWidget(
                  nearbyBusinesses: [],
                  onBusinessTap: (business) {},
                ),
              ),

              // Bottom padding for floating button
              SliverToBoxAdapter(child: SizedBox(height: 15.h)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const GlobalBottomNavigation(currentIndex: 0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickActionsSheet(context),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: CustomIconWidget(iconName: 'add', color: Colors.white, size: 5.w),
        label: Text(
          'Quick Actions',
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  String? _getCategoryId() {
    if (_selectedCategory == 'All' || _categories.isEmpty) return null;

    final category = _categories.firstWhere(
      (cat) =>
          cat['name'].toString().toLowerCase() ==
          _selectedCategory.toLowerCase(),
      orElse: () => {},
    );

    return category.isEmpty ? null : category['id'];
  }

  Widget _buildActionCard(
    String title,
    String description,
    String iconName,
    Color iconColor,
    VoidCallback onPressed,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(2.h),
          child: Row(
            children: [
              CustomIconWidget(iconName: iconName, color: iconColor, size: 5.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}