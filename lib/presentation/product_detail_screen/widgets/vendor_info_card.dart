import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/seller_service.dart';
import '../../../widgets/seller_verification_badge_widget.dart';

class VendorInfoCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onViewShop;

  const VendorInfoCard({
    Key? key,
    required this.product,
    this.onViewShop,
  }) : super(key: key);

  @override
  State<VendorInfoCard> createState() => _VendorInfoCardState();
}

class _VendorInfoCardState extends State<VendorInfoCard> {
  final SellerService _sellerService = SellerService();
  Map<String, dynamic>? sellerProfile;
  Map<String, dynamic> badgeData = {};

  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
  }

  Future<void> _loadSellerProfile() async {
    final sellerId = widget.product['seller_id'] as String?;
    if (sellerId != null) {
      final profile = await _sellerService.getSellerProfile();
      if (profile != null) {
        setState(() {
          sellerProfile = profile;
          badgeData = _sellerService.getSellerBadgeData(profile);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final seller = widget.product['seller_profiles'] ?? {};
    final businessName = seller['business_name'] ?? 'Unknown Seller';
    final businessAddress =
        seller['business_address'] ?? 'Location not specified';

    return GestureDetector(
      onTap: widget.onViewShop,
      child: Container(
        padding: EdgeInsets.all(4.w),
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.shadowColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Store logo placeholder
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'store',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 6.w,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              businessName,
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          // Verification badge
                          if (badgeData.isNotEmpty)
                            SellerVerificationBadgeWidget(
                              badgeData: badgeData,
                              isCompact: true,
                            ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'location_on',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 4.w,
                          ),
                          SizedBox(width: 1.w),
                          Flexible(
                            child: Text(
                              businessAddress,
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                CustomIconWidget(
                  iconName: 'chevron_right',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 5.w,
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Store stats
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: 'star',
                    label: 'Rating',
                    value: '4.8',
                    color: Colors.amber,
                  ),
                ),
                Container(
                  width: 1,
                  height: 4.h,
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: 'inventory',
                    label: 'Products',
                    value: '156',
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
                Container(
                  width: 1,
                  height: 4.h,
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: 'schedule',
                    label: 'Response',
                    value: '< 1hr',
                    color: AppTheme.lightTheme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: color,
          size: 5.w,
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
