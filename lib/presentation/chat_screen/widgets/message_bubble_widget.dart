import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class MessageBubbleWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isCurrentUser;

  const MessageBubbleWidget({
    Key? key,
    required this.message,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final messageType = message['type'] as String? ?? 'text';
    final timestamp = message['timestamp'] as DateTime?;
    final status = message['status'] as String? ?? 'sent';
    final replyTo = message['replyTo'] as String?;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 4.w,
        vertical: 0.5.h,
      ),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Reply indicator if this is a reply
          if (replyTo != null) _buildReplyIndicator(),

          // Main message bubble
          Row(
            mainAxisAlignment:
                isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              // Sender avatar (for received messages)
              if (!isCurrentUser) _buildAvatar(),

              // Message content
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 70.w,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? AppTheme.lightTheme.primaryColor
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(isCurrentUser ? 18 : 4),
                      bottomRight: Radius.circular(isCurrentUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message content based on type
                      _buildMessageContent(messageType),

                      // Timestamp and status
                      SizedBox(height: 0.5.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(timestamp),
                            style: TextStyle(
                              color: isCurrentUser
                                  ? Colors.white.withAlpha(179)
                                  : Colors.grey.shade600,
                              fontSize: 9.sp,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            SizedBox(width: 1.w),
                            _buildStatusIcon(status),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator() {
    return Container(
      margin: EdgeInsets.only(bottom: 0.5.h),
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: AppTheme.lightTheme.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Text(
        'Replying to message',
        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = message['senderAvatar'] as String? ?? '';

    return Container(
      margin: EdgeInsets.only(right: 2.w),
      child: CircleAvatar(
        radius: 18.sp,
        backgroundColor: Colors.grey.shade300,
        backgroundImage:
            avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
        child: avatarUrl.isEmpty
            ? Icon(
                Icons.person,
                color: Colors.grey.shade600,
                size: 18.sp,
              )
            : null,
      ),
    );
  }

  Widget _buildMessageContent(String messageType) {
    switch (messageType) {
      case 'text':
        return _buildTextContent();
      case 'image':
        return _buildImageContent();
      case 'voice':
        return _buildVoiceContent();
      case 'location':
        return _buildLocationContent();
      case 'document':
        return _buildDocumentContent();
      default:
        return _buildTextContent();
    }
  }

  Widget _buildTextContent() {
    final content = message['content'] as String? ?? '';

    return SelectableText(
      content,
      style: TextStyle(
        color: isCurrentUser ? Colors.white : Colors.black87,
        fontSize: 11.sp,
        height: 1.3,
      ),
    );
  }

  Widget _buildImageContent() {
    final imageUrl = message['content'] as String? ?? '';
    final caption = message['caption'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onTap: () => _showImagePreview(imageUrl),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 60.w,
                height: 30.h,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 60.w,
                  height: 30.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 60.w,
                  height: 30.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.error),
                ),
              ),
            ),
          ),
        if (caption != null && caption.isNotEmpty) ...[
          SizedBox(height: 1.h),
          Text(
            caption,
            style: TextStyle(
              color: isCurrentUser ? Colors.white : Colors.black87,
              fontSize: 10.sp,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVoiceContent() {
    final duration = message['duration'] as String? ?? '0:00';

    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_arrow,
            color:
                isCurrentUser ? Colors.white : AppTheme.lightTheme.primaryColor,
            size: 20.sp,
          ),
          SizedBox(width: 2.w),
          Container(
            width: 30.w,
            height: 3,
            decoration: BoxDecoration(
              color: (isCurrentUser ? Colors.white : Colors.grey.shade400)
                  .withAlpha(128),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 10.w,
                height: 3,
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? Colors.white
                      : AppTheme.lightTheme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            duration,
            style: TextStyle(
              color: isCurrentUser ? Colors.white : Colors.black87,
              fontSize: 9.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationContent() {
    final locationName = message['locationName'] as String? ?? 'Location';
    final address = message['content'] as String? ?? '';

    return GestureDetector(
      onTap: () => _openLocation(address),
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: (isCurrentUser ? Colors.white : Colors.grey.shade100)
              .withAlpha(51),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: isCurrentUser
                      ? Colors.white
                      : AppTheme.lightTheme.primaryColor,
                  size: 16.sp,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    locationName,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black87,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (address.isNotEmpty) ...[
              SizedBox(height: 0.5.h),
              Text(
                address,
                style: TextStyle(
                  color: isCurrentUser
                      ? Colors.white.withAlpha(204)
                      : Colors.grey.shade600,
                  fontSize: 9.sp,
                ),
              ),
            ],
            SizedBox(height: 1.h),
            Container(
              height: 15.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Icon(
                  Icons.map,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentContent() {
    final fileName = message['content']?.split('/').last ?? 'Document';

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color:
            (isCurrentUser ? Colors.white : Colors.grey.shade100).withAlpha(51),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.description,
            color:
                isCurrentUser ? Colors.white : AppTheme.lightTheme.primaryColor,
            size: 20.sp,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black87,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Tap to view',
                  style: TextStyle(
                    color: isCurrentUser
                        ? Colors.white.withAlpha(179)
                        : Colors.grey.shade600,
                    fontSize: 9.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return Icon(
          Icons.check,
          size: 12.sp,
          color: Colors.white.withAlpha(179),
        );
      case 'delivered':
        return Stack(
          children: [
            Icon(
              Icons.check,
              size: 12.sp,
              color: Colors.white.withAlpha(179),
            ),
            Positioned(
              left: 1.w,
              child: Icon(
                Icons.check,
                size: 12.sp,
                color: Colors.white.withAlpha(179),
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
              color: Colors.white,
            ),
            Positioned(
              left: 1.w,
              child: Icon(
                Icons.check,
                size: 12.sp,
                color: Colors.white,
              ),
            ),
          ],
        );
      default:
        return Icon(
          Icons.access_time,
          size: 12.sp,
          color: Colors.white.withAlpha(179),
        );
    }
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showImagePreview(String imageUrl) {
    // Implementation for image preview would go here
    HapticFeedback.lightImpact();
  }

  void _openLocation(String address) {
    // Implementation for opening location in maps would go here
    HapticFeedback.lightImpact();
  }
}
