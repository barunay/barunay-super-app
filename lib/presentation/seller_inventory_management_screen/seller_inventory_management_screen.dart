import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/seller_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/global_bottom_navigation.dart';
import '../../widgets/seller_verification_badge_widget.dart';
import './widgets/analytics_dashboard_widget.dart';
import './widgets/filter_chips_widget.dart';
import './widgets/product_card_widget.dart';
import './widgets/seller_profile_deletion_dialog.dart';

class SellerInventoryManagementScreen extends StatefulWidget {
  const SellerInventoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<SellerInventoryManagementScreen> createState() =>
      _SellerInventoryManagementScreenState();
}

class _SellerInventoryManagementScreenState
    extends State<SellerInventoryManagementScreen>
    with TickerProviderStateMixin {
  final SellerService _sellerService = SellerService();
  final SupabaseService _supabaseService = SupabaseService.instance;

  late final TabController _tabController;

  // State
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic> _analytics = {};
  String _selectedFilter = 'all';
  String _searchQuery = '';

  // Controllers
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Dart 3 pattern destructuring works; keep if you're on Dart 3.
      final [products, analytics, sellerProfile] = await Future.wait([
        _sellerService.getSellerProducts(),
        _sellerService.getSellerAnalytics(),
        _sellerService.getSellerProfile(),
      ]);

      setState(() {
        _products = (products as List).cast<Map<String, dynamic>>();
        _analytics = (analytics as Map).cast<String, dynamic>();
        _analytics['seller_profile'] = sellerProfile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  Future<void> _refreshData() => _loadData();

  void _showDeleteSellerProfileDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SellerProfileDeletionDialog(),
    ).then((result) {
      if (result == true) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.marketplaceHomeScreen,
          (route) => false,
        );
      }
    });
  }

  // ------- FILTERED PRODUCTS -------
  List<Map<String, dynamic>> get _filteredProducts {
    var filtered = _products;

    if (_selectedFilter != 'all') {
      filtered = filtered.where((product) {
        switch (_selectedFilter) {
          case 'draft':
            return product['status'] == 'inactive' ||
                product['listing_status'] == 'draft';
          case 'under_review':
            return product['listing_status'] == 'under_review';
          case 'active':
            return product['status'] == 'active' &&
                product['listing_status'] == 'approved';
          case 'rejected':
            return product['listing_status'] == 'rejected';
          case 'sold':
            return product['status'] == 'sold';
          default:
            return true;
        }
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((p) =>
              (p['title'] ?? '').toString().toLowerCase().contains(q) ||
              (p['description'] ?? '').toString().toLowerCase().contains(q))
          .toList();
    }
    return filtered;
  }

  // ------- UI -------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.postItemScreen),
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      bottomNavigationBar: GlobalBottomNavigation(currentIndex: 1),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          edgeOffset: 8,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildStoreHeader(),
              _buildSearchAndFiltersSticky(),
              _buildTabBar(),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // PRODUCTS TAB
                _isLoading
                    ? const _LoadingListSkeleton()
                    : _buildProductsList(),
                // ANALYTICS TAB
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Sliver: Fancy Header with banner + avatar + verification + actions
  SliverAppBar _buildStoreHeader() {
    final profile = _analytics['seller_profile'] as Map<String, dynamic>?;

    final bannerUrl =
        profile?['shop_settings']?['shop_banner'] as String?; // nullable
    final logoUrl = profile?['shop_settings']?['shop_logo'] as String? ??
        'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d';

    return SliverAppBar(
      expandedHeight: 26.h,
      elevation: 0,
      pinned: true,
      backgroundColor: AppTheme.primaryLight,
      titleTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 12.sp,
      ),
      title: innerTitle(profile),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner
            if (bannerUrl != null)
              Opacity(
                opacity: 0.9,
                child:
                    CustomImageWidget(imageUrl: bannerUrl, fit: BoxFit.cover),
              )
            else
              Container(color: AppTheme.primaryLight),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryLight.withAlpha(77),
                    AppTheme.primaryLight.withAlpha(235),
                  ],
                ),
              ),
            ),
            // Bottom content
            Positioned(
              left: 4.w,
              right: 4.w,
              bottom: 2.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar
                  Container(
                    width: 12.h,
                    height: 12.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.6.h),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(38),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(1.6.h),
                      child: CustomImageWidget(
                        imageUrl: logoUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  // Name, username, verification, short bio
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (profile?['business_name'] ?? 'My Business')
                              .toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            Icon(Icons.alternate_email,
                                size: 3.6.w, color: Colors.white70),
                            SizedBox(width: 1.w),
                            Expanded(
                              child: Text(
                                (profile?['username'] ?? 'username_not_set')
                                    .toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: Colors.white.withAlpha(230),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.6.h),
                        Row(
                          children: [
                            if (profile != null)
                              SellerVerificationBadgeWidget(
                                  badgeData: profile),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                _getVerificationStatusText(
                                  (profile?['verification_status'] ?? 'pending')
                                      .toString(),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 9.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.6.h),
                        if ((profile?['business_description'] ?? '')
                            .toString()
                            .isNotEmpty)
                          Text(
                            (profile?['business_description'] ??
                                    'Welcome to our store')
                                .toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 9.sp,
                              height: 1.25,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Overflow menu
                  _storeMenuButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? innerTitle(Map<String, dynamic>? profile) {
    // Collapsed title for pinned AppBar
    if (profile == null) return null;
    return Text(
      (profile['business_name'] ?? 'My Business').toString(),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _storeMenuButton() {
    return PopupMenuButton<String>(
      offset: Offset(0, 3.h),
      onSelected: (value) {
        switch (value) {
          case 'edit_profile':
            Navigator.pushNamed(context, AppRoutes.sellerProfileSetupScreen);
            break;
          case 'business_settings':
            // TODO: business settings route
            break;
          case 'delete_profile':
            _showDeleteSellerProfileDialog();
            break;
        }
      },
      icon: Icon(Icons.more_vert, color: Colors.white, size: 3.h),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit_profile',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              const SizedBox(width: 8),
              const Text('Edit Profile'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'business_settings',
          child: Row(
            children: [
              Icon(Icons.settings, size: 18),
              const SizedBox(width: 8),
              const Text('Business Settings'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete_profile',
          child: Row(
            children: [
              const Icon(Icons.delete_forever, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Text('Delete Profile', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  // --- Sliver: Search + Filters sticky
  SliverToBoxAdapter _buildSearchAndFiltersSticky() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.2.h),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Search pill
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Search your products…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : IconButton(
                        tooltip: 'Sort & More',
                        icon: const Icon(Icons.tune),
                        onPressed: _openSortSheet,
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 1.6.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: AppTheme.primaryLight, width: 1.4),
                ),
              ),
            ),
            SizedBox(height: 1.4.h),

            // Filter chips (counts taken from analytics map if present)
            FilterChipsWidget(
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) =>
                  setState(() => _selectedFilter = filter),
              analytics: _analytics,
            ),
          ],
        ),
      ),
    );
  }

  // --- Sliver: Tab bar (Products | Analytics)
  SliverAppBar _buildTabBar() {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.grey[50],
      toolbarHeight: 0, // hide top to show only TabBar
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(48),
        child: Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryLight,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: AppTheme.primaryLight,
            isScrollable: true,
            labelStyle:
                GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Products'),
              Tab(text: 'Analytics'),
            ],
          ),
        ),
      ),
    );
  }

  // --- PRODUCTS TAB BODY
  Widget _buildProductsList() {
    final items = _filteredProducts;

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(4.w, 1.6.h, 4.w, 16.h),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 1.2.h),
      itemBuilder: (context, index) {
        final product = items[index];
        return AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: ProductCardWidget(
            product: product,
            onEdit: () => _editProduct(product),
            onDelete: () => _deleteProduct(product),
            onToggleStatus: () => _toggleProductStatus(product),
          ),
        );
      },
    );
  }

  // --- ANALYTICS TAB BODY
  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 14.h),
      child: AnalyticsDashboardWidget(analytics: _analytics),
    );
  }

  // --- EMPTY STATE
  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    if (_searchQuery.isNotEmpty) {
      title = 'No products found';
      subtitle = 'Try a different keyword or clear filters.';
      icon = Icons.search_off_rounded;
    } else if (_selectedFilter != 'all') {
      title = 'Nothing here yet';
      subtitle = 'No items match this status.';
      icon = Icons.filter_list_off_rounded;
    } else {
      title = 'Create your first product';
      subtitle = 'Start listing to reach more buyers in minutes.';
      icon = Icons.inventory_2_outlined;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48.sp, color: Colors.grey.shade400),
            SizedBox(height: 2.h),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                )),
            SizedBox(height: 0.6.h),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10.5.sp,
                  color: Colors.grey.shade600,
                )),
            if (_selectedFilter == 'all' && _searchQuery.isEmpty) ...[
              SizedBox(height: 2.4.h),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.postItemScreen,
                ).then((_) => _loadData()),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.6.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- ACTIONS
  void _editProduct(Map<String, dynamic> product) {
    Navigator.pushNamed(
      context,
      AppRoutes.postItemScreen,
      arguments: product,
    ).then((_) => _loadData());
  }

  void _deleteProduct(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product['title']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _sellerService.deleteSellerProduct(product['id']);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product deleted successfully')),
                );
                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete product: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _duplicateProduct(Map<String, dynamic> product) {
    Navigator.pushNamed(
      context,
      AppRoutes.postItemScreen,
      arguments: {...product, 'duplicate': true},
    ).then((_) => _loadData());
  }

  Future<void> _toggleProductStatus(Map<String, dynamic> product) async {
    final currentStatus = product['status'];
    final newStatus = currentStatus == 'active' ? 'inactive' : 'active';

    try {
      await _sellerService
          .updateSellerProduct(product['id'], {'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Product ${newStatus == 'active' ? 'activated' : 'deactivated'}',
          ),
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update product: $e')),
      );
    }
  }

  // --- SORT SHEET
  void _openSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text('Best performing'),
                onTap: () {
                  setState(() {
                    _products.sort(
                        (a, b) => (b['views'] ?? 0).compareTo(a['views'] ?? 0));
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.update),
                title: const Text('Recently updated'),
                onTap: () {
                  setState(() {
                    _products.sort((a, b) =>
                        DateTime.tryParse(b['updated_at'] ?? '')?.compareTo(
                          DateTime.tryParse(a['updated_at'] ?? '') ??
                              DateTime.fromMillisecondsSinceEpoch(0),
                        ) ??
                        0);
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Price: Low to High'),
                onTap: () {
                  setState(() {
                    _products.sort(
                        (a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Price: High to Low'),
                onTap: () {
                  setState(() {
                    _products.sort(
                        (a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // --- STATUS TEXT
  String _getVerificationStatusText(String status) {
    switch (status) {
      case 'verified':
        return 'Verified Seller';
      case 'pending':
        return 'Verification Pending';
      case 'rejected':
        return 'Verification Rejected';
      case 'under_review':
        return 'Under Review';
      default:
        return 'Not Verified';
    }
  }
}

// ---------- SKELETON LOADING ----------
class _LoadingListSkeleton extends StatelessWidget {
  const _LoadingListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 16.h),
      itemCount: 6,
      separatorBuilder: (_, __) => SizedBox(height: 1.2.h),
      itemBuilder: (context, index) {
        return Container(
          height: 12.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 12.h,
                height: 12.h,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(14)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBar(width: 42.w),
                      SizedBox(height: 1.h),
                      _shimmerBar(width: 30.w),
                      const Spacer(),
                      Row(
                        children: [
                          _chipSkeleton(),
                          SizedBox(width: 2.w),
                          _chipSkeleton(width: 18.w),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBar({double width = 60}) => Container(
        width: width,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
      );

  Widget _chipSkeleton({double width = 24}) => Container(
        width: width,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(100),
        ),
      );
}