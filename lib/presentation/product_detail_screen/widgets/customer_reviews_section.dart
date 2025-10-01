import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CustomerReviewsSection extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;
  final double averageRating;
  final Map<int, int> ratingDistribution;
  final VoidCallback onWriteReview;

  const CustomerReviewsSection({
    Key? key,
    required this.reviews,
    required this.averageRating,
    required this.ratingDistribution,
    required this.onWriteReview,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customer Reviews',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: onWriteReview,
                child: Text(
                  'Write Review',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildRatingOverview(),
          SizedBox(height: 3.h),
          _buildRatingDistribution(),
          SizedBox(height: 3.h),
          _buildReviewsList(),
        ],
      ),
    );
  }

  Widget _buildRatingOverview() {
    return Row(
      children: [
        Text(
          averageRating.toStringAsFixed(1),
          style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: 2.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (index) {
                return CustomIconWidget(
                  iconName:
                      index < averageRating.floor() ? 'star' : 'star_border',
                  color: AppTheme.secondaryLight,
                  size: 16,
                );
              }),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Based on ${reviews.length} reviews',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingDistribution() {
    final totalReviews = reviews.length;

    return Column(
      children: List.generate(5, (index) {
        final rating = 5 - index;
        final count = ratingDistribution[rating] ?? 0;
        final percentage = totalReviews > 0 ? count / totalReviews : 0.0;

        return Padding(
          padding: EdgeInsets.only(bottom: 1.h),
          child: Row(
            children: [
              Text(
                '$rating',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
              SizedBox(width: 1.w),
              CustomIconWidget(
                iconName: 'star',
                color: AppTheme.secondaryLight,
                size: 12,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Container(
                  height: 0.8.h,
                  decoration: BoxDecoration(
                    color:
                        AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                '$count',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildReviewsList() {
    if (reviews.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: 'rate_review',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 48,
            ),
            SizedBox(height: 2.h),
            Text(
              'No reviews yet',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Be the first to review this product',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Reviews',
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        ...reviews.take(3).map((review) => _buildReviewItem(review)).toList(),
        if (reviews.length > 3) ...[
          SizedBox(height: 2.h),
          Center(
            child: TextButton(
              onPressed: () {
                // Navigate to all reviews screen
              },
              child: Text(
                'View All Reviews (${reviews.length})',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline,
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: CustomImageWidget(
                    imageUrl: review['userAvatar'] as String? ?? '',
                    width: 10.w,
                    height: 10.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['userName'] as String? ?? 'Anonymous',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            final rating = review['rating'] as int? ?? 0;
                            return CustomIconWidget(
                              iconName: index < rating ? 'star' : 'star_border',
                              color: AppTheme.secondaryLight,
                              size: 14,
                            );
                          }),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          review['date'] as String? ?? '',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Text(
            review['comment'] as String? ?? '',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
