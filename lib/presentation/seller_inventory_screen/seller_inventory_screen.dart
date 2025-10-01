import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/marketplace_service.dart';
import '../../widgets/global_bottom_navigation.dart';
import './widgets/inventory_stats_widget.dart';
import './widgets/product_list_widget.dart';

class SellerInventoryScreen extends StatefulWidget {
  const SellerInventoryScreen({Key? key}) : super(key: key);

  @override
  State<SellerInventoryScreen> createState() => _SellerInventoryScreenState();
}

class _SellerInventoryScreenState extends State<SellerInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MarketplaceService _marketplaceService = MarketplaceService();

  bool _isLoading = false;
  List<Map<String, dynamic>> _allProducts = [];
  Map<String, dynamic>? _sellerProfile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load seller profile and inventory
      final [profile, inventory] = await Future.wait([
        _marketplaceService.getSellerProfile(),
        _marketplaceService.getSellerInventory(),
      ]);

      setState(() {
        _sellerProfile = profile as Map<String, dynamic>?;
        _allProducts = inventory as List<Map<String, dynamic>>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  List<Map<String, dynamic>> _getProductsByStatus(String status) {
    switch (status) {
      case 'pending':
        return _allProducts
            .where((p) => p['listing_status'] == 'pending')
            .toList();
      case 'approved':
        return _allProducts
            .where((p) => p['listing_status'] == 'approved')
            .toList();
      case 'rejected':
        return _allProducts
            .where((p) => p['listing_status'] == 'rejected')
            .toList();
      default:
        return _allProducts;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sellerProfile == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CustomIconWidget(
                iconName: 'store',
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 3.h),
              Text(
                'No Seller Profile',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              const Text(
                'You need to register as a seller to access inventory management.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.sellerProfileSetupScreen,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Register as Seller'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const GlobalBottomNavigation(currentIndex: 1),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160.0,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Seller Dashboard'),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.lightTheme.colorScheme.primary,
                        AppTheme.lightTheme.colorScheme.primary.withValues(
                          alpha: 0.8,
                        ),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(4.w, 8.h, 4.w, 2.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _sellerProfile?['business_name'] ?? 'My Business',
                          style: AppTheme.lightTheme.textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _sellerProfile?['is_verified'] == true
                                        ? Colors.green.withValues(alpha: 0.3)
                                        : Colors.orange.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(1.w),
                              ),
                              child: Text(
                                _sellerProfile?['is_verified'] == true
                                    ? 'Verified'
                                    : 'Pending',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_allProducts.length} Products',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('All'),
                        Text(
                          '${_allProducts.length}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Pending'),
                        Text(
                          '${_getProductsByStatus('pending').length}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Approved'),
                        Text(
                          '${_getProductsByStatus('approved').length}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Rejected'),
                        Text(
                          '${_getProductsByStatus('rejected').length}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverFillRemaining(
              child: Column(
                children: [
                  // Stats Overview
                  InventoryStatsWidget(
                    products: _allProducts,
                    sellerProfile: _sellerProfile!,
                  ),

                  // Product Lists
                  Expanded(
                    child:
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : TabBarView(
                              controller: _tabController,
                              children: [
                                ProductListWidget(
                                  products: _allProducts,
                                  onProductTap: _editProduct,
                                  onProductDeleted: _loadData,
                                ),
                                ProductListWidget(
                                  products: _getProductsByStatus('pending'),
                                  onProductTap: _editProduct,
                                  onProductDeleted: _loadData,
                                ),
                                ProductListWidget(
                                  products: _getProductsByStatus('approved'),
                                  onProductTap: _editProduct,
                                  onProductDeleted: _loadData,
                                ),
                                ProductListWidget(
                                  products: _getProductsByStatus('rejected'),
                                  onProductTap: _editProduct,
                                  onProductDeleted: _loadData,
                                ),
                              ],
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewProduct,
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: Colors.white,
        child: const CustomIconWidget(iconName: 'add', color: Colors.white),
      ),
      bottomNavigationBar: const GlobalBottomNavigation(currentIndex: 1),
    );
  }

  void _addNewProduct() {
    // Navigate to add product screen or show bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add new product feature coming soon!')),
    );
  }

  void _editProduct(Map<String, dynamic> product) {
    // Navigate to edit product screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${product['title']} feature coming soon!')),
    );
  }
}
