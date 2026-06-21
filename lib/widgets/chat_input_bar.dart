// widgets/chat_input_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
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
  bool _showEmojiPicker = false;
  
  // ✅ Voice Recording State
  bool _isRecordingVoice = false;
  bool _isVoiceLocked = false;
  double _dragOffset = 0.0;
  Duration _voiceDuration = Duration.zero;
  Timer? _voiceTimer;
  String? _voicePath;

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

  // ✅ إضافة Emoji
  void _onEmojiSelected(Emoji emoji) {
    final controller = ref.read(chatControllerProvider.notifier).inputController;
    final text = controller.text;
    final selection = controller.selection;
    
    final newText = text.substring(0, selection.start) + 
                     emoji.emoji + 
                     text.substring(selection.end);
    
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + emoji.emoji.length),
    );
  }

  // ✅ بدء تسجيل الصوت (مثل واتساب)
  void _startVoiceRecording() async {
    final chat = ref.read(chatControllerProvider.notifier);
    setState(() {
      _isRecordingVoice = true;
      _isVoiceLocked = false;
      _dragOffset = 0.0;
      _voiceDuration = Duration.zero;
    });
    
    _voiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _voiceDuration += const Duration(seconds: 1);
      });
    });
    
    await chat.startVoiceRecording(widget.chatId, widget.receiverId);
  }

  // ✅ إيقاف التسجيل وإرسال الصوت
  void _stopVoiceRecording() async {
    _voiceTimer?.cancel();
    setState(() {
      _isRecordingVoice = false;
    });
    
    // الرسالة الصوتية هتتبعت تلقائياً من ChatController
  }

  // ✅ إلغاء التسجيل (سحب لليسار)
  void _cancelVoiceRecording() {
    _voiceTimer?.cancel();
    setState(() {
      _isRecordingVoice = false;
      _voiceDuration = Duration.zero;
      _dragOffset = 0.0;
    });
    // حذف الملف الصوتي
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

  // ... باقي الدوال (sendDisappearing, pickImageCamera, pickImageGallery, recordVideo, pickVideoGallery, pickFile, pickGif, sendContact, sendLocation, startLiveLocation, stopLiveLocation)

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatControllerProvider.notifier);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              if (_showFormattingBar) _buildFormattingBar(),
              if (_isRecordingVoice)
                _buildVoiceRecorderBar()
              else
                _buildInputRow(chat),
            ],
          ),
        ),
        // ✅ Emoji Picker
        if (_showEmojiPicker)
          SizedBox(
            height: 300,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                _onEmojiSelected(emoji);
              },
              config: Config(
                columns: 7,
                emojiSizeMax: 32,
                verticalSpacing: 0,
                horizontalSpacing: 0,
                gridPadding: EdgeInsets.zero,
                initCategory: Category.SMILEYS,
                bgColor: Theme.of(context).cardColor,
                indicatorColor: Theme.of(context).primaryColor,
                iconColor: Colors.grey,
                iconColorSelected: Theme.of(context).primaryColor,
                progressIndicatorColor: Theme.of(context).primaryColor,
                backspaceColor: Theme.of(context).primaryColor,
                showRecentsTab: true,
                recentsLimit: 28,
                noRecents: const Text('لا توجد إيموجي حديثة'),
                tabIndicatorAnimDuration: kTabScrollDuration,
                categoryIcons: const CategoryIcons(),
                buttonMode: ButtonMode.MATERIAL,
                checkAvailability: false,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFormattingBar() {
    return Container(
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
    );
  }

  Widget _buildVoiceRecorderBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // ✅ زر إلغاء (سحب لليسار)
          GestureDetector(
            onTap: _cancelVoiceRecording,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.red),
            ),
          ),
          const SizedBox(width: 12),
          // ✅ مؤقت التسجيل
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_voiceDuration),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  // ✅ موجة صوتية متحركة (UI فقط)
                  ...List.generate(5, (index) {
                    final height = 8 + (index % 3) * 4;
                    return Container(
                      width: 3,
                      height: height.toDouble(),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ✅ زر تثبيت التسجيل (سحب لأعلى)
          IconButton(
            icon: Icon(
              _isVoiceLocked ? Icons.lock : Icons.lock_open,
              color: _isVoiceLocked ? Colors.green : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isVoiceLocked = !_isVoiceLocked;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(ChatController chat) {
    return Row(
      children: [
        // ✅ زر Emoji
        IconButton(
          icon: Icon(
            Icons.emoji_emotions,
            color: _showEmojiPicker ? Colors.amber : Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _showEmojiPicker = !_showEmojiPicker;
              _showFormattingBar = false;
            });
          },
        ),
        PopupMenuButton(
          icon: const Icon(Icons.add_circle, size: 28, color: Colors.blue),
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
        // ✅ زر الميكروفون مع GestureDetector للسحب
        GestureDetector(
          onLongPressStart: (_) {
            if (!widget.isChannel && !widget.isGroup) {
              _startVoiceRecording();
            }
          },
          onLongPressMoveUpdate: (details) {
            if (_isRecordingVoice) {
              final dx = details.localPosition.dx;
              final dy = details.localPosition.dy;
              
              // سحب لليسار لإلغاء
              if (dx < -50) {
                _cancelVoiceRecording();
              }
              // سحب للأعلى للتثبيت
              else if (dy < -80) {
                setState(() {
                  _isVoiceLocked = true;
                });
              }
            }
          },
          onLongPressEnd: (_) {
            if (_isRecordingVoice && !_isVoiceLocked) {
              _stopVoiceRecording();
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isRecordingVoice ? Colors.red : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isRecordingVoice ? Icons.stop : Icons.mic,
              color: _isRecordingVoice ? Colors.white : Colors.red,
            ),
          ),
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
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}