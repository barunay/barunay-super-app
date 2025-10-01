import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/delivery_service.dart';
import '../../widgets/global_bottom_navigation.dart';

class DeliveryHomeScreen extends StatefulWidget {
  const DeliveryHomeScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _deliveryRequests = [];
  final DeliveryService _deliveryService = DeliveryService();

  @override
  void initState() {
    super.initState();
    _loadDeliveryRequests();
  }

  Future<void> _loadDeliveryRequests() async {
    setState(() => _isLoading = true);

    try {
      final requests = await _deliveryService.getUserDeliveryRequests();
      setState(() {
        _deliveryRequests = requests;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load delivery requests: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'awaiting_runner':
        return 'blue';
      case 'runner_assigned':
        return 'green';
      case 'in_transit':
        return 'purple';
      case 'delivered':
        return 'green';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'awaiting_runner':
        return 'Finding Runner';
      case 'runner_assigned':
        return 'Runner Assigned';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  void _navigateToCreateDelivery() {
    // Navigate to create delivery request screen (would be implemented)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create delivery request feature coming soon!'),
      ),
    );
  }

  void _navigateToTrackingScreen(String deliveryId) {
    Navigator.pushNamed(
      context,
      AppRoutes.deliveryTrackingScreen,
      arguments: deliveryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Delivery'),
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const CustomIconWidget(iconName: 'refresh'),
            onPressed: _loadDeliveryRequests,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadDeliveryRequests,
                child:
                    _deliveryRequests.isEmpty
                        ? _buildEmptyState()
                        : _buildDeliveryList(),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateDelivery,
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 20,
        ),
        label: const Text('New Delivery'),
      ),
      bottomNavigationBar: const GlobalBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: 'local_shipping',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 16.w,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'No Delivery Requests',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              'Start by creating your first delivery request. We\'ll help you find the best runners in your area.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 4.h),
          ElevatedButton.icon(
            onPressed: _navigateToCreateDelivery,
            icon: const CustomIconWidget(
              iconName: 'add',
              color: Colors.white,
              size: 20,
            ),
            label: const Text('Create Delivery Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: Size(50.w, 6.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryList() {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _deliveryRequests.length,
      itemBuilder: (context, index) {
        final delivery = _deliveryRequests[index];
        return _buildDeliveryCard(delivery);
      },
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    final status = delivery['status'] ?? 'pending';
    final urgency = delivery['urgency'] ?? 'medium';

    return Card(
      margin: EdgeInsets.only(bottom: 3.h),
      child: InkWell(
        onTap: () => _navigateToTrackingScreen(delivery['id']),
        borderRadius: BorderRadius.circular(3.w),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      delivery['title'] ?? 'Delivery Request',
                      style: AppTheme.lightTheme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(status) == 'green'
                              ? AppTheme.lightTheme.colorScheme.tertiary
                                  .withValues(alpha: 0.2)
                              : _getStatusColor(status) == 'orange'
                              ? Colors.orange.withValues(alpha: 0.2)
                              : _getStatusColor(status) == 'blue'
                              ? AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(1.w),
                    ),
                    child: Text(
                      _formatStatus(status),
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color:
                            _getStatusColor(status) == 'green'
                                ? AppTheme.lightTheme.colorScheme.tertiary
                                : _getStatusColor(status) == 'orange'
                                ? Colors.orange
                                : _getStatusColor(status) == 'blue'
                                ? AppTheme.lightTheme.colorScheme.primary
                                : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Pickup and delivery locations
              _buildLocationRow(
                'pickup',
                delivery['pickup_address'] ?? 'Pickup location',
              ),

              SizedBox(height: 1.h),

              _buildLocationRow(
                'location_on',
                delivery['delivery_address'] ?? 'Delivery location',
              ),

              SizedBox(height: 2.h),

              // Bottom row with urgency, budget, and created date
              Row(
                children: [
                  // Urgency indicator
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color:
                          urgency == 'urgent'
                              ? AppTheme.lightTheme.colorScheme.error
                                  .withValues(alpha: 0.2)
                              : urgency == 'high'
                              ? Colors.orange.withValues(alpha: 0.2)
                              : AppTheme
                                  .lightTheme
                                  .colorScheme
                                  .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(1.w),
                    ),
                    child: Text(
                      urgency.toUpperCase(),
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color:
                            urgency == 'urgent'
                                ? AppTheme.lightTheme.colorScheme.error
                                : urgency == 'high'
                                ? Colors.orange
                                : AppTheme
                                    .lightTheme
                                    .colorScheme
                                    .onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  SizedBox(width: 2.w),

                  // Budget
                  if (delivery['max_budget'] != null) ...[
                    Text(
                      'Budget: B\$${delivery['max_budget']}',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(width: 2.w),
                  ],

                  // Created date
                  Expanded(
                    child: Text(
                      _formatDate(delivery['created_at']),
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow(String iconName, String location) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: AppTheme.lightTheme.colorScheme.primary,
          size: 4.w,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            location,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
