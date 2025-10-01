import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class NotificationBadgeWidget extends StatelessWidget {
  final int count;
  final IconData icon;
  final VoidCallback onTap;
  final Color? badgeColor;

  const NotificationBadgeWidget({
    Key? key,
    required this.count,
    required this.icon,
    required this.onTap,
    this.badgeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              icon,
              size: 6.w,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          if (count > 0)
            Positioned(
              right: -1.w,
              top: -0.5.h,
              child: Container(
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: badgeColor ?? Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: BoxConstraints(
                  minWidth: 4.w,
                  minHeight: 4.w,
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 9.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
