import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class ChangeTrackingWidget extends StatelessWidget {
  final Map<String, dynamic> changedFields;

  const ChangeTrackingWidget({super.key, required this.changedFields});

  @override
  Widget build(BuildContext context) {
    if (changedFields.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: Colors.amber.shade700, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Changes Detected',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade700,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            '${changedFields.length} field${changedFields.length > 1 ? 's' : ''} modified',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.amber.shade600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Wrap(
            spacing: 1.w,
            runSpacing: 0.5.h,
            children:
                changedFields.keys.map((field) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 1.5.w,
                      vertical: 0.3.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getFieldDisplayName(field),
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  String _getFieldDisplayName(String field) {
    switch (field) {
      case 'title':
        return 'Title';
      case 'description':
        return 'Description';
      case 'price':
        return 'Price';
      case 'original_price':
        return 'Original Price';
      case 'location':
        return 'Location';
      case 'category_id':
        return 'Category';
      case 'brand_id':
        return 'Brand';
      case 'condition':
        return 'Condition';
      case 'is_negotiable':
        return 'Negotiable';
      case 'tags':
        return 'Tags';
      case 'specifications':
        return 'Specifications';
      case 'shipping_info':
        return 'Shipping';
      default:
        return field;
    }
  }
}
