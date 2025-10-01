import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';

class ProductCardWidget extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onToggleStatus;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrls = (product['image_urls'] as List<dynamic>?) ?? [];
    final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : '';

    final listingStatus = product['listing_status'] ?? 'draft';
    final productStatus = product['status'] ?? 'inactive';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.productDetailScreen,
            arguments: product['id'],
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with status badges
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child:
                          imageUrl.isNotEmpty
                              ? CustomImageWidget(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                height: double.infinity,
                              )
                              : Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 12.w,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                    ),
                  ),

                  // Status badges
                  Positioned(
                    top: 2.w,
                    left: 2.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Listing status badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getListingStatusColor(listingStatus),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getListingStatusText(listingStatus),
                            style: GoogleFonts.inter(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Product status badge if different from active
                        if (productStatus != 'active') ...[
                          SizedBox(height: 0.5.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: _getProductStatusColor(productStatus),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              productStatus.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Actions menu
                  Positioned(
                    top: 2.w,
                    right: 2.w,
                    child: _buildActionMenu(context),
                  ),
                ],
              ),
            ),

            // Product details
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['title'] ?? 'Untitled Product',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),

                    Text(
                      'B\$${product['price']?.toString() ?? '0.00'}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryLight,
                      ),
                    ),

                    const Spacer(),

                    // Stats row
                    Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 3.w,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 0.5.w),
                        Text(
                          '${product['view_count'] ?? 0}',
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Icon(
                          Icons.favorite,
                          size: 3.w,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 0.5.w),
                        Text(
                          '${product['favorite_count'] ?? 0}',
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(product['updated_at']),
                          style: GoogleFonts.inter(
                            fontSize: 8.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: EdgeInsets.all(1.w),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(230),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.more_vert, size: 4.w, color: Colors.grey.shade700),
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            // Navigate to edit screen with product ID
            AppRoutes.navigateToEditProductListing(
              context,
              productId: product['id'] as String,
            );
            break;
          case 'delete':
            onDelete();
            break;
          case 'toggle_status':
            onToggleStatus?.call();
            break;
        }
      },
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 4.w),
                  SizedBox(width: 2.w),
                  const Text('Edit'),
                ],
              ),
            ),
            if (onToggleStatus != null)
              PopupMenuItem(
                value: 'toggle_status',
                child: Row(
                  children: [
                    Icon(
                      product['status'] == 'active'
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      product['status'] == 'active' ? 'Deactivate' : 'Activate',
                    ),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 4.w, color: Colors.red),
                  SizedBox(width: 2.w),
                  const Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
    );
  }

  Color _getListingStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'under_review':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getListingStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'LIVE';
      case 'under_review':
        return 'REVIEW';
      case 'rejected':
        return 'REJECTED';
      case 'draft':
        return 'DRAFT';
      default:
        return status.toUpperCase();
    }
  }

  Color _getProductStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'sold':
        return Colors.blue;
      case 'reserved':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return '${date.day}/${date.month}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else {
        return 'Now';
      }
    } catch (e) {
      return '';
    }
  }
}
