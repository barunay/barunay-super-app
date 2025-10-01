import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class MessageStatusIndicatorWidget extends StatelessWidget {
  final String status;

  const MessageStatusIndicatorWidget({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 4.w, bottom: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildStatusIcon(),
          SizedBox(width: 1.w),
          Text(
            _getStatusText(),
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontSize: 8.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (status.toLowerCase()) {
      case 'sent':
        return Icon(
          Icons.check,
          size: 12.sp,
          color: Colors.grey.shade600,
        );
      case 'delivered':
        return Stack(
          children: [
            Icon(
              Icons.check,
              size: 12.sp,
              color: Colors.grey.shade600,
            ),
            Positioned(
              left: 2.w,
              child: Icon(
                Icons.check,
                size: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        );
      case 'read':
        return Stack(
          children: [
            Icon(
              Icons.check,
              size: 12.sp,
              color: AppTheme.lightTheme.primaryColor,
            ),
            Positioned(
              left: 2.w,
              child: Icon(
                Icons.check,
                size: 12.sp,
                color: AppTheme.lightTheme.primaryColor,
              ),
            ),
          ],
        );
      default:
        return Icon(
          Icons.access_time,
          size: 12.sp,
          color: Colors.grey.shade600,
        );
    }
  }

  String _getStatusText() {
    switch (status.toLowerCase()) {
      case 'sent':
        return 'Sent';
      case 'delivered':
        return 'Delivered';
      case 'read':
        return 'Read';
      default:
        return 'Sending...';
    }
  }
}
