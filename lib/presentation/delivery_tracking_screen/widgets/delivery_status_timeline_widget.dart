import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DeliveryStatusTimelineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> statusHistory;
  final String currentStatus;

  const DeliveryStatusTimelineWidget({
    Key? key,
    required this.statusHistory,
    required this.currentStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Title
          Text(
            'Delivery Status',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),

          // Timeline
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: statusHistory.length,
            itemBuilder: (context, index) {
              final status = statusHistory[index];
              final isCompleted =
                  _isStatusCompleted(status['status'], currentStatus);
              final isCurrent = status['status'] == currentStatus;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline indicator
                  Column(
                    children: [
                      Container(
                        width: 4.w,
                        height: 4.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted || isCurrent
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.outline,
                          border: Border.all(
                            color: isCurrent
                                ? AppTheme.lightTheme.colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? CustomIconWidget(
                                iconName: 'check',
                                color: Colors.white,
                                size: 2.w,
                              )
                            : null,
                      ),
                      if (index < statusHistory.length - 1)
                        Container(
                          width: 0.5.w,
                          height: 6.h,
                          color: isCompleted
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.outline,
                        ),
                    ],
                  ),
                  SizedBox(width: 3.w),

                  // Status content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status['title'],
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight:
                                isCurrent ? FontWeight.w600 : FontWeight.w500,
                            color: isCompleted || isCurrent
                                ? AppTheme.lightTheme.colorScheme.onSurface
                                : AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (status['description'] != null) ...[
                          SizedBox(height: 0.5.h),
                          Text(
                            status['description'],
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (status['timestamp'] != null) ...[
                          SizedBox(height: 0.5.h),
                          Text(
                            _formatTimestamp(status['timestamp']),
                            style: AppTheme.lightTheme.textTheme.labelSmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        SizedBox(height: 2.h),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isStatusCompleted(String status, String currentStatus) {
    final statusOrder = [
      'Request Placed',
      'Runner Assigned',
      'Pickup Confirmed',
      'In Transit',
      'Delivered'
    ];

    final statusIndex = statusOrder.indexOf(status);
    final currentIndex = statusOrder.indexOf(currentStatus);

    return statusIndex < currentIndex;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
