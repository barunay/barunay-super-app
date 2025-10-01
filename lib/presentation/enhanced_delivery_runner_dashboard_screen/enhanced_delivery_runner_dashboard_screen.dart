import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/global_bottom_navigation.dart';
import './widgets/availability_status_widget.dart';
import './widgets/active_delivery_status_widget.dart';
import './widgets/available_delivery_requests_widget.dart';
import './widgets/earnings_overview_widget.dart';
import './widgets/delivery_chat_widget.dart';
import './widgets/notification_badge_widget.dart';
import './widgets/performance_metrics_widget.dart';
import './widgets/quick_actions_widget.dart';

class EnhancedDeliveryRunnerDashboardScreen extends StatefulWidget {
  const EnhancedDeliveryRunnerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedDeliveryRunnerDashboardScreen> createState() =>
      _EnhancedDeliveryRunnerDashboardScreenState();
}

class _EnhancedDeliveryRunnerDashboardScreenState
    extends State<EnhancedDeliveryRunnerDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isOnline = false;
  bool _isLoading = false;
  int _unreadMessagesCount = 0;
  int _unreadNotificationsCount = 0;

  // Mock data for demonstration
  final Map<String, dynamic> _runnerData = {
    'name': 'Ahmad Rahman',
    'rating': 4.8,
    'completedDeliveries': 342,
    'todayEarnings': 45.50,
    'weeklyEarnings': 285.75,
    'monthlyEarnings': 1234.25,
    'averageRating': 4.8,
    'completionRate': 98.5,
    'responseTime': '2.3 min',
  };

  final Map<String, dynamic>? _activeDelivery = {
    'id': 'DEL-001',
    'title': 'Urgent Medicine Delivery',
    'customerName': 'Haji Ahmad',
    'pickupAddress': 'RIPAS Hospital, BSB',
    'deliveryAddress': 'Kampong Ayer, BSB',
    'distance': '3.2 km',
    'estimatedTime': '15 mins',
    'fee': 12.00,
    'status': 'in_transit',
    'progress': 0.7,
  };

  final List<Map<String, dynamic>> _availableRequests = [
    {
      'id': 'REQ-001',
      'title': 'Birthday Cake Delivery',
      'description': 'Delicate birthday cake, handle with care',
      'pickupAddress': 'Secret Recipe, Gadong',
      'deliveryAddress': 'Jerudong Park',
      'distance': '8.5 km',
      'estimatedEarnings': 25.00,
      'urgency': 'medium',
      'timePosted': '5 mins ago',
      'proposalsCount': 2,
      'maxBudget': 30.00,
    },
    {
      'id': 'REQ-002',
      'title': 'Document Delivery',
      'description': 'Important legal documents',
      'pickupAddress': 'Government Building, BSB',
      'deliveryAddress': 'UBD, Tungku Link',
      'distance': '12.1 km',
      'estimatedEarnings': 18.00,
      'urgency': 'high',
      'timePosted': '12 mins ago',
      'proposalsCount': 5,
      'maxBudget': 20.00,
    },
    {
      'id': 'REQ-003',
      'title': 'Grocery Shopping',
      'description': 'Weekly groceries for elderly customer',
      'pickupAddress': 'Hua Ho Manggis',
      'deliveryAddress': 'Rimba Housing',
      'distance': '4.8 km',
      'estimatedEarnings': 35.00,
      'urgency': 'low',
      'timePosted': '25 mins ago',
      'proposalsCount': 1,
      'maxBudget': 40.00,
    },
  ];

  final List<Map<String, dynamic>> _recentNotifications = [
    {
      'id': 'NOT-001',
      'title': 'New Delivery Request',
      'message': 'Urgent medicine delivery in your area',
      'type': 'new_request',
      'time': '2 mins ago',
      'isRead': false,
    },
    {
      'id': 'NOT-002',
      'title': 'Proposal Accepted',
      'message': 'Your proposal for birthday cake delivery was accepted!',
      'type': 'proposal_accepted',
      'time': '15 mins ago',
      'isRead': false,
    },
    {
      'id': 'NOT-003',
      'title': 'Payment Received',
      'message': 'B\$25.00 has been credited to your account',
      'type': 'payment',
      'time': '1 hour ago',
      'isRead': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
    _simulateRealTimeUpdates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      _unreadMessagesCount = 3;
      _unreadNotificationsCount = 2;
    });
  }

  void _simulateRealTimeUpdates() {
    // Simulate real-time updates every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _unreadNotificationsCount++;
        });
        _simulateRealTimeUpdates();
      }
    });
  }

  void _toggleAvailabilityStatus() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isOnline = !_isOnline;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isOnline
              ? 'You are now online and available for deliveries'
              : 'You are now offline',
        ),
        backgroundColor: _isOnline ? Colors.green : Colors.grey,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleRequestAction(String requestId, String action) {
    switch (action) {
      case 'accept':
        _showProposalBottomSheet(requestId);
        break;
      case 'view_details':
        _navigateToRequestDetails(requestId);
        break;
      case 'navigate':
        _startNavigation(requestId);
        break;
    }
  }

  void _showProposalBottomSheet(String requestId) {
    final request = _availableRequests.firstWhere((r) => r['id'] == requestId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 2.h),

            Text(
              'Submit Proposal',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),

            Text(
              request['title'],
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),
            SizedBox(height: 2.h),

            // Proposed fee input
            TextFormField(
              initialValue: request['estimatedEarnings'].toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Proposed Fee (B\$)',
                hintText: 'Enter your proposed fee',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 2.h),

            // Estimated time input
            TextFormField(
              initialValue: '30',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Estimated Time (minutes)',
                hintText: 'How long will it take?',
                prefixIcon: const Icon(Icons.timer),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 2.h),

            // Message input
            TextFormField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message (Optional)',
                hintText: 'Add a personal message to stand out...',
                prefixIcon: const Icon(Icons.message),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 3.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _submitProposal(requestId);
                    },
                    child: const Text('Submit Proposal'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _submitProposal(String requestId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Proposal submitted successfully!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to proposals screen
          },
        ),
      ),
    );
  }

  void _navigateToRequestDetails(String requestId) {
    // Navigate to delivery request details screen
  }

  void _startNavigation(String requestId) {
    // Open navigation app or in-app navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening navigation...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleActiveDeliveryAction(String action) {
    switch (action) {
      case 'contact_customer':
        _contactCustomer();
        break;
      case 'update_status':
        _updateDeliveryStatus();
        break;
      case 'complete_delivery':
        _completeDelivery();
        break;
    }
  }

  void _contactCustomer() {
    Navigator.pushNamed(context, '/chat-screen');
  }

  void _updateDeliveryStatus() {
    // Show status update options
  }

  void _completeDelivery() {
    // Show delivery completion flow
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 70.h,
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 2.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _unreadNotificationsCount = 0;
                    });
                  },
                  child: const Text('Mark all read'),
                ),
              ],
            ),

            Expanded(
              child: ListView.builder(
                itemCount: _recentNotifications.length,
                itemBuilder: (context, index) {
                  final notification = _recentNotifications[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 1.h),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            _getNotificationColor(notification['type']),
                        child: Icon(
                          _getNotificationIcon(notification['type']),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        notification['title'],
                        style: TextStyle(
                          fontWeight: notification['isRead']
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification['message']),
                          SizedBox(height: 0.5.h),
                          Text(
                            notification['time'],
                            style: AppTheme.lightTheme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      onTap: () {
                        // Handle notification tap
                      },
                      trailing: notification['isRead']
                          ? null
                          : Container(
                              width: 2.w,
                              height: 2.w,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'new_request':
        return Colors.blue;
      case 'proposal_accepted':
        return Colors.green;
      case 'payment':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'new_request':
        return Icons.delivery_dining;
      case 'proposal_accepted':
        return Icons.check_circle;
      case 'payment':
        return Icons.account_balance_wallet;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _activeDelivery == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Runner Dashboard',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Hello, ${_runnerData['name'].split(' ').first}!',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          // Chat messages badge
          NotificationBadgeWidget(
            count: _unreadMessagesCount,
            icon: Icons.chat_bubble_outline,
            onTap: () {
              Navigator.pushNamed(context, '/chat-screen');
            },
          ),
          SizedBox(width: 2.w),

          // Notifications badge
          NotificationBadgeWidget(
            count: _unreadNotificationsCount,
            icon: Icons.notifications_outlined,
            onTap: _showNotifications,
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: Column(
        children: [
          // Online/Offline Status Toggle
          AvailabilityStatusWidget(
            isOnline: _isOnline,
            isLoading: _isLoading,
            onToggle: _toggleAvailabilityStatus,
            todayEarnings: _runnerData['todayEarnings'],
          ),

          // Tab Controller
          Container(
            color: AppTheme.lightTheme.scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.lightTheme.primaryColor,
              unselectedLabelColor:
                  AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              indicatorColor: AppTheme.lightTheme.primaryColor,
              tabs: const [
                Tab(text: 'Active', icon: Icon(Icons.local_shipping)),
                Tab(text: 'Available', icon: Icon(Icons.list)),
                Tab(text: 'Earnings', icon: Icon(Icons.account_balance_wallet)),
                Tab(text: 'Stats', icon: Icon(Icons.analytics)),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Active Deliveries Tab
                SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      if (_activeDelivery != null) ...[
                        ActiveDeliveryStatusWidget(
                          delivery: _activeDelivery,
                          onAction: _handleActiveDeliveryAction,
                        ),
                        SizedBox(height: 2.h),
                        DeliveryChatWidget(
                          deliveryId: _activeDelivery['id'],
                          customerName: _activeDelivery['customerName'],
                        ),
                      ] else ...[
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconWidget(
                                iconName: 'local_shipping',
                                size: 20.w,
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'No Active Deliveries',
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                'Check available deliveries to get started',
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Available Requests Tab
                AvailableDeliveryRequestsWidget(
                  requests: _availableRequests,
                  onRequestAction: _handleRequestAction,
                  isOnline: _isOnline,
                ),

                // Earnings Tab
                EarningsOverviewWidget(
                  todayEarnings: _runnerData['todayEarnings'],
                  weeklyEarnings: _runnerData['weeklyEarnings'],
                  monthlyEarnings: _runnerData['monthlyEarnings'],
                  completedDeliveries: _runnerData['completedDeliveries'],
                ),

                // Performance Stats Tab
                PerformanceMetricsWidget(
                  averageRating: _runnerData['averageRating'],
                  completionRate: _runnerData['completionRate'],
                  responseTime: _runnerData['responseTime'],
                  totalDeliveries: _runnerData['completedDeliveries'],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: GlobalBottomNavigation(currentIndex: 2),
      floatingActionButton: _isOnline
          ? FloatingActionButton.extended(
              onPressed: () {
                // Quick actions menu
                _showQuickActionsMenu();
              },
              icon: const Icon(Icons.add),
              label: const Text('Quick Actions'),
              backgroundColor: AppTheme.lightTheme.primaryColor,
            )
          : null,
    );
  }

  void _showQuickActionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => QuickActionsWidget(
        onCreateDeliveryRequest: () {
          Navigator.pop(context);
          // Navigate to create delivery request
        },
        onViewEarnings: () {
          Navigator.pop(context);
          _tabController.animateTo(2);
        },
        onUpdateLocation: () {
          Navigator.pop(context);
          // Update current location
        },
        onToggleAvailability: () {
          Navigator.pop(context);
          _toggleAvailabilityStatus();
        },
      ),
    );
  }
}
