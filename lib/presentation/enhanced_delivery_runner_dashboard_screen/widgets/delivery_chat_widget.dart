import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class DeliveryChatWidget extends StatefulWidget {
  final String deliveryId;
  final String customerName;

  const DeliveryChatWidget({
    Key? key,
    required this.deliveryId,
    required this.customerName,
  }) : super(key: key);

  @override
  State<DeliveryChatWidget> createState() => _DeliveryChatWidgetState();
}

class _DeliveryChatWidgetState extends State<DeliveryChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      'id': '1',
      'message':
          'Hi! I\'m on my way to pick up your medicine from RIPAS Hospital.',
      'senderId': 'runner',
      'senderName': 'Ahmad (Runner)',
      'timestamp': '2 mins ago',
      'type': 'text',
    },
    {
      'id': '2',
      'message':
          'Thank you! Please be careful with the package as it contains temperature-sensitive medication.',
      'senderId': 'customer',
      'senderName': 'Haji Ahmad',
      'timestamp': '1 min ago',
      'type': 'text',
    },
    {
      'id': '3',
      'message':
          'Understood! I have a cooler bag for temperature-sensitive items. ETA is about 10 minutes.',
      'senderId': 'runner',
      'senderName': 'Ahmad (Runner)',
      'timestamp': 'just now',
      'type': 'text',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'message': _messageController.text.trim(),
        'senderId': 'runner',
        'senderName': 'Ahmad (Runner)',
        'timestamp': 'just now',
        'type': 'text',
      });
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.lightTheme.primaryColor,
                  child: Text(
                    widget.customerName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat with ${widget.customerName}',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 2.w,
                            height: 2.w,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'Online',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/chat-screen', arguments: {
                      'deliveryId': widget.deliveryId,
                      'customerName': widget.customerName,
                    });
                  },
                  icon: const Icon(Icons.fullscreen),
                ),
              ],
            ),
          ),

          // Messages
          Container(
            height: 30.h,
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(2.w),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isRunner = message['senderId'] == 'runner';

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 0.5.h),
                  child: Row(
                    mainAxisAlignment: isRunner
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!isRunner) ...[
                        CircleAvatar(
                          radius: 2.5.w,
                          backgroundColor: Colors.blue,
                          child: Text(
                            widget.customerName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                      ],
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: isRunner
                                ? AppTheme.lightTheme.primaryColor
                                : AppTheme.lightTheme.colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['message'],
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: isRunner ? Colors.white : null,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                message['timestamp'],
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: isRunner
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isRunner) ...[
                        SizedBox(width: 2.w),
                        CircleAvatar(
                          radius: 2.5.w,
                          backgroundColor: AppTheme.lightTheme.primaryColor,
                          child: Text(
                            'A',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Input area
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(
                top: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme
                          .lightTheme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 2.h,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Handle attachment
                          },
                          icon: CustomIconWidget(
                            iconName: 'attach_file',
                            size: 5.w,
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                FloatingActionButton.small(
                  onPressed: _sendMessage,
                  backgroundColor: AppTheme.lightTheme.primaryColor,
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
