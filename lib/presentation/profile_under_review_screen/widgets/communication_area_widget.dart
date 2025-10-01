import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class CommunicationAreaWidget extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final Function(String) onSendMessage;

  const CommunicationAreaWidget({
    super.key,
    required this.messages,
    required this.onSendMessage,
  });

  @override
  State<CommunicationAreaWidget> createState() =>
      _CommunicationAreaWidgetState();
}

class _CommunicationAreaWidgetState extends State<CommunicationAreaWidget> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat,
                color: Colors.blue,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Communication',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Messages list
          Container(
            height: 25.h,
            child: widget.messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 14.sp,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      final message = widget.messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),

          SizedBox(height: 2.h),

          // Message input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                  ),
                  maxLines: null,
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? SizedBox(
                          width: 5.w,
                          height: 5.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 6.w,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isFromAdmin = message['isFromAdmin'] as bool;
    final messageText = message['message'] as String;
    final timestamp = message['timestamp'] as DateTime;

    return Align(
      alignment: isFromAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        constraints: BoxConstraints(maxWidth: 75.w),
        child: Column(
          crossAxisAlignment:
              isFromAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isFromAdmin
                    ? Colors.grey.shade200
                    : Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isFromAdmin ? Radius.zero : Radius.circular(16),
                  bottomRight: isFromAdmin ? Radius.circular(16) : Radius.zero,
                ),
              ),
              child: Text(
                messageText,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: isFromAdmin ? Colors.black87 : Colors.white,
                ),
              ),
            ),
            SizedBox(height: 0.5.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFromAdmin) ...[
                  Icon(
                    Icons.admin_panel_settings,
                    size: 3.w,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'Admin',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 2.w),
                ],
                Text(
                  _formatTimestamp(timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      await widget.onSendMessage(_messageController.text.trim());
      _messageController.clear();
    } finally {
      setState(() => _isSending = false);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }
}
