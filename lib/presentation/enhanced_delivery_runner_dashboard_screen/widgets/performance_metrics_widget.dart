import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../theme/app_theme.dart';

class PerformanceMetricsWidget extends StatefulWidget {
  final double averageRating;
  final double completionRate;
  final String responseTime;
  final int totalDeliveries;

  const PerformanceMetricsWidget({
    Key? key,
    required this.averageRating,
    required this.completionRate,
    required this.responseTime,
    required this.totalDeliveries,
  }) : super(key: key);

  @override
  State<PerformanceMetricsWidget> createState() =>
      _PerformanceMetricsWidgetState();
}

class _PerformanceMetricsWidgetState extends State<PerformanceMetricsWidget> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance overview cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Average Rating',
                  widget.averageRating.toString(),
                  Icons.star,
                  Colors.amber,
                  '${widget.averageRating}/5.0',
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: _buildMetricCard(
                  'Completion Rate',
                  '${widget.completionRate.toStringAsFixed(1)}%',
                  Icons.check_circle,
                  Colors.green,
                  'Excellent',
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Response Time',
                  widget.responseTime,
                  Icons.timer,
                  Colors.blue,
                  'Fast',
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: _buildMetricCard(
                  'Total Deliveries',
                  widget.totalDeliveries.toString(),
                  Icons.local_shipping,
                  Colors.purple,
                  'Experienced',
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Rating breakdown chart
          _buildRatingBreakdownChart(),

          SizedBox(height: 3.h),

          // Performance trends
          _buildPerformanceTrends(),

          SizedBox(height: 3.h),

          // Achievement badges
          _buildAchievementBadges(),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 7.w),
            SizedBox(height: 1.h),
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBreakdownChart() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rating Breakdown',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 25.h,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 60,
                      color: Colors.amber,
                      title: '5★\n60%',
                      radius: 15.w,
                      titleStyle:
                          AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    PieChartSectionData(
                      value: 25,
                      color: Colors.orange,
                      title: '4★\n25%',
                      radius: 13.w,
                      titleStyle:
                          AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    PieChartSectionData(
                      value: 10,
                      color: Colors.yellow,
                      title: '3★\n10%',
                      radius: 11.w,
                      titleStyle:
                          AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    PieChartSectionData(
                      value: 3,
                      color: Colors.grey,
                      title: '2★\n3%',
                      radius: 9.w,
                      titleStyle:
                          AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    PieChartSectionData(
                      value: 2,
                      color: Colors.red,
                      title: '1★\n2%',
                      radius: 7.w,
                      titleStyle:
                          AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 0,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTrends() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trends',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            _buildTrendItem(
              'Rating Trend',
              'Increasing',
              Icons.trending_up,
              Colors.green,
              '+0.2 this month',
            ),
            SizedBox(height: 1.h),
            _buildTrendItem(
              'Response Time',
              'Improving',
              Icons.trending_up,
              Colors.green,
              '-30 seconds',
            ),
            SizedBox(height: 1.h),
            _buildTrendItem(
              'Completion Rate',
              'Stable',
              Icons.trending_flat,
              Colors.blue,
              '98.5% maintained',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(
      String title, String status, IconData icon, Color color, String detail) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 5.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  detail,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadges() {
    final achievements = [
      {
        'title': 'Top Rated Runner',
        'description': '4.8+ rating',
        'icon': Icons.star,
        'color': Colors.amber,
        'earned': true,
      },
      {
        'title': 'Speed Demon',
        'description': 'Fast deliveries',
        'icon': Icons.flash_on,
        'color': Colors.orange,
        'earned': true,
      },
      {
        'title': 'Reliable Partner',
        'description': '95%+ completion',
        'icon': Icons.verified,
        'color': Colors.green,
        'earned': true,
      },
      {
        'title': 'Distance King',
        'description': '1000+ km traveled',
        'icon': Icons.directions_run,
        'color': Colors.blue,
        'earned': false,
      },
    ];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievement Badges',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 2.w,
                mainAxisSpacing: 2.w,
                childAspectRatio: 2.5,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                final earned = achievement['earned'] as bool;
                final color = achievement['color'] as Color;

                return Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: earned
                        ? color.withValues(alpha: 0.1)
                        : AppTheme
                            .lightTheme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: earned
                          ? color.withValues(alpha: 0.3)
                          : AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        achievement['icon'] as IconData,
                        color: earned
                            ? color
                            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 6.w,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              achievement['title'] as String,
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: earned
                                    ? color
                                    : AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              achievement['description'] as String,
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: earned
                                    ? color.withValues(alpha: 0.8)
                                    : AppTheme
                                        .lightTheme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
