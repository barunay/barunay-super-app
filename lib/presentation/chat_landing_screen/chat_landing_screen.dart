import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/marketplace_chat_service.dart';

class ChatLandingScreen extends StatefulWidget {
  const ChatLandingScreen({Key? key}) : super(key: key);

  @override
  State<ChatLandingScreen> createState() => _ChatLandingScreenState();
}

class _ChatLandingScreenState extends State<ChatLandingScreen> {
  final MarketplaceChatService _chatService = MarketplaceChatService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      setState(() => _isLoading = true);

      final conversations = await _chatService.getUserConversations();

      setState(() {
        _conversations = conversations;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load conversations: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToConversation(Map<String, dynamic> conversation) {
    final currentUserId = _chatService.client.auth.currentUser?.id;

    // Determine the other participant
    Map<String, dynamic> participant;
    if (conversation['participant_one_id'] == currentUserId) {
      participant = conversation['participant_two'];
    } else {
      participant = conversation['participant_one'];
    }

    Navigator.pushNamed(
      context,
      '/chat-screen',
      arguments: {
        'conversationId': conversation['id'],
        'participant': participant,
        'chatType': conversation['chat_type'],
        'productId': conversation['product_id'],
        'deliveryRequestId': conversation['delivery_request_id'],
      },
    );
  }

  void _startNewConversation() {
    // Navigate to contact selection or search users
    Navigator.pushNamed(context, '/select-contact');
  }

  String _formatLastMessageTime(String timestamp) {
    final messageTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(messageTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Messages',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 6.w,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _startNewConversation,
            icon: CustomIconWidget(
              iconName: 'edit',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 6.w,
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _loadConversations,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = _conversations[index];
                    final currentUserId =
                        _chatService.client.auth.currentUser?.id;

                    // Determine the other participant
                    final isParticipantOne =
                        conversation['participant_one_id'] == currentUserId;
                    final participant =
                        isParticipantOne
                            ? conversation['participant_two']
                            : conversation['participant_one'];

                    return _buildConversationTile(conversation, participant);
                  },
                ),
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'chat_bubble_outline',
            size: 20.w,
            color: AppTheme.lightTheme.colorScheme.outline,
          ),
          SizedBox(height: 2.h),
          Text(
            'No conversations yet',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Start a conversation by browsing products or services',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/marketplace-home'),
            icon: CustomIconWidget(
              iconName: 'explore',
              color: Colors.white,
              size: 5.w,
            ),
            label: Text('Explore Marketplace'),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(
    Map<String, dynamic> conversation,
    Map<String, dynamic> participant,
  ) {
    final lastMessage = conversation['last_message'] as List?;
    final hasUnread = (conversation['unread_count'] as int? ?? 0) > 0;

    return ListTile(
      onTap: () {
        HapticFeedback.lightImpact();
        _navigateToConversation(conversation);
      },
      leading: CircleAvatar(
        radius: 6.w,
        backgroundImage: NetworkImage(
          participant['avatar_url'] ??
              'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png',
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
      ),
      title: Text(
        participant['full_name'] ?? 'User',
        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle:
          lastMessage != null && lastMessage.isNotEmpty
              ? Text(
                lastMessage.first['message_text'] ?? 'Media message',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color:
                      hasUnread
                          ? AppTheme.lightTheme.colorScheme.onSurface
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
              : Text(
                'No messages yet',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatLastMessageTime(conversation['last_message_at']),
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color:
                  hasUnread
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (hasUnread) ...[
            SizedBox(height: 0.5.h),
            Container(
              padding: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2.w),
              ),
              constraints: BoxConstraints(minWidth: 5.w, minHeight: 5.w),
              child: Text(
                '${conversation['unread_count'] ?? 0}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
    );
  }
}