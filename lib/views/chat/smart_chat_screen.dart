// lib/views/chat/smart_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/app_controller.dart';
import '../../models/message_model.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import '../../services/channel_service.dart';
import '../../services/reaction_service.dart';
import '../../services/ai/ai_service.dart';
import '../../services/ratchet_service.dart';
import '../../services/encryption_service.dart';
import '../../services/supabase_service.dart';
import 'message_bubble.dart';
import '../../main.dart';
import 'reply_preview_widget.dart';
import 'pinned_messages_screen.dart';
import 'group_details_screen.dart';
import '../../widgets/poll_widget.dart';
import '../../widgets/chat_input_bar.dart';
import '../call/group_call_screen.dart';

class SmartChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String receiverId;
  final bool isGroup;
  final String? groupId;
  final String? groupName;
  final bool isChannel;
  final String? channelId;

  const SmartChatScreen({
    super.key,
    required this.chatId,
    required this.receiverId,
    this.isGroup = false,
    this.groupId,
    this.groupName,
    this.isChannel = false,
    this.channelId,
  });

  @override
  ConsumerState<SmartChatScreen> createState() => _SmartChatScreenState();
}

class _SmartChatScreenState extends ConsumerState<SmartChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<MessageModel> _messages = [];
  Map<String, dynamic>? _lastDocument;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _groupName;
  GroupModel? _group;
  String? _channelName;
  List<String> suggestions = [];
  String? _typingUserName;

  final Map<String, List<int>> _keyCache = {};
  final ReactionService _reactionService = ReactionService();
  final GroupService _groupService = GroupService();
  final ChannelService _channelService = ChannelService();
  final SupabaseClient _supabase = Supabase.instance.client;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _scrollController.addListener(_onScroll);
    if (widget.isGroup && widget.groupId != null) {
      _loadGroupInfo();
    }
    if (widget.isChannel && widget.channelId != null) {
      _loadChannelInfo();
    }
    _listenToTyping();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _keyCache.clear();
    super.dispose();
  }

  Future<void> _loadGroupInfo() async {
    try {
      final group = await _groupService.getGroup(widget.groupId!);
      if (!mounted) return;
      setState(() {
        _group = group;
        _groupName = group.name;
      });
    } catch (e) {
      logger.e('❌ فشل تحميل معلومات المجموعة: $e');
    }
  }

  Future<void> _loadChannelInfo() async {
    try {
      final channel = await _channelService.getChannel(widget.channelId!);
      if (!mounted) return;
      setState(() {
        _channelName = channel.name;
      });
    } catch (e) {
      logger.e('❌ فشل تحميل معلومات القناة: $e');
    }
  }

  void _listenToTyping() {
    final userId = ref.read(authControllerProvider).currentUser?.id;
    if (userId == null) return;
    
    if (!widget.isGroup && !widget.isChannel) {
      final otherUserId = widget.receiverId;
      ref.read(chatControllerProvider.notifier).getTypingStatus(widget.chatId, otherUserId).listen((isTyping) {
        if (!mounted) return;
        setState(() {
          _typingUserName = isTyping ? 'الطرف الآخر' : null;
        });
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 500) {
      if (_hasMore && !_isLoadingMore && !_isLoading) {
        _loadMessages(loadMore: true);
      }
    }
  }

  Future<void> _loadMessages({bool loadMore = false}) async {
    if (_isLoadingMore || (loadMore && !_hasMore)) return;

    if (!mounted) return;
    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
      }
      _error = null;
    });

    try {
      final userId = ref.read(authControllerProvider).currentUser?.id;
      if (userId == null) return;

      // ✅ جلب الرسائل من Supabase
      final response = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', widget.chatId)
          .order('timestamp', ascending: false)
          .limit(30);

      if (response.isNotEmpty) {
        _lastDocument = response.last;
        _hasMore = response.length == 30;
      } else {
        _hasMore = false;
      }

      // ✅ معالجة الرسائل الفردية (غير القنوات والمجموعات)
      if (!widget.isGroup && !widget.isChannel) {
        final newMessages = <MessageModel>[];
        
        for (var data in response) {
          try {
            final ratchetN = data['ratchet_n'] as int?;
            if (ratchetN == null || ratchetN == 0) {
              final message = MessageModel.fromSupabase(data);
              newMessages.add(message);
              continue;
            }
            
            final cacheKey = '${widget.chatId}:$ratchetN';
            List<int>? mk = _keyCache[cacheKey];
            
            if (mk == null) {
              final dhPubStr = data['dh_pub'] as String?;
              final senderDhPub = dhPubStr != null ? base64Decode(dhPubStr) : null;
              mk = await RatchetService.keyForReceived(
                chatId: widget.chatId,
                myUserId: userId,
                ratchetN: ratchetN,
                senderDhPub: senderDhPub,
              );
              if (_keyCache.length > 100) {
                _keyCache.remove(_keyCache.keys.first);
              }
              _keyCache[cacheKey] = mk;
            }

            final senderId = data['sender_id'] as String? ?? '';
            final recipientId = data['recipient_id'] as String? ?? '';
            final timestamp = data['timestamp'] as String? ?? DateTime.now().toIso8601String();
            final messageType = data['message_type'] as String? ?? 'text';
            final protocolVersion = data['protocol_version'] as int? ?? 2;
            final dhPubStr = data['dh_pub'] as String? ?? '';
            final encryptedContent = data['content'] as String? ?? '';

            // ✅ استخدام AAD موحد
            final aad = EncryptionService.buildAAD(
              chatId: widget.chatId,
              senderId: senderId,
              receiverId: userId,
              ratchetN: ratchetN,
              timestamp: DateTime.parse(timestamp).millisecondsSinceEpoch,
              messageType: messageType,
              protocolVersion: protocolVersion,
              dhPub: dhPubStr.isNotEmpty ? base64Decode(dhPubStr) : [],
            );

            final clear = await EncryptionService.decrypt(
              encrypted: encryptedContent,
              keyBytes: mk,
              aad: aad,
            );

            final safeData = {
              ...data,
              'content': clear,
            };

            final message = MessageModel.fromSupabase(safeData);
            newMessages.add(message);
          } catch (e) {
            logger.e('❌ فشل فك الرسالة: $e');
            newMessages.add(MessageModel.fromSupabase({
              ...data,
              'content': '[فشل فك التشفير]',
            }));
          }
        }

        if (!mounted) return;
        setState(() {
          if (loadMore) {
            _messages.addAll(newMessages);
          } else {
            _messages.clear();
            _messages.addAll(newMessages);
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        // ✅ للمجموعات والقنوات (غير مشفرة)
        final newMessages = response
            .map((data) => MessageModel.fromSupabase(data))
            .toList();

        if (!mounted) return;
        setState(() {
          if (loadMore) {
            _messages.addAll(newMessages);
          } else {
            _messages.clear();
            _messages.addAll(newMessages);
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
      }

    } catch (e) {
      logger.e('❌ فشل تحميل الرسائل: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshMessages() async {
    _lastDocument = null;
    _hasMore = true;
    _keyCache.clear();
    await _loadMessages();
  }

  void _openGroupDetails() {
    if (widget.isGroup && widget.groupId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupDetailsScreen(groupId: widget.groupId!),
        ),
      ).then((_) => _loadGroupInfo());
    }
  }

  Future<void> _startVideoGroupCall() async {
    if (_group == null) return;
    
    final userId = ref.read(authControllerProvider).currentUser?.id;
    if (userId == null) return;
    
    final participants = _group!.members.where((id) => id != userId).toList();
    
    if (participants.isEmpty) {
      _showSnackBar('لا يوجد مشاركين آخرين لإجراء مكالمة', isError: true);
      return;
    }
    
    if (participants.length > 50) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ عدد كبير من المشاركين'),
          content: Text(
            'المجموعة تحتوي على ${participants.length} عضو. '
            'المكالمات الفيديو تدعم حتى 50 مشاركاً فقط. '
            'سيتم إضافة أول 50 عضو فقط.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('متابعة'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
    }
    
    final limitedParticipants = participants.take(50).toList();
    
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupCallScreen(
            isInitiator: true,
            groupId: widget.groupId!,
            callId: DateTime.now().millisecondsSinceEpoch.toString(),
            participantIds: limitedParticipants,
            currentUserId: userId,
            isVideo: true,
          ),
        ),
      );
    } catch (e) {
      logger.e('❌ فشل بدء المكالمة الجماعية: $e');
      _showSnackBar('فشل بدء المكالمة: $e', isError: true);
    }
  }

  Future<void> _startVoiceGroupCall() async {
    if (_group == null) return;
    
    final userId = ref.read(authControllerProvider).currentUser?.id;
    if (userId == null) return;
    
    final participants = _group!.members.where((id) => id != userId).toList();
    
    if (participants.isEmpty) {
      _showSnackBar('لا يوجد مشاركين آخرين لإجراء مكالمة', isError: true);
      return;
    }
    
    if (participants.length > 1050) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ عدد كبير جداً من المشاركين'),
          content: Text(
            'المجموعة تحتوي على ${participants.length} عضو. '
            'المكالمات الصوتية تدعم حتى 1050 مشاركاً فقط. '
            'سيتم إضافة أول 1050 عضو فقط.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('متابعة'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
    }
    
    final limitedParticipants = participants.take(1050).toList();
    
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupCallScreen(
            isInitiator: true,
            groupId: widget.groupId!,
            callId: DateTime.now().millisecondsSinceEpoch.toString(),
            participantIds: limitedParticipants,
            currentUserId: userId,
            isVideo: false,
          ),
        ),
      );
    } catch (e) {
      logger.e('❌ فشل بدء المكالمة الجماعية: $e');
      _showSnackBar('فشل بدء المكالمة: $e', isError: true);
    }
  }

  Future<void> _addReaction(MessageModel message, String reaction) async {
    final userId = ref.read(authControllerProvider).currentUser?.id;
    if (userId == null) return;
    
    if (widget.isGroup && widget.groupId != null) {
      await _reactionService.addReaction(
        chatId: widget.groupId!,
        messageId: message.id,
        reaction: reaction,
        userId: userId,
        isGroup: true,
      );
    } else if (widget.isChannel && widget.channelId != null) {
      return;
    } else {
      await _reactionService.addReaction(
        chatId: widget.chatId,
        messageId: message.id,
        reaction: reaction,
        userId: userId,
      );
    }
    _refreshMessages();
  }

  Future<void> _summarizeConversation() async {
    if (_messages.isEmpty) {
      _showSnackBar('لا توجد رسائل لتلخيصها', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('جاري التلخيص...'),
        content: SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
      ),
    );

    try {
      final aiService = AIService();
      final currentUserId = ref.read(authControllerProvider).currentUser?.id;
      if (currentUserId == null) return;
      final messagesText = _messages.map((m) =>
        '${m.senderId == currentUserId ? 'أنا' : 'الآخر'}: ${m.content}'
      ).join('\n');
      
      final summary = await aiService.chat(
        user: currentUserId,
        message: 'لخص هذه المحادثة:\n\n$messagesText',
        isPro: true,
        isLifetime: false,
        messagesToday: 0,
        withRAG: false,
      );
      
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('📝 ملخص المحادثة'),
            content: SelectableText(summary),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('فشل تلخيص المحادثة', isError: true);
      }
    }
  }

  Future<void> _showSmartReplies() async {
    if (_messages.isEmpty) return;
    
    final lastMessage = _messages.first.content;
    
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<String>>(
        future: _generateReplies(lastMessage),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              title: Text('جاري التوليد...'),
              content: SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
            );
          }
          
          final replies = snapshot.data ?? [];
          if (replies.isEmpty) {
            return AlertDialog(
              title: const Text('🤖 ردود ذكية مقترحة'),
              content: const Text('لا توجد ردود مقترحة حالياً.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
              ],
            );
          }
          
          return AlertDialog(
            title: const Text('🤖 ردود ذكية مقترحة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: replies.map((reply) => ListTile(
                title: Text(reply),
                onTap: () {
                  Navigator.pop(context);
                  final chatController = ref.read(chatControllerProvider.notifier);
                  chatController.inputController.text = reply;
                  chatController.sendTextMessage(widget.chatId, widget.receiverId);
                },
              )).toList(),
            ),
          );
        },
      ),
    );
  }

  Future<List<String>> _generateReplies(String message) async {
    try {
      final aiService = AIService();
      final currentUserId = ref.read(authControllerProvider).currentUser?.id;
      if (currentUserId == null) return [];
      final response = await aiService.chat(
        user: currentUserId,
        message: 'اقترح 3 ردود قصيرة ومفيدة للرد على: "$message"',
        isPro: true,
        isLifetime: false,
        messagesToday: 0,
        withRAG: false,
      );
      
      return response.split('\n').where((r) => r.trim().isNotEmpty).take(3).toList();
    } catch (e) {
      logger.e('❌ فشل توليد الردود الذكية: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatController = ref.watch(chatControllerProvider.notifier);
    final chatState = ref.watch(chatControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final userId = authState.currentUser?.id;
    final isPro = ref.watch(appControllerProvider).isPro;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("يجب تسجيل الدخول أولًا.")),
      );
    }

    String title;
    if (widget.isChannel) {
      title = _channelName ?? 'القناة';
    } else if (widget.isGroup) {
      title = _groupName ?? widget.groupName ?? 'المجموعة';
    } else {
      title = 'المستخدم الآخر';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (widget.isGroup) ...[
            IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: _startVideoGroupCall,
              tooltip: 'مكالمة فيديو جماعية (حتى 50 مشارك)',
            ),
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: _startVoiceGroupCall,
              tooltip: 'مكالمة صوتية جماعية (حتى 1050 مشارك)',
            ),
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: _openGroupDetails,
              tooltip: 'تفاصيل المجموعة',
            ),
          ],
          
          if (!widget.isGroup && !widget.isChannel) ...[
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: () => chatController.startVoiceCall(widget.receiverId),
              tooltip: 'مكالمة صوتية',
            ),
            IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: () => chatController.startVideoCall(widget.receiverId),
              tooltip: 'مكالمة فيديو',
            ),
          ],
          
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pinned', child: Text('الرسائل المثبتة')),
              const PopupMenuItem(value: 'summary', child: Text('📝 ملخص المحادثة')),
              if (isPro) const PopupMenuItem(value: 'smart_replies', child: Text('🤖 ردود ذكية')),
            ],
            onSelected: (value) {
              if (value == 'pinned') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PinnedMessagesScreen(chatId: widget.chatId)));
              } else if (value == 'summary') {
                _summarizeConversation();
              } else if (value == 'smart_replies') {
                _showSmartReplies();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            padding: const EdgeInsets.all(6),
            child: Text(
              widget.isChannel
                ? '📢 هذه قناة عامة - البث فقط'
                : (widget.isGroup
                    ? '💡 محادثة جماعية مشفرة بالكامل | 📹 مكالمات فيديو (حتى 50) | 📞 مكالمات صوتية (حتى 1050)'
                    : '💡 اكتب "privoo" داخل المحادثة لتفعيل البوت الذكي الخاص بك.'),
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('خطأ: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshMessages,
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Text(
                              widget.isChannel
                                ? 'لا توجد منشورات بعد.\nكن أول من ينشر!'
                                : (widget.isGroup
                                    ? 'لا توجد رسائل بعد.\nأول رسالة في المجموعة!'
                                    : 'لا توجد رسائل بعد.\nابدأ المحادثة!'),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshMessages,
                            child: ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _messages.length && _isLoadingMore) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  );
                                }
                                final msg = _messages[index];
                                final isMe = msg.senderId == userId;
                                final isBot = msg.senderId == "PrivooAI";
                                
                                String senderName;
                                if (widget.isGroup) {
                                  senderName = isMe ? 'أنا' : ('${msg.senderId.substring(0, 6)}...');
                                } else if (widget.isChannel) {
                                  senderName = msg.senderId.substring(0, 8);
                                } else {
                                  senderName = isBot
                                      ? "Privoo 🤖"
                                      : (isMe ? "أنا" : "المستخدم الآخر");
                                }

                                return Column(
                                  children: [
                                    MessageBubble(
                                      message: msg,
                                      isMe: isMe,
                                      isBot: isBot,
                                      senderName: senderName,
                                      isPinned: msg.isPinned,
                                      onReaction: (reaction) => _addReaction(msg, reaction),
                                      onPin: () => chatController.togglePinMessage(
                                        widget.chatId,
                                        msg.id,
                                        msg.isPinned,
                                      ),
                                      onDelete: () async {
                                        if (widget.isGroup && widget.groupId != null) {
                                          await _supabase
                                              .from('messages')
                                              .delete()
                                              .eq('id', msg.id)
                                              .eq('chat_id', widget.groupId!);
                                        } else if (widget.isChannel && widget.channelId != null) {
                                          await _supabase
                                              .from('messages')
                                              .delete()
                                              .eq('id', msg.id)
                                              .eq('chat_id', widget.channelId!);
                                        } else {
                                          await _supabase
                                              .from('messages')
                                              .delete()
                                              .eq('id', msg.id)
                                              .eq('chat_id', widget.chatId);
                                        }
                                        _refreshMessages();
                                      },
                                      // ✅ إضافة onDownload
                                      onDownload: () => chatController.downloadMediaMessage(context, msg),
                                    ),
                                    if (msg.pollId != null)
                                      PollWidget(pollId: msg.pollId!.toString()),
                                  ],
                                );
                              },
                            ),
                          ),
          ),

          if (_typingUserName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_typingUserName يكتب...',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

          if (chatState.suggestions.isNotEmpty && !widget.isGroup && !widget.isChannel)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                children: chatState.suggestions.map(
                  (s) => ActionChip(
                    label: Text(s),
                    onPressed: () =>
                        chatController.sendSmartReply(s, widget.chatId, widget.receiverId),
                  ),
                ).toList(),
              ),
            ),

          ChatInputBar(
            chatId: widget.chatId,
            receiverId: widget.receiverId,
            isGroup: widget.isGroup,
            groupId: widget.groupId,
            isChannel: widget.isChannel,
            channelId: widget.channelId,
            onMessageSent: _refreshMessages,
          ),

          Container(
            padding: const EdgeInsets.all(6),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Text(
              widget.isChannel
                ? '📢 هذه قناة عامة - جميع المنشورات مرئية للجميع'
                : (widget.isGroup
                    ? '🔒 هذه المجموعة مشفرة بالكامل بين جميع الأعضاء.'
                    : '🔒 جميع الرسائل مشفرة بالكامل بين الطرفين فقط.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}