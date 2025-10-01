import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';


class AnalyticsDashboardWidget extends StatelessWidget {
  final Map<String, dynamic> analytics;

  const AnalyticsDashboardWidget({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview Cards
        _buildSectionTitle('Overview'),
        SizedBox(height: 12.h),
        _buildOverviewGrid(),

        SizedBox(height: 24.h),

        // Product Status Breakdown
        _buildSectionTitle('Product Status'),
        SizedBox(height: 12.h),
        _buildStatusCards(),

        SizedBox(height: 24.h),

        // Performance Metrics
        _buildSectionTitle('Performance'),
        SizedBox(height: 12.h),
        _buildPerformanceCards(),

        SizedBox(height: 24.h),

        // Recent Reviews
        if (analytics['recent_reviews'] != null &&
            (analytics['recent_reviews'] as List).isNotEmpty) ...[
          _buildSectionTitle('Recent Reviews'),
          SizedBox(height: 12.h),
          _buildRecentReviews(),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildOverviewGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Total Products',
          '${analytics['total_products'] ?? 0}',
          Icons.inventory,
          Colors.blue,
        ),
        _buildMetricCard(
          'Active Products',
          '${analytics['active_products'] ?? 0}',
          Icons.store,
          Colors.green,
        ),
        _buildMetricCard(
          'Total Views',
          '${analytics['total_views'] ?? 0}',
          Icons.visibility,
          Colors.orange,
        ),
        _buildMetricCard(
          'Total Favorites',
          '${analytics['total_favorites'] ?? 0}',
          Icons.favorite,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24.sp),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16.sp),
                ),
              ],
            ),

            Spacer(),

            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),

            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCards() {
    final statusData = [
      {
        'title': 'Under Review',
        'count': analytics['under_review'] ?? 0,
        'color': Colors.orange,
        'icon': Icons.schedule,
        'description': 'Awaiting admin approval',
      },
      {
        'title': 'Approved',
        'count': analytics['approved'] ?? 0,
        'color': Colors.green,
        'icon': Icons.check_circle,
        'description': 'Live in marketplace',
      },
      {
        'title': 'Rejected',
        'count': analytics['rejected'] ?? 0,
        'color': Colors.red,
        'icon': Icons.cancel,
        'description': 'Need modifications',
      },
    ];

    return Column(
      children:
          statusData.map((status) {
            return Card(
              margin: EdgeInsets.only(bottom: 8.h),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: (status['color'] as Color).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    status['icon'] as IconData,
                    color: status['color'] as Color,
                    size: 20.sp,
                  ),
                ),
                title: Text(
                  status['title'] as String,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  status['description'] as String,
                  style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: (status['color'] as Color).withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${status['count']}',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: status['color'] as Color,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildPerformanceCards() {
    final totalViews = analytics['total_views'] ?? 0;
    final totalFavorites = analytics['total_favorites'] ?? 0;
    final totalProducts =
        analytics['total_products'] ?? 1; // Avoid division by zero

    final avgViews = (totalViews / totalProducts).round();
    final avgFavorites = (totalFavorites / totalProducts).round();

    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Icon(Icons.trending_up, color: Colors.blue, size: 32.sp),
                  SizedBox(height: 8.h),
                  Text(
                    '$avgViews',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'Avg Views per Product',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(width: 12.w),

        Expanded(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Icon(Icons.favorite, color: Colors.red, size: 32.sp),
                  SizedBox(height: 8.h),
                  Text(
                    '$avgFavorites',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    'Avg Favorites per Product',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReviews() {
    final reviews = analytics['recent_reviews'] as List<dynamic>;

    return Column(
      children:
          reviews.take(3).map<Widget>((review) {
            return Card(
              margin: EdgeInsets.only(bottom: 8.h),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (review['reviewer']['full_name'] as String)[0]
                        .toUpperCase(),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        review['product']['title'] as String,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < (review['rating'] as int)
                              ? Icons.star
                              : Icons.star_border,
                          size: 16.sp,
                          color: Colors.amber,
                        );
                      }),
                    ),
                  ],
                ),
                subtitle: Text(
                  review['review_text'] as String? ?? 'No comment',
                  style: GoogleFonts.inter(fontSize: 12.sp),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
    );
  }
}