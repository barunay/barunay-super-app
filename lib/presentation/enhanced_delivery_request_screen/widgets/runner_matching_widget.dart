import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RunnerMatchingWidget extends StatelessWidget {
  final List<Map<String, dynamic>> availableRunners;
  final Function(Map<String, dynamic>) onRunnerSelected;

  const RunnerMatchingWidget({
    Key? key,
    required this.availableRunners,
    required this.onRunnerSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (availableRunners.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Runners Near You',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: ListView.builder(
              itemCount: availableRunners.length,
              itemBuilder: (context, index) {
                final runner = availableRunners[index];
                return _buildRunnerCard(context, runner);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: 'search',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 10.w,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Searching for Runners',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          const Text('We are finding the best runners in your area'),
        ],
      ),
    );
  }

  Widget _buildRunnerCard(BuildContext context, Map<String, dynamic> runner) {
    final userProfile = runner['user_sub_profiles']?['user_profiles'] ?? {};
    final runnerName = userProfile['full_name'] ?? 'Unknown Runner';
    final avatarUrl = userProfile['avatar_url'] ?? '';
    final vehicleType = runner['vehicle_type'] ?? 'Vehicle';
    final rating = (runner['rating_average'] ?? 0.0).toDouble();
    final totalDeliveries = runner['total_deliveries'] ?? 0;
    final estimatedArrival = runner['estimated_arrival'] ?? '10-15 min';
    final proposedFee = (runner['proposed_fee'] ?? 8.0).toDouble();

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            // Runner Info Row
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 6.w,
                  backgroundColor:
                      AppTheme.lightTheme.colorScheme.primaryContainer,
                  backgroundImage:
                      avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child:
                      avatarUrl.isEmpty
                          ? CustomIconWidget(
                            iconName: 'person',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 6.w,
                          )
                          : null,
                ),
                SizedBox(width: 3.w),
                // Runner Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        runnerName,
                        style: AppTheme.lightTheme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'directions_bike',
                            size: 16,
                            color:
                                AppTheme
                                    .lightTheme
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            vehicleType,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                                  color:
                                      AppTheme
                                          .lightTheme
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                          ),
                          SizedBox(width: 3.w),
                          CustomIconWidget(
                            iconName: 'schedule',
                            size: 16,
                            color:
                                AppTheme
                                    .lightTheme
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            estimatedArrival,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                                  color:
                                      AppTheme
                                          .lightTheme
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Rating Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.tertiary.withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CustomIconWidget(
                        iconName: 'star',
                        size: 14,
                        color: Colors.amber,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        rating.toStringAsFixed(1),
                        style: AppTheme.lightTheme.textTheme.labelSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Deliveries', '$totalDeliveries'),
                _buildStatItem('Acceptance', '98%'),
                _buildStatItem('On Time', '99%'),
                _buildStatItem('Fee', 'B\$${proposedFee.toStringAsFixed(2)}'),
              ],
            ),

            SizedBox(height: 2.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRunnerDetails(context, runner),
                    child: const Text('View Profile'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _requestRunner(context, runner),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Request Delivery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.primary,
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

  void _showRunnerDetails(BuildContext context, Map<String, dynamic> runner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildRunnerDetailsSheet(context, runner),
    );
  }

  Widget _buildRunnerDetailsSheet(
    BuildContext context,
    Map<String, dynamic> runner,
  ) {
    final userProfile = runner['user_sub_profiles']?['user_profiles'] ?? {};
    final runnerName = userProfile['full_name'] ?? 'Unknown Runner';
    final phone = userProfile['phone'] ?? '';

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(1.w),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            runnerName,
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          if (phone.isNotEmpty) ...[
            Row(
              children: [
                const CustomIconWidget(iconName: 'phone', size: 20),
                SizedBox(width: 3.w),
                Text(phone),
              ],
            ),
            SizedBox(height: 2.h),
          ],
          const Text('Recent Reviews:'),
          SizedBox(height: 1.h),
          _buildReviewItem('⭐⭐⭐⭐⭐', 'Fast and reliable service!'),
          _buildReviewItem('⭐⭐⭐⭐⭐', 'Very professional runner.'),
          _buildReviewItem('⭐⭐⭐⭐', 'Good communication throughout.'),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _requestRunner(context, runner);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Request Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String rating, String review) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Text(rating, style: const TextStyle(fontSize: 12)),
          SizedBox(width: 2.w),
          Expanded(child: Text(review, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  void _requestRunner(BuildContext context, Map<String, dynamic> runner) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Request'),
            content: const Text('Send delivery request to this runner?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Delivery request sent!')),
                  );
                  onRunnerSelected(runner);
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
  }
}
