import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LocationSelectorWidget extends StatelessWidget {
  final String selectedLocation;
  final Function(String) onLocationSelected;

  const LocationSelectorWidget({
    Key? key,
    required this.selectedLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> bruneiLocations = [
      'Current Location',
      'Bandar Seri Begawan',
      'Kuala Belait',
      'Seria',
      'Tutong',
      'Jerudong',
      'Gadong',
      'Kiulap',
      'Rimba',
      'Sengkurong',
      'Lumapas',
      'Mentiri',
      'Muara',
      'Temburong',
    ];

    return Container(
      height: 60.h,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: EdgeInsets.only(top: 2.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Text(
                  'Select Location',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    size: 6.w,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppTheme.lightTheme.colorScheme.outline),

          // Location List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              itemCount: bruneiLocations.length,
              itemBuilder: (context, index) {
                final location = bruneiLocations[index];
                final bool isSelected = selectedLocation == location;
                final bool isCurrentLocation = location == 'Current Location';

                return ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: isCurrentLocation
                          ? AppTheme.lightTheme.colorScheme.primaryContainer
                          : AppTheme
                              .lightTheme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: CustomIconWidget(
                      iconName:
                          isCurrentLocation ? 'my_location' : 'location_on',
                      size: 5.w,
                      color: isCurrentLocation
                          ? AppTheme.lightTheme.colorScheme.onPrimaryContainer
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(
                    location,
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: isCurrentLocation
                      ? Text(
                          'Use GPS to find nearby businesses',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      : null,
                  trailing: isSelected
                      ? CustomIconWidget(
                          iconName: 'check_circle',
                          size: 6.w,
                          color: AppTheme.lightTheme.colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    onLocationSelected(location);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
