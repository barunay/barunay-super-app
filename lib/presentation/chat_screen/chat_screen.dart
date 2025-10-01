import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/marketplace_chat_service.dart';
import '../../services/product_service.dart';
import '../../widgets/global_bottom_navigation.dart';
import './widgets/chat_header_widget.dart';
import './widgets/chat_input_widget.dart';
import './widgets/enhanced_product_context_card_widget.dart';
import './widgets/message_bubble_widget.dart';
import './widgets/typing_indicator_widget.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String? productId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.productId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MarketplaceChatService _chatService = MarketplaceChatService();
  final ProductService _productService = ProductService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _conversation;
  Map<String, dynamic>? _product;
  Map<String, dynamic>? _otherParticipant;
  bool _isLoading = true;
  bool _isTyping = false;
  String? _error;

  RealtimeChannel? _messageChannel;
  RealtimeChannel? _typingChannel;

  @override
  void initState() {
    super.initState();
    _loadChatData();
  }

  @override
  void dispose() {
    _messageChannel?.unsubscribe();
    _typingChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadChatData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load conversation details
      final conversation =
          await _chatService.getConversation(widget.conversationId);
      if (conversation == null) {
        setState(() {
          _error = 'Conversation not found';
          _isLoading = false;
        });
        return;
      }

      // Load messages
      final messages =
          await _chatService.getConversationMessages(widget.conversationId);

      // Load product details if this is a product inquiry
      Map<String, dynamic>? product;
      if (widget.productId != null || conversation['product_id'] != null) {
        final productId = widget.productId ?? conversation['product_id'];
        try {
          product = await _productService.getProductById(productId);
        } catch (e) {
          // Product might be deleted or not accessible
          print('Failed to load product: $e');
        }
      }

      // Determine other participant
      final currentUserId = _chatService.client.auth.currentUser?.id;
      Map<String, dynamic>? otherParticipant;

      if (conversation['participant_one_id'] == currentUserId) {
        otherParticipant = conversation['participant_two'];
      } else {
        otherParticipant = conversation['participant_one'];
      }

      setState(() {
        _conversation = conversation;
        _messages = messages;
        _product = product;
        _otherParticipant = otherParticipant;
        _isLoading = false;
      });

      // Mark messages as read
      await _chatService.markMessagesAsRead(widget.conversationId);

      // Subscribe to real-time updates
      _subscribeToUpdates();

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _subscribeToUpdates() {
    // Subscribe to new messages
    _messageChannel = _chatService.subscribeToConversationMessages(
      widget.conversationId,
      (message) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      },
    );

    // Subscribe to typing indicators
    _typingChannel = _chatService.subscribeToTypingIndicators(
      widget.conversationId,
      (typingData) {
        final currentUserId = _chatService.client.auth.currentUser?.id;
        if (typingData['user_id'] != currentUserId) {
          setState(() {
            _isTyping = typingData['is_typing'] ?? false;
          });
        }
      },
    );

    _messageChannel?.subscribe();
    _typingChannel?.subscribe();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      final message = await _chatService.sendMessage(
        conversationId: widget.conversationId,
        messageText: text.trim(),
      );

      setState(() {
        _messages.add(message);
      });

      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onTypingChanged(bool isTyping) {
    _chatService.updateTypingStatus(widget.conversationId, isTyping);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _otherParticipant != null
          ? ChatHeaderWidget(
              participant: _otherParticipant!,
              isOnline: false, // TODO: Implement online status
              onBackPressed: () => Navigator.pop(context),
              onCallPressed: () {
                // TODO: Implement call functionality
              },
              onVideoCallPressed: () {
                // TODO: Implement video call functionality
              },
            )
          : AppBar(
              title: const Text('Chat'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
      backgroundColor: Colors.grey.shade50,
      body: _buildBody(),
      bottomNavigationBar: const GlobalBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load chat',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadChatData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Product Context Card (if this is a product inquiry)
        if (_product != null)
          EnhancedProductContextCardWidget(
            product: _product,
            conversationId: widget.conversationId,
          ),

        // Messages List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) {
                // Typing indicator
                return TypingIndicatorWidget(
                  userName:
                      (_otherParticipant?['name'] as String?) ?? 'Unknown User',
                  isVisible: true,
                );
              }

              final message = _messages[index];
              final currentUserId = _chatService.client.auth.currentUser?.id;
              final isMe = message['sender_id'] == currentUserId;

              return MessageBubbleWidget(
                message: message,
                isCurrentUser: isMe,
              );
            },
          ),
        ),

        // Chat Input
        ChatInputWidget(
          onSendMessage: (type, content) => _sendMessage(content),
          onSendImage: (type, path, caption) {
            // TODO: Implement image sending
          },
          onSendVoice: (type, path) {
            // TODO: Implement voice message sending
          },
          onSendLocation: (type, name, address) {
            // TODO: Implement location sharing
          },
          onTypingStart: () => _onTypingChanged(true),
          onTypingStop: () => _onTypingChanged(false),
        ),
      ],
    );
  }
}
