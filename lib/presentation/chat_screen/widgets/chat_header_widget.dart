import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ChatHeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final Map<String, dynamic> participant;
  final bool isOnline;
  final bool isTyping;
  final VoidCallback? onBackPressed;
  final VoidCallback? onCallPressed;
  final VoidCallback? onVideoCallPressed;
  final VoidCallback? onMorePressed;

  const ChatHeaderWidget({
    Key? key,
    required this.participant,
    this.isOnline = false,
    this.isTyping = false,
    this.onBackPressed,
    this.onCallPressed,
    this.onVideoCallPressed,
    this.onMorePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      elevation: 1,
      shadowColor: AppTheme.lightTheme.colorScheme.shadow,
      leading: IconButton(
        onPressed: onBackPressed ?? () => Navigator.pop(context),
        icon: CustomIconWidget(
          iconName: 'arrow_back',
          color: AppTheme.lightTheme.colorScheme.onSurface,
          size: 6.w,
        ),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 5.w,
                backgroundColor: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                child: ClipOval(
                  child: CustomImageWidget(
                    imageUrl: (participant['avatar'] as String?) ??
                        'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png',
                    width: 10.w,
                    height: 10.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 3.w,
                    height: 3.w,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.tertiary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.lightTheme.scaffoldBackgroundColor,
                        width: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (participant['name'] as String?) ?? 'Unknown User',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  isTyping
                      ? 'Typing...'
                      : isOnline
                          ? 'Online'
                          : _getLastSeenText(),
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: isTyping
                        ? AppTheme.lightTheme.colorScheme.primary
                        : isOnline
                            ? AppTheme.lightTheme.colorScheme.tertiary
                            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (onCallPressed != null)
          IconButton(
            onPressed: onCallPressed,
            icon: CustomIconWidget(
              iconName: 'call',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 5.w,
            ),
          ),
        if (onVideoCallPressed != null)
          IconButton(
            onPressed: onVideoCallPressed,
            icon: CustomIconWidget(
              iconName: 'videocam',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 5.w,
            ),
          ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuSelection(context, value),
          icon: CustomIconWidget(
            iconName: 'more_vert',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 5.w,
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'search',
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'search',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 4.w,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Search Messages',
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'mute',
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'notifications_off',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 4.w,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Mute Notifications',
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'block',
                    color: AppTheme.lightTheme.colorScheme.error,
                    size: 4.w,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Block User',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'report',
                    color: AppTheme.lightTheme.colorScheme.error,
                    size: 4.w,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Report User',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getLastSeenText() {
    final lastSeen = participant['lastSeen'] as DateTime?;
    if (lastSeen == null) return 'Last seen recently';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inDays > 0) {
      return 'Last seen ${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return 'Last seen ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return 'Last seen ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Last seen just now';
    }
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'search':
        _showSearchDialog(context);
        break;
      case 'mute':
        _showMuteDialog(context);
        break;
      case 'block':
        _showBlockDialog(context);
        break;
      case 'report':
        _showReportDialog(context);
        break;
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Search Messages',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Search in conversation...',
            prefixIcon: CustomIconWidget(
              iconName: 'search',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showMuteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Mute Notifications',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        content: Text(
          'You won\'t receive notifications for messages from this chat.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Mute'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Block User',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.lightTheme.colorScheme.error,
          ),
        ),
        content: Text(
          'Are you sure you want to block this user? They won\'t be able to send you messages.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Block',
              style: TextStyle(color: AppTheme.lightTheme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Report User',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.lightTheme.colorScheme.error,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why are you reporting this user?',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            ...['Spam', 'Harassment', 'Inappropriate content', 'Fraud', 'Other']
                .map(
              (reason) => RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: null,
                onChanged: (value) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Report',
              style: TextStyle(color: AppTheme.lightTheme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
