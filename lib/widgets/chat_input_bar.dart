// widgets/chat_input_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../controllers/chat_controller.dart';
import '../services/group_service.dart';
import '../services/channel_service.dart';
import '../services/gif_service.dart';
import '../views/chat/disappearing_options_sheet.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  final String chatId;
  final String receiverId;
  final bool isGroup;
  final String? groupId;
  final bool isChannel;
  final String? channelId;
  final VoidCallback? onMessageSent;

  const ChatInputBar({
    super.key,
    required this.chatId,
    required this.receiverId,
    this.isGroup = false,
    this.groupId,
    this.isChannel = false,
    this.channelId,
    this.onMessageSent,
  });

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  bool _showFormattingBar = false;

  void _applyFormatting(String before, String after) {
    final controller = ref.read(chatControllerProvider.notifier).inputController;
    final text = controller.text;
    final selection = controller.selection;
    
    final start = selection.start;
    final end = selection.end;
    
    if (start == end) {
      final newText = text.substring(0, start) + before + after + text.substring(start);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + before.length),
      );
    } else {
      final selectedText = text.substring(start, end);
      final newText = text.substring(0, start) + before + selectedText + after + text.substring(end);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(baseOffset: start, extentOffset: end + before.length + after.length),
      );
    }
  }

  Future<void> _send(WidgetRef ref) async {
    final chat = ref.read(chatControllerProvider.notifier);
    chat.onTypingStop();
    final text = chat.inputController.text.trim();
    if (text.isEmpty) return;

    try {
      print('📤📤📤 SEND BUTTON PRESSED 📤📤📤');
      print('📤 chatId: ${widget.chatId}');
      print('📤 receiverId: ${widget.receiverId}');
      print('📤 text: $text');
      print('📤 isGroup: ${widget.isGroup}');
      print('📤 isChannel: ${widget.isChannel}');
      
      if (widget.isChannel && widget.channelId != null) {
        final channelService = ChannelService();
        await channelService.sendChannelPost(
          channelId: widget.channelId!,
          content: text,
          senderId: chat.currentUserId,
        );
      } else if (widget.isGroup && widget.groupId != null) {
        final groupService = GroupService();
        await groupService.sendGroupMessage(
          groupId: widget.groupId!,
          message: text,
          senderId: chat.currentUserId,
        );
      } else {
        await chat.sendTextMessage(widget.chatId, widget.receiverId);
      }
      
      print('✅ Message sent successfully');
      widget.onMessageSent?.call();
    } catch (e, st) {
      print('❌❌❌ SEND ERROR ❌❌❌');
      print('❌ Error: $e');
      print('❌ Stacktrace: $st');
      
      // ✅ عرض الخطأ للمستخدم
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ فشل الإرسال: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _sendDisappearing(WidgetRef ref, dynamic duration) async {
    final chat = ref.read(chatControllerProvider.notifier);
    final text = chat.inputController.text.trim();
    if (text.isEmpty) return;
    
    if (!widget.isChannel && !widget.isGroup) {
      await chat.sendDisappearingMessage(widget.chatId, widget.receiverId, duration);
      widget.onMessageSent?.call();
    }
  }

  Future<void> _pickImageCamera(WidgetRef ref) async {
    final file = await ImagePicker().pickImage(source: ImageSource.camera);
    if (file != null) {
      if (widget.isGroup && widget.groupId != null) {
        final groupService = GroupService();
        await groupService.sendGroupMessage(
          groupId: widget.groupId!,
          message: file.path,
          senderId: ref.read(chatControllerProvider.notifier).currentUserId,
          type: 'image',
        );
      } else if (widget.isChannel && widget.channelId != null) {
        final channelService = ChannelService();
        await channelService.sendChannelPost(
          channelId: widget.channelId!,
          content: file.path,
          senderId: ref.read(chatControllerProvider.notifier).currentUserId,
        );
      } else {
        await ref.read(chatControllerProvider.notifier)
            .sendMediaMessage(widget.chatId, widget.receiverId, file.path, "image");
      }
      widget.onMessageSent?.call();
    }
  }

  Future<void> _pickImageGallery(WidgetRef ref) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      if (widget.isGroup && widget.groupId != null) {
        final groupService = GroupService();
        await groupService.sendGroupMessage(
          groupId: widget.groupId!,
          message: file.path,
          senderId: ref.read(chatControllerProvider.notifier).currentUserId,
          type: 'image',
        );
      } else if (widget.isChannel && widget.channelId != null) {
        final channelService = ChannelService();
        await channelService.sendChannelPost(
          channelId: widget.channelId!,
          content: file.path,
          senderId: ref.read(chatControllerProvider.notifier).currentUserId,
        );
      } else {
        await ref.read(chatControllerProvider.notifier)
            .sendMediaMessage(widget.chatId, widget.receiverId, file.path, "image");
      }
      widget.onMessageSent?.call();
    }
  }

  Future<void> _recordVideo(WidgetRef ref) async {
    final file = await ImagePicker().pickVideo(source: ImageSource.camera);
    if (file != null) {
      if (widget.isGroup && widget.groupId != null) {
        final groupService = GroupService();
        await groupService.sendGroupMessage(
          groupId: widget.groupId!,
          message: file.path,
          senderId: ref.read(chatControllerProvider.notifier).currentUserId,
          type: 'video',
        );
      } else if (widget.isChannel && widget.channelId != null) {
        final channelService = ChannelService();
        await channelService.sendChannelPost(
          channelId: widget.channelId!,
          content: file.path,
          senderId: ref.read(chatControllerProvider.notifier).currentUserId,
        );
      } else {
        await ref.read(chatControllerProvider.notifier)
            .sendMediaMessage(widget.chatId, widget.receiverId, file.path, "video");
      }
      widget.onMessageSent?.call();
    }
  }

  Future<void> _pickVideoGallery(WidgetRef ref) async {
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file != null) {
      if (widget.isGroup && widget.groupId != null) {
        final groupService = GroupService();
        await groupService.sendGroupMessage(
          groupId: widget.groupId!,
          message: file.path,
          senderId: ref.read(chatControllerProvider.notifier).currentUserId,
          type: 'video',
        );
      } else if (widget.isChannel && widget.channelId != null) {
        final channelService = ChannelService();
        await channelService.sendChannelPost(
          channelId: widget.channelId!,
          content: file.path,
          senderId: ref.read(chatControllerProvider.notifier).currentUserId,
        );
      } else {
        await ref.read(chatControllerProvider.notifier)
            .sendMediaMessage(widget.chatId, widget.receiverId, file.path, "video");
      }
      widget.onMessageSent?.call();
    }
  }

  Future<void> _pickFile(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      if (widget.isGroup && widget.groupId != null) {
        final groupService = GroupService();
        await groupService.sendGroupMessage(
          groupId: widget.groupId!,
          message: result.files.single.path!,
          senderId: ref.read(chatControllerProvider.notifier).currentUserId,
          type: 'file',
        );
      } else if (widget.isChannel && widget.channelId != null) {
        final channelService = ChannelService();
        await channelService.sendChannelPost(
          channelId: widget.channelId!,
          content: result.files.single.path!,
          senderId: ref.read(chatControllerProvider.notifier).currentUserId,
        );
      } else {
        await ref.read(chatControllerProvider.notifier)
            .sendMediaMessage(widget.chatId, widget.receiverId, result.files.single.path!, "file");
      }
      widget.onMessageSent?.call();
    }
  }

  Future<void> _pickGif(WidgetRef ref) async {
    final gifUrl = await GifService.pickGif(context);
    if (gifUrl != null && gifUrl.isNotEmpty) {
      if (widget.isGroup && widget.groupId != null) {
        final groupService = GroupService();
        await groupService.sendGroupMessage(
          groupId: widget.groupId!,
          message: gifUrl,
          senderId: ref.read(chatControllerProvider.notifier).currentUserId,
          type: 'gif',
        );
      } else if (widget.isChannel && widget.channelId != null) {
        final channelService = ChannelService();
        await channelService.sendChannelPost(
          channelId: widget.channelId!,
          content: gifUrl,
          senderId: ref.read(chatControllerProvider.notifier).currentUserId,
        );
      } else {
        await ref.read(chatControllerProvider.notifier)
            .sendMediaMessage(widget.chatId, widget.receiverId, gifUrl, "gif");
      }
      widget.onMessageSent?.call();
    }
  }

  Future<void> _sendContact(WidgetRef ref) async {
    if (!widget.isChannel && !widget.isGroup) {
      await ref.read(chatControllerProvider.notifier)
          .sendContactMessage(widget.chatId, widget.receiverId, "جهة اتصال");
      widget.onMessageSent?.call();
    }
  }

  Future<void> _sendLocation(WidgetRef ref) async {
    if (!widget.isChannel && !widget.isGroup) {
      await ref.read(chatControllerProvider.notifier)
          .sendLocationMessage(widget.chatId, widget.receiverId);
      widget.onMessageSent?.call();
    }
  }

  Future<void> _startLiveLocation(WidgetRef ref) async {
    if (!widget.isChannel && !widget.isGroup) {
      await ref.read(chatControllerProvider.notifier).startLiveLocation(widget.chatId);
    }
  }

  Future<void> _stopLiveLocation(WidgetRef ref) async {
    if (!widget.isChannel && !widget.isGroup) {
      await ref.read(chatControllerProvider.notifier).stopLiveLocation(widget.chatId);
    }
  }

  Future<void> _recordVoice(WidgetRef ref) async {
    if (!widget.isChannel && !widget.isGroup) {
      await ref.read(chatControllerProvider.notifier)
          .startVoiceRecording(widget.chatId, widget.receiverId);
      widget.onMessageSent?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          if (_showFormattingBar)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.format_bold, size: 20),
                    onPressed: () => _applyFormatting('**', '**'),
                    tooltip: 'عريض (Bold)',
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_italic, size: 20),
                    onPressed: () => _applyFormatting('*', '*'),
                    tooltip: 'مائل (Italic)',
                  ),
                  IconButton(
                    icon: const Icon(Icons.code, size: 20),
                    onPressed: () => _applyFormatting('`', '`'),
                    tooltip: 'كود',
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _showFormattingBar = false),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              PopupMenuButton(
                icon: const Icon(Icons.add_circle, size: 30, color: Colors.blue),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'camera', child: Text("📸 التقاط صورة")),
                  const PopupMenuItem(value: 'gallery', child: Text("🖼 اختيار صورة")),
                  const PopupMenuItem(value: 'record_video', child: Text("🎥 تسجيل فيديو")),
                  const PopupMenuItem(value: 'video', child: Text("🎬 اختيار فيديو")),
                  const PopupMenuItem(value: 'file', child: Text("📁 ملف")),
                  const PopupMenuItem(value: 'gif', child: Text("🎬 GIF")),
                  const PopupMenuItem(value: 'contact', child: Text("👤 جهة اتصال")),
                  if (!widget.isChannel && !widget.isGroup) ...[
                    const PopupMenuItem(value: 'location', child: Text("📍 إرسال الموقع")),
                    const PopupMenuItem(value: 'live_location_start', child: Text("📍 بدء الموقع الحي")),
                    const PopupMenuItem(value: 'live_location_stop', child: Text("⛔ إيقاف الموقع الحي")),
                  ],
                  const PopupMenuItem(value: 'poll', child: Text("📊 استطلاع رأي")),
                  const PopupMenuItem(value: 'disappearing', child: Text("⏱️ رسالة مختفية")),
                  const PopupMenuItem(value: 'formatting', child: Text("🔤 تنسيق النص")),
                ],
                onSelected: (value) async {
                  switch (value) {
                    case 'camera':
                      await _pickImageCamera(ref);
                      break;
                    case 'gallery':
                      await _pickImageGallery(ref);
                      break;
                    case 'record_video':
                      await _recordVideo(ref);
                      break;
                    case 'video':
                      await _pickVideoGallery(ref);
                      break;
                    case 'file':
                      await _pickFile(ref);
                      break;
                    case 'gif':
                      await _pickGif(ref);
                      break;
                    case 'contact':
                      await _sendContact(ref);
                      break;
                    case 'location':
                      await _sendLocation(ref);
                      break;
                    case 'live_location_start':
                      await _startLiveLocation(ref);
                      break;
                    case 'live_location_stop':
                      await _stopLiveLocation(ref);
                      break;
                    case 'poll':
                      break;
                    case 'disappearing':
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => DisappearingOptionsSheet(
                          onSelected: (duration) {
                            if (duration.seconds > 0) {
                              _sendDisappearing(ref, duration);
                            }
                          },
                        ),
                      );
                      break;
                    case 'formatting':
                      setState(() => _showFormattingBar = !_showFormattingBar);
                      break;
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: chat.inputController,
                  decoration: const InputDecoration(
                    hintText: "اكتب رسالتك...",
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    if (!widget.isGroup && !widget.isChannel) {
                      chat.analyzeInput(value);
                      if (value.isNotEmpty) {
                        chat.onTypingStart(widget.chatId);
                      } else {
                        chat.onTypingStop();
                      }
                    }
                  },
                  onSubmitted: (_) => _send(ref),
                  minLines: 1,
                  maxLines: 5,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.mic, color: Colors.red),
                onPressed: () => _recordVoice(ref),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                color: chat.inputController.text.trim().isEmpty
                    ? Colors.grey
                    : Theme.of(context).primaryColor,
                onPressed: chat.inputController.text.trim().isEmpty
                    ? null
                    : () => _send(ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
