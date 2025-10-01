import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RunnerInfoCardWidget extends StatelessWidget {
  final Map<String, dynamic> runnerData;
  final VoidCallback onContactRunner;

  const RunnerInfoCardWidget({
    Key? key,
    required this.runnerData,
    required this.onContactRunner,
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
      child: Row(
        children: [
          // Runner avatar
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline,
                width: 1,
              ),
            ),
            child: ClipOval(
              child: CustomImageWidget(
                imageUrl: runnerData['avatar'] ?? '',
                width: 15.w,
                height: 15.w,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 3.w),

          // Runner details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  runnerData['name'] ?? 'Unknown Runner',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),

                // Rating and vehicle info
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'star',
                      color: Colors.amber,
                      size: 4.w,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '${runnerData['rating'] ?? 0.0}',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Container(
                      width: 1,
                      height: 3.h,
                      color: AppTheme.lightTheme.colorScheme.outline,
                    ),
                    SizedBox(width: 2.w),
                    CustomIconWidget(
                      iconName: _getVehicleIcon(runnerData['vehicleType']),
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 4.w,
                    ),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Text(
                        runnerData['vehicleType'] ?? 'Vehicle',
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),

                // Contact button
                SizedBox(
                  width: double.infinity,
                  height: 5.h,
                  child: ElevatedButton.icon(
                    onPressed: onContactRunner,
                    icon: CustomIconWidget(
                      iconName: 'chat',
                      color: Colors.white,
                      size: 4.w,
                    ),
                    label: Text(
                      'Contact Runner',
                      style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getVehicleIcon(String? vehicleType) {
    switch (vehicleType?.toLowerCase()) {
      case 'motorcycle':
      case 'bike':
        return 'motorcycle';
      case 'car':
        return 'directions_car';
      case 'bicycle':
        return 'pedal_bike';
      case 'truck':
        return 'local_shipping';
      default:
        return 'delivery_dining';
    }
  }
}
