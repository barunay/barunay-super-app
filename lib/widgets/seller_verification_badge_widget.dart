import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';

class SellerVerificationBadgeWidget extends StatelessWidget {
  final Map<String, dynamic> badgeData;
  final bool isCompact;

  const SellerVerificationBadgeWidget({
    Key? key,
    required this.badgeData,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (badgeData['show_badge'] != true) {
      return const SizedBox.shrink();
    }

    final badgeColor = badgeData['badge_color'] as String;
    final badgeText = badgeData['badge_text'] as String;
    final badgeIcon = badgeData['badge_icon'] as String;
    final tooltip = badgeData['tooltip'] as String;

    Color backgroundColor;
    Color textColor;
    Color iconColor;

    switch (badgeColor) {
      case 'verified':
        backgroundColor =
            AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.1);
        textColor = AppTheme.lightTheme.colorScheme.tertiary;
        iconColor = AppTheme.lightTheme.colorScheme.tertiary;
        break;
      case 'pending':
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange.shade700;
        iconColor = Colors.orange.shade700;
        break;
      case 'not_verified':
      default:
        backgroundColor =
            AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1);
        textColor = AppTheme.lightTheme.colorScheme.outline;
        iconColor = AppTheme.lightTheme.colorScheme.outline;
        break;
    }

    Widget badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 2.w : 3.w,
        vertical: isCompact ? 0.5.h : 1.h,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: badgeIcon,
            color: iconColor,
            size: isCompact ? 3.w : 4.w,
          ),
          if (!isCompact) ...[
            SizedBox(width: 1.w),
            Text(
              badgeText,
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 8.sp : 10.sp,
              ),
            ),
          ],
        ],
      ),
    );

    return Tooltip(
      message: tooltip,
      child: badge,
    );
  }
}
