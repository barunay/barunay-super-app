import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class MarketplaceChatService {
  final SupabaseService _supabaseService = SupabaseService.instance;
  SupabaseClient get client => _supabaseService.client;

  // Conversation Management
  Future<Map<String, dynamic>?> createConversation({
    required String participantTwoId,
    String? productId,
    String? deliveryRequestId,
    String chatType = 'general',
  }) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Check if conversation already exists
      final existingConversation = await client
          .from('marketplace_conversations')
          .select('*')
          .or('participant_one_id.eq.$currentUserId,participant_two_id.eq.$currentUserId')
          .or('participant_one_id.eq.$participantTwoId,participant_two_id.eq.$participantTwoId')
          .maybeSingle();

      if (existingConversation != null) {
        return existingConversation;
      }

      // Create new conversation
      final response = await client
          .from('marketplace_conversations')
          .insert({
            'participant_one_id': currentUserId,
            'participant_two_id': participantTwoId,
            'product_id': productId,
            'delivery_request_id': deliveryRequestId,
            'chat_type': chatType,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create conversation: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getUserConversations() async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await client
          .from('marketplace_conversations')
          .select('''
            *,
            participant_one:user_profiles!marketplace_conversations_participant_one_id_fkey(
              id, full_name, avatar_url, role
            ),
            participant_two:user_profiles!marketplace_conversations_participant_two_id_fkey(
              id, full_name, avatar_url, role
            ),
            last_message:marketplace_messages!marketplace_messages_conversation_id_fkey(
              message_text, media_type, created_at, sender_id
            )
          ''')
          .or('participant_one_id.eq.$currentUserId,participant_two_id.eq.$currentUserId')
          .eq('is_archived', false)
          .order('last_message_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch conversations: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> getConversation(String conversationId) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await client
          .from('marketplace_conversations')
          .select('''
            *,
            participant_one:user_profiles!marketplace_conversations_participant_one_id_fkey(
              id, full_name, avatar_url, role
            ),
            participant_two:user_profiles!marketplace_conversations_participant_two_id_fkey(
              id, full_name, avatar_url, role
            )
          ''')
          .eq('id', conversationId)
          .or('participant_one_id.eq.$currentUserId,participant_two_id.eq.$currentUserId')
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch conversation: ${e.toString()}');
    }
  }

  // Message Management
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    String? messageText,
    String? mediaUrl,
    String? mediaType,
    String? mediaCaption,
    String? replyToMessageId,
    bool isQuickReply = false,
  }) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await client.from('marketplace_messages').insert({
        'conversation_id': conversationId,
        'sender_id': currentUserId,
        'message_text': messageText,
        'media_url': mediaUrl,
        'media_type': mediaType,
        'media_caption': mediaCaption,
        'reply_to_message_id': replyToMessageId,
        'is_quick_reply': isQuickReply,
        'status': 'sent',
      }).select('''
            *,
            sender:user_profiles!marketplace_messages_sender_id_fkey(
              id, full_name, avatar_url
            )
          ''').single();

      // Mark other user's messages as delivered
      await markMessagesAsDelivered(conversationId);

      return response;
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getConversationMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Verify user has access to this conversation
      final conversation = await getConversation(conversationId);
      if (conversation == null) {
        throw Exception('Conversation not found or access denied');
      }

      final response = await client
          .from('marketplace_messages')
          .select('''
            *,
            sender:user_profiles!marketplace_messages_sender_id_fkey(
              id, full_name, avatar_url
            ),
            replied_message:marketplace_messages!marketplace_messages_reply_to_message_id_fkey(
              message_text, media_type, sender_id
            )
          ''')
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch messages: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      final response = await client
          .from('marketplace_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Update message status to read for messages not sent by current user
      await client
          .from('marketplace_messages')
          .update({'status': 'read'})
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUserId)
          .inFilter('status', ['sent', 'delivered']);

      // Insert read receipts
      final unreadMessages = await client
          .from('marketplace_messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUserId)
          .eq('status', 'read');

      if (unreadMessages.isNotEmpty) {
        final readReceipts = unreadMessages
            .map((message) => {
                  'message_id': message['id'],
                  'user_id': currentUserId,
                })
            .toList();

        await client.from('chat_read_receipts').upsert(readReceipts);
      }
    } catch (e) {
      throw Exception('Failed to mark messages as read: ${e.toString()}');
    }
  }

  Future<void> markMessagesAsDelivered(String conversationId) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      await client
          .from('marketplace_messages')
          .update({'status': 'delivered'})
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUserId)
          .eq('status', 'sent');
    } catch (e) {
      // Non-critical operation
      print('Failed to mark messages as delivered: ${e.toString()}');
    }
  }

  // Typing Indicators
  Future<void> updateTypingStatus(String conversationId, bool isTyping) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) return;

      if (isTyping) {
        await client.from('chat_typing_indicators').upsert({
          'conversation_id': conversationId,
          'user_id': currentUserId,
          'is_typing': true,
        });
      } else {
        await client
            .from('chat_typing_indicators')
            .delete()
            .eq('conversation_id', conversationId)
            .eq('user_id', currentUserId);
      }
    } catch (e) {
      print('Failed to update typing status: ${e.toString()}');
    }
  }

  // Quick Replies
  Future<List<Map<String, dynamic>>> getQuickReplies({
    String chatType = 'general',
  }) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) return [];

      final response = await client
          .from('quick_reply_templates')
          .select('*')
          .eq('user_id', currentUserId)
          .eq('chat_type', chatType)
          .eq('is_active', true)
          .order('usage_count', ascending: false)
          .limit(6);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Failed to fetch quick replies: ${e.toString()}');
      return [];
    }
  }

  Future<void> createQuickReply({
    required String templateName,
    required String messageText,
    String chatType = 'general',
  }) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      await client.from('quick_reply_templates').insert({
        'user_id': currentUserId,
        'template_name': templateName,
        'message_text': messageText,
        'chat_type': chatType,
      });
    } catch (e) {
      throw Exception('Failed to create quick reply: ${e.toString()}');
    }
  }

  Future<void> incrementQuickReplyUsage(String templateId) async {
    try {
      await client.from('quick_reply_templates').update({
        'usage_count': client.rpc('increment', params: {'x': 1})
      }).eq('id', templateId);
    } catch (e) {
      print('Failed to increment quick reply usage: ${e.toString()}');
    }
  }

  // Media Upload
  Future<String> uploadMedia(File file, String fileName) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final String path = 'chat-media/$currentUserId/$fileName';

      await client.storage.from('chat-media').upload(
            path,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final String publicUrl =
          client.storage.from('chat-media').getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload media: ${e.toString()}');
    }
  }

  // Utility Functions
  Future<int> getUnreadMessageCount() async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) return 0;

      final response = await client.rpc('get_unread_message_count', params: {
        'user_id': currentUserId,
      });

      return response as int? ?? 0;
    } catch (e) {
      print('Failed to get unread message count: ${e.toString()}');
      return 0;
    }
  }

  Future<void> blockUser(String conversationId, String userIdToBlock) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      await client.from('marketplace_conversations').update({
        'is_blocked': true,
        'blocked_by_user_id': currentUserId,
      }).eq('id', conversationId);
    } catch (e) {
      throw Exception('Failed to block user: ${e.toString()}');
    }
  }

  Future<void> archiveConversation(String conversationId) async {
    try {
      await client
          .from('marketplace_conversations')
          .update({'is_archived': true}).eq('id', conversationId);
    } catch (e) {
      throw Exception('Failed to archive conversation: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getUnreadMessages() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await client
          .from('marketplace_messages')
          .select()
          .neq('sender_id', userId)
          .inFilter('status', ['sent', 'delivered']).order('created_at',
              ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch unread messages: $e');
    }
  }

  // Real-time Subscriptions
  RealtimeChannel subscribeToConversationMessages(
    String conversationId,
    void Function(Map<String, dynamic>) onMessage,
  ) {
    return client.channel('messages:$conversationId').onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'marketplace_messages',
          callback: (payload) {
            if (payload.newRecord['conversation_id'] == conversationId) {
              onMessage(payload.newRecord);
            }
          },
        );
  }

  RealtimeChannel subscribeToTypingIndicators(
    String conversationId,
    void Function(Map<String, dynamic>) onTypingUpdate,
  ) {
    return client.channel('typing:$conversationId').onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_typing_indicators',
          callback: (payload) {
            if (payload.newRecord['conversation_id'] == conversationId) {
              onTypingUpdate(payload.newRecord);
            }
          },
        );
  }

  RealtimeChannel subscribeToMessageStatus(
    String conversationId,
    void Function(Map<String, dynamic>) onStatusUpdate,
  ) {
    return client.channel('message_status:$conversationId').onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'marketplace_messages',
          callback: (payload) {
            if (payload.newRecord['conversation_id'] == conversationId) {
              onStatusUpdate(payload.newRecord);
            }
          },
        );
  }

  void unsubscribe(RealtimeChannel channel) {
    client.removeChannel(channel);
  }
}