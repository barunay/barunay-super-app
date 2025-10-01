import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/active_delivery_card_widget.dart';
import './widgets/available_deliveries_widget.dart';
import './widgets/earnings_chart_widget.dart';
import './widgets/earnings_summary_widget.dart';
import './widgets/quick_stats_widget.dart';
import './widgets/status_toggle_widget.dart';

class DeliveryRunnerDashboardScreen extends StatefulWidget {
  const DeliveryRunnerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryRunnerDashboardScreen> createState() =>
      _DeliveryRunnerDashboardScreenState();
}

class _DeliveryRunnerDashboardScreenState
    extends State<DeliveryRunnerDashboardScreen> {
  int _currentIndex = 0;
  bool _isOnline = true;

  // Mock data for active delivery
  Map<String, dynamic>? _activeDelivery = {
    "orderId": "DEL001",
    "status": "In Transit",
    "pickupLocation": "McDonald's Gadong",
    "dropoffLocation": "Kampong Ayer Cultural & Tourism Gallery",
    "customerName": "Ahmad Rahman",
    "customerPhone": "+673 8123456",
    "earnings": 15.50,
    "estimatedTime": "25 mins",
  };

  // Mock data for available deliveries
  final List<Map<String, dynamic>> _availableDeliveries = [
    {
      "orderId": "DEL002",
      "itemType": "Food",
      "pickupLocation": "KFC Times Square",
      "dropoffLocation": "Universiti Brunei Darussalam",
      "earnings": 18.75,
      "distance": 12.5,
      "expiresIn": 8,
      "customerName": "Siti Nurhaliza",
    },
    {
      "orderId": "DEL003",
      "itemType": "Package",
      "pickupLocation": "The Mall Gadong",
      "dropoffLocation": "Jerudong Park Playground",
      "earnings": 22.00,
      "distance": 15.2,
      "expiresIn": 12,
      "customerName": "David Lim",
    },
    {
      "orderId": "DEL004",
      "itemType": "Food",
      "pickupLocation": "Ayamku Kiulap",
      "dropoffLocation": "Brunei International Airport",
      "earnings": 35.50,
      "distance": 8.7,
      "expiresIn": 5,
      "customerName": "Maria Santos",
    },
  ];

  // Mock data for daily earnings
  final List<Map<String, dynamic>> _dailyEarnings = [
    {"day": "Mon", "earnings": 125.50},
    {"day": "Tue", "earnings": 98.75},
    {"day": "Wed", "earnings": 156.25},
    {"day": "Thu", "earnings": 142.00},
    {"day": "Fri", "earnings": 178.50},
    {"day": "Sat", "earnings": 195.75},
    {"day": "Sun", "earnings": 167.25},
  ];

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isOnline
            ? 'You are now online and available for deliveries'
            : 'You are now offline'),
        backgroundColor: _isOnline
            ? AppTheme.lightTheme.colorScheme.tertiary
            : AppTheme.lightTheme.colorScheme.error,
      ),
    );
  }

  void _navigateToCustomer() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening navigation to customer location...'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }

  void _contactCustomer() {
    if (_activeDelivery != null) {
      Navigator.pushNamed(context, '/chat-screen');
    }
  }

  void _markDeliveryComplete() {
    setState(() {
      _activeDelivery = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Delivery marked as complete! Great job!'),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
      ),
    );
  }

  void _acceptDelivery(Map<String, dynamic> delivery) {
    setState(() {
      _activeDelivery = {
        "orderId": delivery["orderId"],
        "status": "Accepted",
        "pickupLocation": delivery["pickupLocation"],
        "dropoffLocation": delivery["dropoffLocation"],
        "customerName": delivery["customerName"],
        "customerPhone": "+673 8123456",
        "earnings": delivery["earnings"],
        "estimatedTime": "30 mins",
      };
      _availableDeliveries
          .removeWhere((d) => d["orderId"] == delivery["orderId"]);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Delivery accepted! Head to pickup location.'),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        // Dashboard - already here
        break;
      case 1:
        // Available Jobs - could navigate to a dedicated screen
        break;
      case 2:
        // Earnings - could navigate to earnings detail screen
        break;
      case 3:
        _showRunnerProfileSwitchDialog();
        break;
    }
  }

  void _showRunnerProfileSwitchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),

            // Icon
            Container(
              width: 16.w,
              height: 16.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'person',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 8.w,
              ),
            ),

            SizedBox(height: 2.h),

            Text(
              'Profile Management',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 1.h),

            Text(
              'Manage your runner profile or switch to other profiles.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 3.h),

            // Action buttons
            Column(
              children: [
                // Runner Profile Settings
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/user-profile-screen');
                    },
                    icon: CustomIconWidget(
                      iconName: 'settings',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    ),
                    label: const Text('Runner Profile Settings'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(0, 6.h),
                      side: BorderSide(
                        color: AppTheme.lightTheme.colorScheme.outline,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 2.h),

                // Switch to Shopper Profile
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(
                          context, '/marketplace-home-screen');
                    },
                    icon: CustomIconWidget(
                      iconName: 'shopping_bag',
                      color: Colors.white,
                      size: 5.w,
                    ),
                    label: const Text('Switch to Shopper Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.lightTheme.colorScheme.secondary,
                      minimumSize: Size(0, 6.h),
                    ),
                  ),
                ),

                SizedBox(height: 1.h),

                // Manage All Profiles
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.profileManagementScreen);
                    },
                    icon: CustomIconWidget(
                      iconName: 'manage_accounts',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    ),
                    label: const Text('Manage All Profiles'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Runner Dashboard',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Show location accuracy or settings
            },
            icon: CustomIconWidget(
              iconName: 'gps_fixed',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: () {
              // Show notifications
            },
            icon: Stack(
              children: [
                CustomIconWidget(
                  iconName: 'notifications',
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  size: 24,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Toggle
            StatusToggleWidget(
              isOnline: _isOnline,
              onToggle: _toggleOnlineStatus,
            ),
            SizedBox(height: 3.h),

            // Earnings Summary
            EarningsSummaryWidget(
              todayEarnings: 156.75,
              weeklyEarnings: 1063.75,
              monthlyEarnings: 4255.50,
            ),
            SizedBox(height: 3.h),

            // Active Delivery Card
            ActiveDeliveryCardWidget(
              activeDelivery: _activeDelivery,
              onNavigate: _navigateToCustomer,
              onContactCustomer: _contactCustomer,
              onMarkComplete: _markDeliveryComplete,
            ),
            SizedBox(height: 3.h),

            // Available Deliveries
            if (_isOnline) ...[
              AvailableDeliveriesWidget(
                availableDeliveries: _availableDeliveries,
                onAcceptDelivery: _acceptDelivery,
              ),
              SizedBox(height: 3.h),
            ],

            // Quick Stats
            QuickStatsWidget(
              completedDeliveries: 247,
              averageRating: 4.8,
              completionRate: 96.5,
            ),
            SizedBox(height: 3.h),

            // Earnings Chart
            EarningsChartWidget(
              dailyEarnings: _dailyEarnings,
            ),
            SizedBox(height: 10.h), // Bottom padding for FAB
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
        unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'dashboard',
              color: _currentIndex == 0
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'work',
              color: _currentIndex == 1
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Available Jobs',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'account_balance_wallet',
              color: _currentIndex == 2
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'person',
              color: _currentIndex == 3
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleOnlineStatus,
        backgroundColor: _isOnline
            ? AppTheme.lightTheme.colorScheme.error
            : AppTheme.lightTheme.colorScheme.tertiary,
        foregroundColor: Colors.white,
        icon: CustomIconWidget(
          iconName: _isOnline ? 'pause' : 'play_arrow',
          color: Colors.white,
          size: 20,
        ),
        label: Text(_isOnline ? 'Go Offline' : 'Go Online'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}