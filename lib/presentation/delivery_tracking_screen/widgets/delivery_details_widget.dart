import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DeliveryDetailsWidget extends StatelessWidget {
  final Map<String, dynamic> deliveryData;

  const DeliveryDetailsWidget({
    Key? key,
    required this.deliveryData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Delivery Details',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),

          // Item description
          _buildDetailRow(
            icon: 'inventory_2',
            title: 'Item',
            content: deliveryData['itemDescription'] ?? 'No description',
          ),
          SizedBox(height: 2.h),

          // Pickup address
          _buildDetailRow(
            icon: 'location_on',
            title: 'Pickup Location',
            content: deliveryData['pickupAddress'] ?? 'No address provided',
          ),
          SizedBox(height: 2.h),

          // Dropoff address
          _buildDetailRow(
            icon: 'flag',
            title: 'Delivery Location',
            content: deliveryData['dropoffAddress'] ?? 'No address provided',
          ),
          SizedBox(height: 2.h),

          // Special instructions
          if (deliveryData['specialInstructions'] != null &&
              (deliveryData['specialInstructions'] as String).isNotEmpty) ...[
            _buildDetailRow(
              icon: 'note',
              title: 'Special Instructions',
              content: deliveryData['specialInstructions'],
            ),
            SizedBox(height: 2.h),
          ],

          // Estimated time
          if (deliveryData['estimatedTime'] != null) ...[
            _buildDetailRow(
              icon: 'schedule',
              title: 'Estimated Delivery',
              content: _formatEstimatedTime(deliveryData['estimatedTime']),
            ),
            SizedBox(height: 2.h),
          ],

          // Total cost
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Cost',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'B\$${deliveryData['totalCost']?.toStringAsFixed(2) ?? '0.00'}',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomIconWidget(
          iconName: icon,
          color: AppTheme.lightTheme.colorScheme.primary,
          size: 5.w,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                content,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatEstimatedTime(DateTime estimatedTime) {
    final now = DateTime.now();
    final difference = estimatedTime.difference(now);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ${difference.inMinutes % 60} minutes';
    } else {
      return '${estimatedTime.day}/${estimatedTime.month}/${estimatedTime.year} at ${estimatedTime.hour}:${estimatedTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
