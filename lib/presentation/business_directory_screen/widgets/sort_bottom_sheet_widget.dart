import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SortBottomSheetWidget extends StatelessWidget {
  final String currentSort;
  final Function(String) onSortSelected;

  const SortBottomSheetWidget({
    Key? key,
    required this.currentSort,
    required this.onSortSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> sortOptions = [
      {
        'key': 'distance',
        'title': 'Distance',
        'subtitle': 'Nearest first',
        'icon': 'location_on',
      },
      {
        'key': 'rating',
        'title': 'Rating',
        'subtitle': 'Highest rated first',
        'icon': 'star',
      },
      {
        'key': 'newest',
        'title': 'Newest',
        'subtitle': 'Recently added businesses',
        'icon': 'schedule',
      },
      {
        'key': 'alphabetical',
        'title': 'Alphabetical',
        'subtitle': 'A to Z',
        'icon': 'sort_by_alpha',
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  'Sort By',
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

          // Sort Options
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: 2.h),
            itemCount: sortOptions.length,
            itemBuilder: (context, index) {
              final option = sortOptions[index];
              final bool isSelected = currentSort == option['key'];

              return ListTile(
                leading: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primaryContainer
                        : AppTheme
                            .lightTheme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: option['icon'],
                    size: 5.w,
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.onPrimaryContainer
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                title: Text(
                  option['title'],
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  option['subtitle'],
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: isSelected
                    ? CustomIconWidget(
                        iconName: 'check_circle',
                        size: 6.w,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  onSortSelected(option['key']);
                  Navigator.pop(context);
                },
              );
            },
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}
