import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FilterBottomSheetWidget extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersApplied;

  const FilterBottomSheetWidget({
    Key? key,
    required this.currentFilters,
    required this.onFiltersApplied,
  }) : super(key: key);

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late Map<String, dynamic> _filters;

  final List<String> _categories = [
    'All Categories',
    'Restaurants',
    'Retail',
    'Services',
    'Healthcare',
    'Education',
    'Entertainment',
    'Automotive',
    'Beauty & Wellness',
    'Technology',
  ];

  final List<String> _distances = [
    '1 km',
    '5 km',
    '10 km',
    '25 km',
    '50 km',
    'Any distance',
  ];

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
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
                  'Filter Businesses',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: Text(
                    'Clear All',
                    style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppTheme.lightTheme.colorScheme.outline),

          // Filter Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Filter
                  _buildFilterSection(
                    'Category',
                    _buildCategoryFilter(),
                  ),

                  SizedBox(height: 3.h),

                  // Distance Filter
                  _buildFilterSection(
                    'Distance',
                    _buildDistanceFilter(),
                  ),

                  SizedBox(height: 3.h),

                  // Rating Filter
                  _buildFilterSection(
                    'Minimum Rating',
                    _buildRatingFilter(),
                  ),

                  SizedBox(height: 3.h),

                  // Operating Hours Filter
                  _buildFilterSection(
                    'Operating Hours',
                    _buildOperatingHoursFilter(),
                  ),
                ],
              ),
            ),
          ),

          // Apply Button
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline,
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                child: Text(
                  'Apply Filters',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        content,
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: _categories.map((category) {
        final bool isSelected = _filters['category'] == category;
        return GestureDetector(
          onTap: () {
            setState(() {
              _filters['category'] = category;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.outline,
                width: 1,
              ),
            ),
            child: Text(
              category,
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? Colors.white
                    : AppTheme.lightTheme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      children: _distances.map((distance) {
        final bool isSelected = _filters['distance'] == distance;
        return RadioListTile<String>(
          title: Text(
            distance,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          value: distance,
          groupValue: _filters['distance'],
          onChanged: (value) {
            setState(() {
              _filters['distance'] = value;
            });
          },
          activeColor: AppTheme.lightTheme.colorScheme.primary,
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      children: [1, 2, 3, 4, 5].map((rating) {
        final bool isSelected = _filters['minRating'] == rating;
        return RadioListTile<int>(
          title: Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return CustomIconWidget(
                    iconName: index < rating ? 'star' : 'star_border',
                    size: 4.w,
                    color: AppTheme.lightTheme.colorScheme.secondary,
                  );
                }),
              ),
              SizedBox(width: 2.w),
              Text(
                '$rating & above',
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
            ],
          ),
          value: rating,
          groupValue: _filters['minRating'],
          onChanged: (value) {
            setState(() {
              _filters['minRating'] = value;
            });
          },
          activeColor: AppTheme.lightTheme.colorScheme.primary,
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildOperatingHoursFilter() {
    return SwitchListTile(
      title: Text(
        'Open Now',
        style: AppTheme.lightTheme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        'Show only businesses currently open',
        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        ),
      ),
      value: _filters['openNow'] ?? false,
      onChanged: (value) {
        setState(() {
          _filters['openNow'] = value;
        });
      },
      activeColor: AppTheme.lightTheme.colorScheme.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _clearAllFilters() {
    setState(() {
      _filters = {
        'category': 'All Categories',
        'distance': 'Any distance',
        'minRating': null,
        'openNow': false,
      };
    });
  }

  void _applyFilters() {
    widget.onFiltersApplied(_filters);
    Navigator.pop(context);
  }
}
