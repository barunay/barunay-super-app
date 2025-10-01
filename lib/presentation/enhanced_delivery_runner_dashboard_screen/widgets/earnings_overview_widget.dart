import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../theme/app_theme.dart';

class EarningsOverviewWidget extends StatefulWidget {
  final double todayEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final int completedDeliveries;

  const EarningsOverviewWidget({
    Key? key,
    required this.todayEarnings,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.completedDeliveries,
  }) : super(key: key);

  @override
  State<EarningsOverviewWidget> createState() => _EarningsOverviewWidgetState();
}

class _EarningsOverviewWidgetState extends State<EarningsOverviewWidget> {
  String _selectedPeriod = 'Weekly';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Earnings summary cards
          Row(
            children: [
              Expanded(
                child: _buildEarningsCard(
                  'Today',
                  widget.todayEarnings,
                  Icons.today,
                  Colors.blue,
                  '+12%',
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: _buildEarningsCard(
                  'This Week',
                  widget.weeklyEarnings,
                  Icons.date_range,
                  Colors.green,
                  '+8%',
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          Row(
            children: [
              Expanded(
                child: _buildEarningsCard(
                  'This Month',
                  widget.monthlyEarnings,
                  Icons.calendar_month,
                  Colors.purple,
                  '+15%',
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: _buildDeliveriesCard(
                  'Completed',
                  widget.completedDeliveries,
                  Icons.check_circle,
                  Colors.orange,
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Chart section
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Earnings Trend',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedPeriod,
                        items:
                            ['Daily', 'Weekly', 'Monthly'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPeriod = newValue!;
                          });
                        },
                        underline: const SizedBox(),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  SizedBox(
                    height: 30.h,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const style = TextStyle(fontSize: 10);
                                String text;
                                switch (value.toInt()) {
                                  case 0:
                                    text = 'Mon';
                                    break;
                                  case 1:
                                    text = 'Tue';
                                    break;
                                  case 2:
                                    text = 'Wed';
                                    break;
                                  case 3:
                                    text = 'Thu';
                                    break;
                                  case 4:
                                    text = 'Fri';
                                    break;
                                  case 5:
                                    text = 'Sat';
                                    break;
                                  case 6:
                                    text = 'Sun';
                                    break;
                                  default:
                                    text = '';
                                    break;
                                }
                                return Text(text, style: style);
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _getChartData(),
                            isCurved: true,
                            color: AppTheme.lightTheme.primaryColor,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.lightTheme.primaryColor
                                  .withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Performance insights
          _buildPerformanceInsights(),

          SizedBox(height: 3.h),

          // Withdrawal section
          _buildWithdrawalSection(),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(
      String period, double amount, IconData icon, Color color, String change) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 6.w),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    change,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              period,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'B\$${amount.toStringAsFixed(2)}',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveriesCard(
      String label, int count, IconData icon, Color color) {
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
            Icon(icon, color: color, size: 6.w),
            SizedBox(height: 1.h),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              count.toString(),
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getChartData() {
    // Mock data for the week
    return [
      const FlSpot(0, 35),
      const FlSpot(1, 42),
      const FlSpot(2, 28),
      const FlSpot(3, 55),
      const FlSpot(4, 48),
      const FlSpot(5, 62),
      const FlSpot(6, 45),
    ];
  }

  Widget _buildPerformanceInsights() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Insights',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            _buildInsightRow(
              'Best Day',
              'Saturday',
              'B\$62.00',
              Icons.trending_up,
              Colors.green,
            ),
            SizedBox(height: 1.h),
            _buildInsightRow(
              'Peak Hours',
              '5:00 PM - 8:00 PM',
              '40% of earnings',
              Icons.access_time,
              Colors.blue,
            ),
            SizedBox(height: 1.h),
            _buildInsightRow(
              'Average per Delivery',
              'B\$8.35',
              '+5% from last week',
              Icons.attach_money,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(
      String title, String value, String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 5.w),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWithdrawalSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Withdraw Earnings',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Balance',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'B\$${widget.weeklyEarnings.toStringAsFixed(2)}',
                        style:
                            AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handle withdrawal
                    },
                    icon: const Icon(Icons.account_balance),
                    label: const Text('Withdraw'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Withdrawals are processed within 1-3 business days',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
