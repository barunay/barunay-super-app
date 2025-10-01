import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class InventoryStatsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final Map<String, dynamic> sellerProfile;

  const InventoryStatsWidget({
    Key? key,
    required this.products,
    required this.sellerProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        products.where((p) => p['listing_status'] == 'pending').length;
    final approvedCount =
        products.where((p) => p['listing_status'] == 'approved').length;
    final rejectedCount =
        products.where((p) => p['listing_status'] == 'rejected').length;
    final totalViews = products.fold(
      0,
      (sum, p) => sum + ((p['view_count'] ?? 0) as int),
    );
    final totalFavorites = products.fold(
      0,
      (sum, p) => sum + ((p['favorite_count'] ?? 0) as int),
    );

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
              alpha: 0.1,
            ),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Overview',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 3.h),

          // Top Row Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Products',
                  '${products.length}',
                  'inventory_2',
                  AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  'Approved',
                  '$approvedCount',
                  'verified',
                  Colors.green,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Bottom Row Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pending Review',
                  '$pendingCount',
                  'pending',
                  Colors.orange,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  'Total Views',
                  '$totalViews',
                  'visibility',
                  Colors.blue,
                ),
              ),
            ],
          ),

          if (rejectedCount > 0) ...[
            SizedBox(height: 2.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'warning',
                    color: AppTheme.lightTheme.colorScheme.error,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '$rejectedCount product(s) need attention',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 3.h),

          // Performance Metrics
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem('❤️', '$totalFavorites', 'Favorites'),
                _buildMetricItem('👁️', '$totalViews', 'Views'),
                _buildMetricItem('⭐', '4.5', 'Rating'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String iconName,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(iconName: iconName, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}