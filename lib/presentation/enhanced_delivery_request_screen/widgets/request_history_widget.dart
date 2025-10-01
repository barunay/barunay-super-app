import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RequestHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> requestHistory;
  final Function(Map<String, dynamic>) onRequestTap;

  const RequestHistoryWidget({
    Key? key,
    required this.requestHistory,
    required this.onRequestTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (requestHistory.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery History',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: ListView.builder(
              itemCount: requestHistory.length,
              itemBuilder: (context, index) {
                final request = requestHistory[index];
                return _buildHistoryCard(context, request);
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
              iconName: 'history',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 10.w,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'No Delivery History',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          const Text('Your completed deliveries will appear here'),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> request) {
    final status = request['status'] ?? 'delivered';
    final title = request['title'] ?? 'Delivery Request';
    final pickupAddress = request['pickup_address'] ?? 'Pickup location';
    final deliveryAddress = request['delivery_address'] ?? 'Delivery location';
    final createdAt = request['created_at'] ?? '';
    final maxBudget = request['max_budget'];

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

              // Bottom Row
              Row(
                children: [
                  // Date
                  Row(
                    children: [
                      const CustomIconWidget(iconName: 'schedule', size: 16),
                      SizedBox(width: 1.w),
                      Text(
                        _formatDate(createdAt),
                        style: AppTheme.lightTheme.textTheme.bodySmall
                            ?.copyWith(
                              color:
                                  AppTheme
                                      .lightTheme
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Budget
                  if (maxBudget != null) ...[
                    Text(
                      'B\$${maxBudget.toStringAsFixed(2)}',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 3.w),
                  ],

                  // Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status == 'delivered') ...[
                        IconButton(
                          onPressed: () => _showRatingDialog(context, request),
                          icon: const CustomIconWidget(
                            iconName: 'star_border',
                            size: 20,
                          ),
                          tooltip: 'Rate Delivery',
                        ),
                        IconButton(
                          onPressed: () => _showReceiptDialog(context, request),
                          icon: const CustomIconWidget(
                            iconName: 'receipt',
                            size: 20,
                          ),
                          tooltip: 'View Receipt',
                        ),
                      ],
                      IconButton(
                        onPressed: () => _reorderDelivery(context, request),
                        icon: const CustomIconWidget(
                          iconName: 'refresh',
                          size: 20,
                        ),
                        tooltip: 'Reorder',
                      ),
                    ],
                  ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'cancelled':
        return AppTheme.lightTheme.colorScheme.error;
      default:
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';

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
      return dateStr;
    }
  }

  void _showRatingDialog(BuildContext context, Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Rate Delivery'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('How was your delivery experience?'),
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Rated ${index + 1} stars. Thank you!',
                            ),
                          ),
                        );
                      },
                      icon: const CustomIconWidget(
                        iconName: 'star_border',
                        size: 30,
                        color: Colors.amber,
                      ),
                    );
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _showReceiptDialog(BuildContext context, Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delivery Receipt'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Request: ${request['title'] ?? 'Delivery'}'),
                SizedBox(height: 1.h),
                Text('Date: ${_formatDate(request['created_at'] ?? '')}'),
                SizedBox(height: 1.h),
                Text(
                  'Fee: B\$${request['max_budget']?.toStringAsFixed(2) ?? '0.00'}',
                ),
                SizedBox(height: 1.h),
                Text(
                  'Status: ${_formatStatus(request['status'] ?? 'delivered')}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Receipt downloaded!')),
                  );
                },
                child: const Text('Download'),
              ),
            ],
          ),
    );
  }

  void _reorderDelivery(BuildContext context, Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reorder Delivery'),
            content: const Text(
              'Create a new delivery request with the same details?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reorder created! Check New Request tab.'),
                    ),
                  );
                },
                child: const Text('Reorder'),
              ),
            ],
          ),
    );
  }
}
