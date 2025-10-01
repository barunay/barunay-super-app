import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/global_bottom_navigation.dart';
import './widgets/business_card_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/location_selector_widget.dart';
import './widgets/search_filter_widget.dart';
import './widgets/sort_bottom_sheet_widget.dart';

class BusinessDirectoryScreen extends StatefulWidget {
  const BusinessDirectoryScreen({Key? key}) : super(key: key);

  @override
  State<BusinessDirectoryScreen> createState() =>
      _BusinessDirectoryScreenState();
}

class _BusinessDirectoryScreenState extends State<BusinessDirectoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final RefreshIndicator _refreshIndicatorKey = RefreshIndicator(
    onRefresh: () async {},
    child: Container(),
  );

  String _searchQuery = '';
  String _selectedLocation = 'Current Location';
  String _currentSort = 'distance';
  bool _isMapView = false;
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 1;

  Map<String, dynamic> _currentFilters = {
    'category': 'All Categories',
    'distance': 'Any distance',
    'minRating': null,
    'openNow': false,
  };

  List<Map<String, dynamic>> _businesses = [];
  List<Map<String, dynamic>> _filteredBusinesses = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _businesses = [
      {
        "id": 1,
        "name": "Gadong Night Market",
        "category": "Restaurants",
        "rating": 4.5,
        "distance": "2.3 km",
        "isOpen": true,
        "description":
            "Traditional Brunei street food and local delicacies. Famous for ambuyat, satay, and fresh seafood dishes.",
        "imageUrl":
            "https://images.pexels.com/photos/1267320/pexels-photo-1267320.jpeg?auto=compress&cs=tinysrgb&w=800",
        "isFavorite": false,
        "phone": "+673 123 4567",
        "website": "www.gadongmarket.bn",
        "address": "Gadong, Bandar Seri Begawan",
      },
      {
        "id": 2,
        "name": "Royal Regalia Museum Shop",
        "category": "Retail",
        "rating": 4.8,
        "distance": "1.5 km",
        "isOpen": true,
        "description":
            "Official museum gift shop featuring authentic Brunei souvenirs, traditional crafts, and royal memorabilia.",
        "imageUrl":
            "https://images.pexels.com/photos/1005638/pexels-photo-1005638.jpeg?auto=compress&cs=tinysrgb&w=800",
        "isFavorite": true,
        "phone": "+673 234 5678",
        "website": "www.museum.gov.bn",
        "address": "Bandar Seri Begawan",
      },
      {
        "id": 3,
        "name": "Brunei Wellness Spa",
        "category": "Beauty & Wellness",
        "rating": 4.7,
        "distance": "3.1 km",
        "isOpen": false,
        "description":
            "Premium spa services with traditional Malay healing treatments and modern wellness therapies.",
        "imageUrl":
            "https://images.pexels.com/photos/3757942/pexels-photo-3757942.jpeg?auto=compress&cs=tinysrgb&w=800",
        "isFavorite": false,
        "phone": "+673 345 6789",
        "website": "www.bruneiwellness.com",
        "address": "Kiulap, Bandar Seri Begawan",
      },
      {
        "id": 4,
        "name": "Tech Solutions Brunei",
        "category": "Technology",
        "rating": 4.3,
        "distance": "4.2 km",
        "isOpen": true,
        "description":
            "IT services, computer repairs, and digital solutions for businesses and individuals in Brunei.",
        "imageUrl":
            "https://images.pexels.com/photos/3861969/pexels-photo-3861969.jpeg?auto=compress&cs=tinysrgb&w=800",
        "isFavorite": false,
        "phone": "+673 456 7890",
        "website": "www.techsolutions.bn",
        "address": "Rimba, Bandar Seri Begawan",
      },
      {
        "id": 5,
        "name": "Seria Auto Service",
        "category": "Automotive",
        "rating": 4.2,
        "distance": "45.8 km",
        "isOpen": true,
        "description":
            "Complete automotive services including repairs, maintenance, and parts for all vehicle types.",
        "imageUrl":
            "https://images.pexels.com/photos/3806288/pexels-photo-3806288.jpeg?auto=compress&cs=tinysrgb&w=800",
        "isFavorite": false,
        "phone": "+673 567 8901",
        "website": "www.seriaauto.bn",
        "address": "Seria, Belait District",
      },
      {
        "id": 6,
        "name": "Tutong Medical Centre",
        "category": "Healthcare",
        "rating": 4.6,
        "distance": "32.5 km",
        "isOpen": true,
        "description":
            "Comprehensive healthcare services with experienced doctors and modern medical facilities.",
        "imageUrl":
            "https://images.pexels.com/photos/263402/pexels-photo-263402.jpeg?auto=compress&cs=tinysrgb&w=800",
        "isFavorite": true,
        "phone": "+673 678 9012",
        "website": "www.tutongmedical.bn",
        "address": "Tutong Town, Tutong District",
      },
      {
        "id": 7,
        "name": "Jerudong International School",
        "category": "Education",
        "rating": 4.9,
        "distance": "8.7 km",
        "isOpen": true,
        "description":
            "Premier international school offering world-class education with British curriculum and modern facilities.",
        "imageUrl":
            "https://images.pexels.com/photos/289740/pexels-photo-289740.jpeg?auto=compress&cs=tinysrgb&w=800",
        "isFavorite": false,
        "phone": "+673 789 0123",
        "website": "www.jis.edu.bn",
        "address": "Jerudong, Brunei-Muara District",
      },
      {
        "id": 8,
        "name": "Empire Cinema",
        "category": "Entertainment",
        "rating": 4.4,
        "distance": "12.3 km",
        "isOpen": true,
        "description":
            "Luxury cinema experience with latest movies, premium seating, and state-of-the-art sound systems.",
        "imageUrl":
            "https://images.pexels.com/photos/7991579/pexels-photo-7991579.jpeg?auto=compress&cs=tinysrgb&w=800",
        "isFavorite": false,
        "phone": "+673 890 1234",
        "website": "www.empirecinema.bn",
        "address": "Jerudong, Brunei-Muara District",
      },
    ];

    _applyFiltersAndSort();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Simulate no more data after page 3
    if (_currentPage >= 3) {
      setState(() {
        _hasMoreData = false;
        _isLoading = false;
      });
      return;
    }

    _currentPage++;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _currentPage = 1;
      _hasMoreData = true;
    });

    // Simulate refresh delay
    await Future.delayed(const Duration(seconds: 1));

    _applyFiltersAndSort();

    Fluttertoast.showToast(
      msg: "Business directory updated",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = List.from(_businesses);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((business) {
        final name = (business['name'] as String).toLowerCase();
        final category = (business['category'] as String).toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || category.contains(query);
      }).toList();
    }

    // Apply category filter
    if (_currentFilters['category'] != 'All Categories') {
      filtered = filtered
          .where(
              (business) => business['category'] == _currentFilters['category'])
          .toList();
    }

    // Apply rating filter
    if (_currentFilters['minRating'] != null) {
      filtered = filtered
          .where((business) =>
              (business['rating'] as double) >= _currentFilters['minRating'])
          .toList();
    }

    // Apply open now filter
    if (_currentFilters['openNow'] == true) {
      filtered =
          filtered.where((business) => business['isOpen'] == true).toList();
    }

    // Apply sorting
    switch (_currentSort) {
      case 'distance':
        filtered.sort((a, b) {
          final distanceA =
              double.parse((a['distance'] as String).split(' ')[0]);
          final distanceB =
              double.parse((b['distance'] as String).split(' ')[0]);
          return distanceA.compareTo(distanceB);
        });
        break;
      case 'rating':
        filtered.sort(
            (a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
        break;
      case 'newest':
        filtered.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
        break;
      case 'alphabetical':
        filtered.sort(
            (a, b) => (a['name'] as String).compareTo(b['name'] as String));
        break;
    }

    setState(() {
      _filteredBusinesses = filtered;
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FilterBottomSheetWidget(
        currentFilters: _currentFilters,
        onFiltersApplied: (filters) {
          setState(() {
            _currentFilters = filters;
          });
          _applyFiltersAndSort();
        },
      ),
    );
  }

  void _showLocationSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => LocationSelectorWidget(
        selectedLocation: _selectedLocation,
        onLocationSelected: (location) {
          setState(() {
            _selectedLocation = location;
          });
          _applyFiltersAndSort();
        },
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SortBottomSheetWidget(
        currentSort: _currentSort,
        onSortSelected: (sort) {
          setState(() {
            _currentSort = sort;
          });
          _applyFiltersAndSort();
        },
      ),
    );
  }

  void _toggleMapView() {
    setState(() {
      _isMapView = !_isMapView;
    });

    Fluttertoast.showToast(
      msg: _isMapView ? "Map view enabled" : "List view enabled",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onBusinessTap(Map<String, dynamic> business) {
    // Navigate to business detail screen
    Fluttertoast.showToast(
      msg: "Opening ${business['name']}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onBusinessCall(Map<String, dynamic> business) {
    Fluttertoast.showToast(
      msg: "Calling ${business['name']}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onBusinessMessage(Map<String, dynamic> business) {
    Navigator.pushNamed(context, '/chat-screen');
  }

  void _onBusinessWebsite(Map<String, dynamic> business) {
    Fluttertoast.showToast(
      msg: "Opening ${business['website']}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onBusinessFavorite(Map<String, dynamic> business) {
    setState(() {
      final index = _businesses.indexWhere((b) => b['id'] == business['id']);
      if (index != -1) {
        _businesses[index]['isFavorite'] =
            !(_businesses[index]['isFavorite'] as bool);
      }
    });
    _applyFiltersAndSort();

    final isFavorite = business['isFavorite'] as bool;
    Fluttertoast.showToast(
      msg: isFavorite ? "Removed from favorites" : "Added to favorites",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onBusinessShare(Map<String, dynamic> business) {
    Fluttertoast.showToast(
      msg: "Sharing ${business['name']}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onBusinessDirections(Map<String, dynamic> business) {
    Fluttertoast.showToast(
      msg: "Getting directions to ${business['name']}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Business Directory',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Sort Button
          IconButton(
            onPressed: _showSortBottomSheet,
            icon: CustomIconWidget(
              iconName: 'sort',
              size: 6.w,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          // Map Toggle Button
          IconButton(
            onPressed: _toggleMapView,
            icon: CustomIconWidget(
              iconName: _isMapView ? 'list' : 'map',
              size: 6.w,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Header
          SearchFilterWidget(
            searchQuery: _searchQuery,
            onSearchChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
              _applyFiltersAndSort();
            },
            onFilterTap: _showFilterBottomSheet,
            selectedLocation: _selectedLocation,
            onLocationTap: _showLocationSelector,
          ),

          // Content Area
          Expanded(
            child: _isMapView ? _buildMapView() : _buildListView(),
          ),
        ],
      ),
      bottomNavigationBar: GlobalBottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildListView() {
    if (_filteredBusinesses.isEmpty && _searchQuery.isEmpty) {
      return _buildLoadingState();
    }

    if (_filteredBusinesses.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(vertical: 2.h),
        itemCount: _filteredBusinesses.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredBusinesses.length) {
            return _buildLoadingIndicator();
          }

          final business = _filteredBusinesses[index];
          return BusinessCardWidget(
            business: business,
            onTap: () => _onBusinessTap(business),
            onCall: () => _onBusinessCall(business),
            onMessage: () => _onBusinessMessage(business),
            onWebsite: () => _onBusinessWebsite(business),
            onFavorite: () => _onBusinessFavorite(business),
            onShare: () => _onBusinessShare(business),
            onDirections: () => _onBusinessDirections(business),
          );
        },
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'map',
            size: 20.w,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 2.h),
          Text(
            'Map View',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Interactive map with business locations\nwould be displayed here',
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: _toggleMapView,
            child: Text(
              'Switch to List View',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(height: 2.h),
          Text(
            'Loading businesses...',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              size: 20.w,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 3.h),
            Text(
              'No businesses found',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Try adjusting your search terms or filters to find more businesses in your area.',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _currentFilters = {
                          'category': 'All Categories',
                          'distance': 'Any distance',
                          'minRating': null,
                          'openNow': false,
                        };
                      });
                      _applyFiltersAndSort();
                    },
                    child: Text('Clear Filters'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _refreshData,
                    child: Text(
                      'Refresh',
                      style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    if (!_isLoading) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.lightTheme.colorScheme.primary,
        ),
      ),
    );
  }
}
