import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DeliveryContextCardWidget extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final VoidCallback? onTrackDelivery;
  final VoidCallback? onContactRunner;
  final VoidCallback? onReportIssue;

  const DeliveryContextCardWidget({
    Key? key,
    required this.delivery,
    this.onTrackDelivery,
    this.onContactRunner,
    this.onReportIssue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = (delivery['status'] as String?) ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
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
          Row(
            children: [
              CustomIconWidget(
                iconName: 'local_shipping',
                color: statusColor,
                size: 4.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Delivery #${delivery['id'] ?? 'Unknown'}',
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: statusIcon,
                      color: statusColor,
                      size: 3.w,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      _getStatusText(status),
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildLocationInfo(),
          SizedBox(height: 2.h),
          if (delivery['runner'] != null) _buildRunnerInfo(),
          SizedBox(height: 2.h),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Column(
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: 'radio_button_checked',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 4.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup Location',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    (delivery['pickupAddress'] as String?) ??
                        'Unknown pickup location',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          margin: EdgeInsets.only(left: 2.w),
          height: 4.h,
          width: 1,
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        Row(
          children: [
            CustomIconWidget(
              iconName: 'location_on',
              color: AppTheme.lightTheme.colorScheme.error,
              size: 4.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Location',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    (delivery['deliveryAddress'] as String?) ??
                        'Unknown delivery location',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRunnerInfo() {
    final runner = delivery['runner'] as Map<String, dynamic>;
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(2.w),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 4.w,
            backgroundColor:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            child: CustomImageWidget(
              imageUrl: (runner['avatar'] as String?) ??
                  'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png',
              width: 8.w,
              height: 8.w,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (runner['name'] as String?) ?? 'Unknown Runner',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'star',
                      color: AppTheme.lightTheme.colorScheme.secondary,
                      size: 3.w,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '${runner['rating'] ?? '4.8'} (${runner['reviews'] ?? '124'} reviews)',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onContactRunner,
            icon: CustomIconWidget(
              iconName: 'call',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 5.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTrackDelivery,
            icon: CustomIconWidget(
              iconName: 'track_changes',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 4.w,
            ),
            label: Text(
              'Track',
              style: AppTheme.lightTheme.textTheme.labelMedium,
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: TextButton.icon(
            onPressed: onReportIssue,
            icon: CustomIconWidget(
              iconName: 'report_problem',
              color: AppTheme.lightTheme.colorScheme.error,
              size: 4.w,
            ),
            label: Text(
              'Report Issue',
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.lightTheme.colorScheme.secondary;
      case 'picked_up':
      case 'in_transit':
        return AppTheme.lightTheme.colorScheme.primary;
      case 'delivered':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'cancelled':
        return AppTheme.lightTheme.colorScheme.error;
      default:
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'schedule';
      case 'picked_up':
        return 'inventory';
      case 'in_transit':
        return 'local_shipping';
      case 'delivered':
        return 'check_circle';
      case 'cancelled':
        return 'cancel';
      default:
        return 'help';
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'picked_up':
        return 'Picked Up';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}
