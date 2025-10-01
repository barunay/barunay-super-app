import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BusinessCardWidget extends StatelessWidget {
  final Map<String, dynamic> business;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onWebsite;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final VoidCallback? onDirections;

  const BusinessCardWidget({
    Key? key,
    required this.business,
    this.onTap,
    this.onCall,
    this.onMessage,
    this.onWebsite,
    this.onFavorite,
    this.onShare,
    this.onDirections,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String businessName = business['name'] ?? 'Unknown Business';
    final String category = business['category'] ?? 'General';
    final double rating = (business['rating'] ?? 0.0).toDouble();
    final String distance = business['distance'] ?? '0 km';
    final bool isOpen = business['isOpen'] ?? false;
    final String description = business['description'] ?? '';
    final String imageUrl = business['imageUrl'] ?? '';
    final bool isFavorite = business['isFavorite'] ?? false;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showQuickActions(context),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Image and Status
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: imageUrl.isNotEmpty
                      ? CustomImageWidget(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 20.h,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: double.infinity,
                          height: 20.h,
                          color: AppTheme
                              .lightTheme.colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: CustomIconWidget(
                              iconName: 'business',
                              size: 8.w,
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                ),
                // Operating Status Badge
                Positioned(
                  top: 2.h,
                  right: 3.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: isOpen
                          ? AppTheme.lightTheme.colorScheme.tertiary
                          : AppTheme.lightTheme.colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOpen ? 'Open' : 'Closed',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Favorite Icon
                Positioned(
                  top: 2.h,
                  left: 3.w,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: CustomIconWidget(
                        iconName: isFavorite ? 'favorite' : 'favorite_border',
                        size: 5.w,
                        color: isFavorite
                            ? AppTheme.lightTheme.colorScheme.error
                            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Business Information
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business Name and Category
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          businessName,
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.lightTheme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 1.h),

                  // Rating and Distance
                  Row(
                    children: [
                      // Rating Stars
                      Row(
                        children: List.generate(5, (index) {
                          return CustomIconWidget(
                            iconName:
                                index < rating.floor() ? 'star' : 'star_border',
                            size: 4.w,
                            color: AppTheme.lightTheme.colorScheme.secondary,
                          );
                        }),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        rating.toStringAsFixed(1),
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      CustomIconWidget(
                        iconName: 'location_on',
                        size: 4.w,
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        distance,
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                      ),
                    ],
                  ),

                  SizedBox(height: 1.h),

                  // Description
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  SizedBox(height: 2.h),

                  // Action Buttons
                  Row(
                    children: [
                      // Call Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCall,
                          icon: CustomIconWidget(
                            iconName: 'phone',
                            size: 4.w,
                            color: AppTheme.lightTheme.colorScheme.primary,
                          ),
                          label: Text(
                            'Call',
                            style: AppTheme.lightTheme.textTheme.labelMedium,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.h),
                          ),
                        ),
                      ),

                      SizedBox(width: 2.w),

                      // Message Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onMessage,
                          icon: CustomIconWidget(
                            iconName: 'message',
                            size: 4.w,
                            color: AppTheme.lightTheme.colorScheme.primary,
                          ),
                          label: Text(
                            'Message',
                            style: AppTheme.lightTheme.textTheme.labelMedium,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.h),
                          ),
                        ),
                      ),

                      SizedBox(width: 2.w),

                      // Website Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onWebsite,
                          child: Text(
                            'Visit',
                            style: AppTheme.lightTheme.textTheme.labelMedium
                                ?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.h),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Quick Actions',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'favorite',
                size: 6.w,
                color: AppTheme.lightTheme.colorScheme.error,
              ),
              title: Text('Save to Favorites'),
              onTap: () {
                Navigator.pop(context);
                onFavorite?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                size: 6.w,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              title: Text('Share Business'),
              onTap: () {
                Navigator.pop(context);
                onShare?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'directions',
                size: 6.w,
                color: AppTheme.lightTheme.colorScheme.tertiary,
              ),
              title: Text('Get Directions'),
              onTap: () {
                Navigator.pop(context);
                onDirections?.call();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
