import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ActiveRequestsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> activeRequests;
  final Function(Map<String, dynamic>) onRequestTap;

  const ActiveRequestsWidget({
    Key? key,
    required this.activeRequests,
    required this.onRequestTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (activeRequests.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Active Deliveries',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(3.w),
                ),
                child: Text(
                  '${activeRequests.length}',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: ListView.builder(
              itemCount: activeRequests.length,
              itemBuilder: (context, index) {
                final request = activeRequests[index];
                return _buildRequestCard(context, request);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: 'local_shipping',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 10.w,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'No Active Deliveries',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          const Text('Your active deliveries will appear here'),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> request) {
    final status = request['status'] ?? 'pending';
    final title = request['title'] ?? 'Delivery Request';
    final pickupAddress = request['pickup_address'] ?? 'Pickup location';
    final deliveryAddress = request['delivery_address'] ?? 'Delivery location';
    final urgency = request['urgency'] ?? 'medium';
    final createdAt = request['created_at'] ?? '';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => onRequestTap(request),
        borderRadius: BorderRadius.circular(3.w),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.lightTheme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),

              SizedBox(height: 2.h),

              // Addresses
              _buildAddressRow('pickup', pickupAddress),
              SizedBox(height: 1.h),
              _buildAddressRow('location_on', deliveryAddress),

              SizedBox(height: 2.h),

              // Status Timeline
              _buildStatusTimeline(status),

              SizedBox(height: 2.h),

              // Bottom Info Row
              Row(
                children: [
                  // Urgency
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getUrgencyColor(urgency).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(1.w),
                    ),
                    child: Text(
                      urgency.toUpperCase(),
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: _getUrgencyColor(urgency),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Real-time Update Button
                  TextButton.icon(
                    onPressed: () => onRequestTap(request),
                    icon: const CustomIconWidget(
                      iconName: 'track_changes',
                      size: 16,
                    ),
                    label: const Text('Track'),
                  ),

                  // Contact Runner Button
                  if (status == 'runner_assigned' ||
                      status == 'in_transit') ...[
                    SizedBox(width: 2.w),
                    IconButton(
                      onPressed: () => _contactRunner(context, request),
                      icon: const CustomIconWidget(iconName: 'phone', size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            AppTheme.lightTheme.colorScheme.primaryContainer,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    final text = _formatStatus(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(1.w),
      ),
      child: Text(
        text,
        style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAddressRow(String iconName, String address) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: AppTheme.lightTheme.colorScheme.primary,
          size: 16,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            address,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTimeline(String currentStatus) {
    final steps = [
      'pending',
      'awaiting_runner',
      'runner_assigned',
      'in_transit',
      'delivered',
    ];
    final currentIndex = steps.indexOf(currentStatus);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(2.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Progress',
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children:
                steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  final isActive = index <= currentIndex;

                  return Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 2.w,
                          height: 2.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isActive
                                    ? AppTheme.lightTheme.colorScheme.primary
                                    : AppTheme.lightTheme.colorScheme.outline,
                          ),
                        ),
                        if (index < steps.length - 1) ...[
                          Expanded(
                            child: Container(
                              height: 0.2.h,
                              color:
                                  index < currentIndex
                                      ? AppTheme.lightTheme.colorScheme.primary
                                      : AppTheme.lightTheme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
          ),
          SizedBox(height: 1.h),
          Text(
            _formatStatus(currentStatus),
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'awaiting_runner':
        return Colors.blue;
      case 'runner_assigned':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'cancelled':
        return AppTheme.lightTheme.colorScheme.error;
      default:
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'urgent':
        return AppTheme.lightTheme.colorScheme.error;
      case 'high':
        return Colors.orange;
      default:
        return AppTheme.lightTheme.colorScheme.primary;
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

  void _contactRunner(BuildContext context, Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Contact Runner',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3.h),
                ListTile(
                  leading: const CustomIconWidget(iconName: 'phone'),
                  title: const Text('Call Runner'),
                  subtitle: const Text('+673 8123456'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling runner...')),
                    );
                  },
                ),
                ListTile(
                  leading: const CustomIconWidget(iconName: 'message'),
                  title: const Text('Send Message'),
                  subtitle: const Text('Chat with your runner'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening chat...')),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }
}
