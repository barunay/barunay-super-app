import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/delivery_service.dart';
import '../../widgets/global_bottom_navigation.dart';
import './widgets/delivery_details_widget.dart';
import './widgets/delivery_status_timeline_widget.dart';
import './widgets/map_view_widget.dart';
import './widgets/runner_info_card_widget.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  const DeliveryTrackingScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _bottomSheetController;
  late Animation<double> _bottomSheetAnimation;
  final DeliveryService _deliveryService = DeliveryService();

  bool _isBottomSheetExpanded = false;
  bool _isLoading = true;
  String? _deliveryRequestId;
  String? _taskId;

  Map<String, dynamic>? _deliveryData;
  Map<String, dynamic>? _runnerData;
  List<Map<String, dynamic>> _statusHistory = [];
  RealtimeChannel? _deliverySubscription;
  RealtimeChannel? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDeliveryData();
  }

  @override
  void dispose() {
    _bottomSheetController.dispose();
    _deliverySubscription?.unsubscribe();
    _locationSubscription?.unsubscribe();
    super.dispose();
  }

  void _initializeAnimations() {
    _bottomSheetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bottomSheetAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _bottomSheetController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadDeliveryData() async {
    try {
      setState(() => _isLoading = true);

      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _deliveryRequestId = args?['deliveryRequestId'] as String?;

      if (_deliveryRequestId == null) {
        throw Exception('Delivery request ID is required');
      }

      // Fetch delivery tracking data
      final trackingData = await _deliveryService.getDeliveryTracking(
        _deliveryRequestId!,
      );

      if (trackingData == null) {
        throw Exception('Delivery not found');
      }

      _taskId = trackingData['id'];

      setState(() {
        _deliveryData = trackingData['delivery_requests'];
        _runnerData = trackingData['runner_profiles'] != null
            ? {
                'id': trackingData['runner_profiles']['user_sub_profiles']
                    ['user_profiles']['id'],
                'name': trackingData['runner_profiles']['user_sub_profiles']
                    ['user_profiles']['full_name'],
                'avatar': trackingData['runner_profiles']['user_sub_profiles']
                        ['user_profiles']['avatar_url'] ??
                    'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png',
                'phone': trackingData['runner_profiles']['user_sub_profiles']
                    ['user_profiles']['phone'],
                'vehicleType': trackingData['runner_profiles']['vehicle_type'],
                'currentLatitude': trackingData['runner_profiles']
                    ['current_latitude'],
                'currentLongitude': trackingData['runner_profiles']
                    ['current_longitude'],
              }
            : null;
        _buildStatusHistory();
      });

      // Set up real-time subscriptions
      _setupRealtimeSubscriptions();
    } catch (e) {
      _showErrorSnackBar('Failed to load delivery data: ${e.toString()}');
      Navigator.pop(context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _buildStatusHistory() {
    if (_deliveryData == null) return;

    _statusHistory = [];
    final status = _deliveryData!['status'] as String;
    final createdAt = DateTime.parse(_deliveryData!['created_at']);

    // Build status timeline based on current status
    _statusHistory.add({
      'status': 'pending',
      'title': 'Request Placed',
      'description': 'Your delivery request has been submitted',
      'timestamp': createdAt,
      'isCompleted': true,
    });

    if ([
      'awaiting_runner',
      'runner_assigned',
      'in_transit',
      'delivered',
    ].contains(status)) {
      _statusHistory.add({
        'status': 'awaiting_runner',
        'title': 'Finding Runner',
        'description': 'Looking for available delivery runner',
        'timestamp': createdAt.add(const Duration(minutes: 5)),
        'isCompleted': true,
      });
    }

    if (['runner_assigned', 'in_transit', 'delivered'].contains(status)) {
      _statusHistory.add({
        'status': 'runner_assigned',
        'title': 'Runner Assigned',
        'description': '${_runnerData?['name'] ?? 'Runner'} has been assigned',
        'timestamp': createdAt.add(const Duration(minutes: 10)),
        'isCompleted': true,
      });
    }

    if (['in_transit', 'delivered'].contains(status)) {
      _statusHistory.add({
        'status': 'in_transit',
        'title': 'On the Way',
        'description': 'Your delivery is on the way',
        'timestamp': _deliveryData!['actual_pickup_time'] != null
            ? DateTime.parse(_deliveryData!['actual_pickup_time'])
            : createdAt.add(const Duration(minutes: 20)),
        'isCompleted': true,
      });
    }

    _statusHistory.add({
      'status': 'delivered',
      'title': 'Delivered',
      'description':
          status == 'delivered' ? 'Your delivery has been completed' : null,
      'timestamp': _deliveryData!['actual_delivery_time'] != null
          ? DateTime.parse(_deliveryData!['actual_delivery_time'])
          : null,
      'isCompleted': status == 'delivered',
    });
  }

  void _setupRealtimeSubscriptions() {
    if (_deliveryRequestId == null) return;

    // Subscribe to delivery status updates
    _deliverySubscription = _deliveryService.subscribeToDeliveryUpdates(
      _deliveryRequestId!,
      (data) {
        if (mounted) {
          setState(() {
            _deliveryData = {..._deliveryData!, ...data};
            _buildStatusHistory();
          });
        }
      },
    );

    // Subscribe to runner location updates
    if (_taskId != null) {
      _locationSubscription = _deliveryService.subscribeToRunnerLocation(
        _taskId!,
        (data) {
          if (mounted && _runnerData != null) {
            setState(() {
              _runnerData = {
                ..._runnerData!,
                'currentLatitude': data['runner_latitude'],
                'currentLongitude': data['runner_longitude'],
              };
            });
          }
        },
      );
    }
  }

  void _toggleBottomSheet() {
    setState(() {
      _isBottomSheetExpanded = !_isBottomSheetExpanded;
    });

    if (_isBottomSheetExpanded) {
      _bottomSheetController.forward();
    } else {
      _bottomSheetController.reverse();
    }
  }

  void _centerOnRunner() {
    HapticFeedback.lightImpact();
    // Map centering is handled in MapViewWidget
  }

  void _contactRunner() {
    if (_runnerData == null) return;

    Navigator.pushNamed(
      context,
      '/chat-screen',
      arguments: {
        'participantId': _runnerData!['id'],
        'participant': _runnerData,
        'deliveryContext': {
          'deliveryRequestId': _deliveryRequestId,
          'title': _deliveryData?['title'],
          'status': _deliveryData?['status'],
        },
        'chatType': 'delivery',
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _getCurrentStatus() {
    if (_deliveryData == null) return 'Loading...';

    final status = _deliveryData!['status'] as String;
    switch (status) {
      case 'pending':
        return 'Request Placed';
      case 'awaiting_runner':
        return 'Finding Runner';
      case 'runner_assigned':
        return 'Runner Assigned';
      case 'in_transit':
        return 'On the Way';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'awaiting_runner':
        return Colors.blue;
      case 'runner_assigned':
        return Colors.purple;
      case 'in_transit':
        return AppTheme.lightTheme.colorScheme.primary;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return 'schedule';
      case 'awaiting_runner':
        return 'search';
      case 'runner_assigned':
        return 'person';
      case 'in_transit':
        return 'local_shipping';
      case 'delivered':
        return 'check_circle';
      case 'cancelled':
        return 'cancel';
      default:
        return 'info';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const GlobalBottomNavigation(currentIndex: 2),
      );
    }

    final currentStatus = _getCurrentStatus();
    final status = _deliveryData?['status'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Track Delivery',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 6.w,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadDeliveryData,
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map view
          if (_deliveryData != null)
            MapViewWidget(
              deliveryData: _deliveryData!,
              runnerData: _runnerData ?? {},
              onCenterOnRunner: _centerOnRunner,
            ),

          // Bottom sheet with delivery information
          AnimatedBuilder(
            animation: _bottomSheetAnimation,
            builder: (context, child) {
              return Positioned(
                left: 0,
                right: 0,
                bottom: kBottomNavigationBarHeight +
                    4, // Add space for bottom navigation
                height: _bottomSheetAnimation.value * 100.h -
                    kBottomNavigationBarHeight -
                    4,
                child: GestureDetector(
                  onTap: _toggleBottomSheet,
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta! < -10) {
                      if (!_isBottomSheetExpanded) _toggleBottomSheet();
                    } else if (details.primaryDelta! > 10) {
                      if (_isBottomSheetExpanded) _toggleBottomSheet();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(5.w),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.lightTheme.colorScheme.shadow,
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: _isBottomSheetExpanded
                          ? const AlwaysScrollableScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          // Drag handle
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 2.h),
                            width: 12.w,
                            height: 0.5.h,
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.outline,
                              borderRadius: BorderRadius.circular(2.w),
                            ),
                          ),

                          // Runner info card
                          if (_runnerData != null)
                            RunnerInfoCardWidget(
                              runnerData: _runnerData!,
                              onContactRunner: _contactRunner,
                            ),

                          // Delivery details
                          if (_isBottomSheetExpanded &&
                              _deliveryData != null) ...[
                            DeliveryDetailsWidget(deliveryData: _deliveryData!),

                            // Status timeline
                            DeliveryStatusTimelineWidget(
                              statusHistory: _statusHistory,
                              currentStatus: status,
                            ),

                            SizedBox(height: 4.h),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Status indicator at top
          Positioned(
            top: 2.h,
            left: 4.w,
            right: 4.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(3.w),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: _getStatusIcon(status),
                    color: Colors.white,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      currentStatus,
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const GlobalBottomNavigation(currentIndex: 2),
    );
  }
}
