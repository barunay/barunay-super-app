import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/delivery_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/global_bottom_navigation.dart';
import './widgets/active_requests_widget.dart';
import './widgets/delivery_request_form_widget.dart';
import './widgets/request_history_widget.dart';
import './widgets/runner_matching_widget.dart';

class EnhancedDeliveryRequestScreen extends StatefulWidget {
  const EnhancedDeliveryRequestScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedDeliveryRequestScreen> createState() =>
      _EnhancedDeliveryRequestScreenState();
}

class _EnhancedDeliveryRequestScreenState
    extends State<EnhancedDeliveryRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DeliveryService _deliveryService = DeliveryService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _availableRunners = [];
  List<Map<String, dynamic>> _activeRequests = [];
  List<Map<String, dynamic>> _requestHistory = [];
  String _currentLocation = 'Getting location...';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load user's delivery requests
      final requests = await _deliveryService.getUserDeliveryRequests();

      // Separate active and completed requests
      final active =
          requests
              .where((r) => !['delivered', 'cancelled'].contains(r['status']))
              .toList();
      final history =
          requests
              .where((r) => ['delivered', 'cancelled'].contains(r['status']))
              .toList();

      setState(() {
        _activeRequests = active;
        _requestHistory = history;
      });

      // Load available runners (simulate based on location)
      await _loadAvailableRunners();
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

  Future<void> _loadAvailableRunners() async {
    try {
      // Get available runners from database
      final response = await SupabaseService.instance.client
          .from('runner_profiles')
          .select('''
            id,
            user_sub_profiles!runner_profiles_user_profile_id_fkey(
              user_profiles(full_name, avatar_url, phone)
            ),
            vehicle_type,
            rating_average,
            total_deliveries,
            current_latitude,
            current_longitude,
            is_available
          ''')
          .eq('is_available', true)
          .eq('is_verified', true)
          .limit(10);

      setState(() {
        _availableRunners = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading runners: $e');
      // Set mock runners if database query fails
      setState(() {
        _availableRunners = _getMockRunners();
      });
    }
  }

  List<Map<String, dynamic>> _getMockRunners() {
    return [
      {
        'id': '1',
        'user_sub_profiles': {
          'user_profiles': {
            'full_name': 'Ahmad Rahman',
            'avatar_url':
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
            'phone': '+673 8123456',
          },
        },
        'vehicle_type': 'Motorcycle',
        'rating_average': 4.8,
        'total_deliveries': 45,
        'current_latitude': 4.9031,
        'current_longitude': 114.9398,
        'estimated_arrival': '5-8 min',
        'proposed_fee': 5.00,
      },
      {
        'id': '2',
        'user_sub_profiles': {
          'user_profiles': {
            'full_name': 'Sarah Lim',
            'avatar_url':
                'https://images.unsplash.com/photo-1494790108755-2616b332b1ea?w=100',
            'phone': '+673 8765432',
          },
        },
        'vehicle_type': 'Car',
        'rating_average': 4.9,
        'total_deliveries': 32,
        'current_latitude': 4.8895,
        'current_longitude': 114.9421,
        'estimated_arrival': '8-12 min',
        'proposed_fee': 8.00,
      },
    ];
  }

  Future<void> _getCurrentLocation() async {
    // Simulate getting current location
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _currentLocation = 'Gadong, Brunei-Muara';
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  void _showEmergencyContact() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Emergency Contact'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('For urgent delivery issues, contact:'),
                SizedBox(height: 16),
                Text(
                  '📞 +673 8888-999',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '📧 emergency@delivery.com',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Available 24/7 for assistance'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Delivery Request'),
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
                        Row(
                          children: [
                            const CustomIconWidget(
                              iconName: 'location_on',
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                _currentLocation,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(1.w),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                '3',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
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
                tabs: const [
                  Tab(text: 'New Request'),
                  Tab(text: 'Find Runners'),
                  Tab(text: 'Active'),
                  Tab(text: 'History'),
                ],
              ),
            ),
            SliverFillRemaining(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                        controller: _tabController,
                        children: [
                          DeliveryRequestFormWidget(
                            onRequestCreated: () {
                              _tabController.animateTo(1);
                              _loadData();
                            },
                          ),
                          RunnerMatchingWidget(
                            availableRunners: _availableRunners,
                            onRunnerSelected: (runner) {
                              _tabController.animateTo(2);
                              _loadData();
                            },
                          ),
                          ActiveRequestsWidget(
                            activeRequests: _activeRequests,
                            onRequestTap: (request) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.deliveryTrackingScreen,
                                arguments: request['id'],
                              );
                            },
                          ),
                          RequestHistoryWidget(
                            requestHistory: _requestHistory,
                            onRequestTap: (request) {
                              // Show request details
                            },
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showEmergencyContact,
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        foregroundColor: Colors.white,
        child: const CustomIconWidget(
          iconName: 'emergency',
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: const GlobalBottomNavigation(currentIndex: 2),
    );
  }
}
