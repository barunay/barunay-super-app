import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LocationPermissionCard extends StatelessWidget {
  final bool isGranted;
  final VoidCallback onRequestPermission;

  const LocationPermissionCard({
    Key? key,
    required this.isGranted,
    required this.onRequestPermission,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isGranted
            ? AppTheme.successLight.withValues(alpha: 0.1)
            : AppTheme.warningLight.withValues(alpha: 0.1),
        border: Border.all(
          color: isGranted
              ? AppTheme.successLight.withValues(alpha: 0.3)
              : AppTheme.warningLight.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color:
                      isGranted ? AppTheme.successLight : AppTheme.warningLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: CustomIconWidget(
                  iconName: isGranted ? 'location_on' : 'location_off',
                  color: Colors.white,
                  size: 4.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  isGranted ? 'Location Access Granted' : 'Location Permission',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    color: isGranted
                        ? AppTheme.successLight
                        : AppTheme.warningLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isGranted)
                CustomIconWidget(
                  iconName: 'check_circle',
                  color: AppTheme.successLight,
                  size: 5.w,
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            isGranted
                ? 'Great! You\'ll get personalized business recommendations and accurate delivery tracking.'
                : 'Enable location access to discover nearby businesses and track your deliveries in real-time.',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (!isGranted) ...[
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRequestPermission,
                icon: CustomIconWidget(
                  iconName: 'location_on',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 4.w,
                ),
                label: Text(
                  'Enable Location',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  side: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
