import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class FilterChipsWidget extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final Map<String, dynamic> analytics;

  const FilterChipsWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    final themePrimary = Theme.of(context).primaryColor;

    final filters = [
      {
        'key': 'all',
        'label': 'All',
        'count': analytics['total_products'] ?? 0,
        'color': themePrimary,
        'icon': Icons.inventory_2_rounded,
      },
      {
        'key': 'active',
        'label': 'Live',
        'count': analytics['approved'] ?? 0,
        'color': Colors.green,
        'icon': Icons.check_circle_rounded,
      },
      {
        'key': 'under_review',
        'label': 'Review',
        'count': analytics['under_review'] ?? 0,
        'color': Colors.orange,
        'icon': Icons.schedule_rounded,
      },
      {
        'key': 'rejected',
        'label': 'Rejected',
        'count': analytics['rejected'] ?? 0,
        'color': Colors.red,
        'icon': Icons.cancel_rounded,
      },
      {
        'key': 'draft',
        'label': 'Draft',
        'count': (analytics['total_products'] ?? 0) -
            (analytics['approved'] ?? 0) -
            (analytics['under_review'] ?? 0) -
            (analytics['rejected'] ?? 0),
        'color': Colors.grey,
        'icon': Icons.edit_rounded,
      },
    ];

    return SizedBox(
      height: 5.6.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        itemCount: filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 2.w),
        itemBuilder: (context, i) {
          final f = filters[i];
          final isSelected = selectedFilter == f['key'];
          final color = f['color'] as Color;

          return ChoiceChip(
            selected: isSelected,
            onSelected: (_) => onFilterChanged(f['key'] as String),
            labelPadding: EdgeInsets.symmetric(horizontal: 2.8.w, vertical: 0.2.h),
            backgroundColor: Colors.white,
            selectedColor: color.withOpacity(0.12),
            side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  f['icon'] as IconData,
                  size: 12.sp,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
                SizedBox(width: 1.2.w),
                Text(
                  f['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : Colors.grey.shade800,
                  ),
                ),
                SizedBox(width: 1.2.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 1.6.w, vertical: 0.2.h),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${f['count']}',
                    style: GoogleFonts.inter(
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
