import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_image_widget.dart';

class EditProductPreviewWidget extends StatelessWidget {
  final String title;
  final String description;
  final double price;
  final double? originalPrice;
  final String condition;
  final String location;
  final bool isNegotiable;
  final List<String> tags;
  final List<String> imageUrls;
  final String category;
  final Map<String, dynamic> changedFields;

  const EditProductPreviewWidget({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.condition,
    required this.location,
    required this.isNegotiable,
    required this.tags,
    required this.imageUrls,
    required this.category,
    required this.changedFields,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview Your Updated Listing',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),

          // Changed fields indicator
          if (changedFields.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: Colors.orange.shade700,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Changes will trigger review',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Modified: ${changedFields.keys.join(', ')}',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
          ],

          // Product preview card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Images
                if (imageUrls.isNotEmpty) ...[
                  Container(
                    height: 50.w,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: CustomImageWidget(
                        imageUrl: imageUrls.first,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (imageUrls.length > 1)
                    Container(
                      height: 15.w,
                      padding: EdgeInsets.all(2.w),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageUrls.length - 1,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 12.w,
                            height: 12.w,
                            margin: EdgeInsets.only(right: 1.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CustomImageWidget(
                                imageUrl: imageUrls[index + 1],
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],

                // Content
                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title.isEmpty ? 'Product Title' : title,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color:
                              title.isEmpty
                                  ? Colors.grey.shade400
                                  : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 1.h),

                      // Category
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),

                      // Price
                      Row(
                        children: [
                          Text(
                            'B\$${price.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          if (originalPrice != null &&
                              originalPrice! > price) ...[
                            SizedBox(width: 2.w),
                            Text(
                              'B\$${originalPrice!.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (isNegotiable)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Negotiable',
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 2.h),

                      // Condition
                      Row(
                        children: [
                          Text(
                            'Condition: ',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            _formatCondition(condition),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: _getConditionColor(condition),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),

                      // Location
                      if (location.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 4.w,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: 1.w),
                            Expanded(
                              child: Text(
                                location,
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 2.h),

                      // Description
                      Text(
                        'Description',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        description.isEmpty
                            ? 'Product description...'
                            : description,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color:
                              description.isEmpty
                                  ? Colors.grey.shade400
                                  : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 2.h),

                      // Tags
                      if (tags.isNotEmpty) ...[
                        Text(
                          'Tags',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Wrap(
                          spacing: 1.w,
                          runSpacing: 0.5.h,
                          children:
                              tags.map((tag) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 2.w,
                                    vertical: 0.5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    tag,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // Review notice
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 8.w,
                  color: Colors.blue.shade700,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Your updated listing will be reviewed',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),
                Text(
                  'After updating, your listing will go through admin review again. This usually takes 1-2 business days.',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.blue.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCondition(String condition) {
    switch (condition) {
      case 'like_new':
        return 'Like New';
      case 'new':
      case 'good':
      case 'fair':
      case 'poor':
        return condition.substring(0, 1).toUpperCase() + condition.substring(1);
      default:
        return 'Unknown';
    }
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'new':
        return Colors.green;
      case 'like_new':
        return Colors.blue;
      case 'good':
        return Colors.orange;
      case 'fair':
        return Colors.yellow.shade700;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
