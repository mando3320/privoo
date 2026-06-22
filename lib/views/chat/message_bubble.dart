// lib/views/chat/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import '../../main.dart';
import '../../services/tts_service.dart';
import '../../services/ai/ai_service.dart';
import '../../services/text_formatter.dart';
import '../../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isBot;
  final String senderName;
  final VoidCallback? onPin;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final bool isPinned;
  final void Function(String)? onReaction;
  final VoidCallback? onDownload;  // ✅ إضافة callback للتحميل

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isBot,
    required this.senderName,
    this.onPin,
    this.onReply,
    this.onDelete,
    this.isPinned = false,
    this.onReaction,
    this.onDownload,  // ✅ إضافة
  });

  Color _getBubbleColor(BuildContext context) {
    if (isPinned) return Colors.amber.shade100;
    if (isBot) return Colors.deepPurple.shade50;
    if (isMe) return Theme.of(context).primaryColor.withValues(alpha: 0.8);
    return Colors.grey.shade300;
  }

  BorderRadiusGeometry _getBorderRadius() {
    const radius = Radius.circular(16);
    return BorderRadius.only(
      topLeft: radius,
      topRight: radius,
      bottomLeft: isMe ? radius : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : radius,
    );
  }

  Widget _buildReplyPreview() {
    if (message.replyToMessageId == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '↩️ ${message.replyToSenderId == 'PRIVOO_BOT' ? 'Privoo 🤖' : 'الرد على رسالة'}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            message.replyToContent ?? '',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMentions() {
    if (message.mentions == null || message.mentions!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 4,
        children: message.mentions!.map((mention) => Text(
          '@$mention',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildReactions() {
    if (message.reactions == null || message.reactions!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: message.reactions!.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${entry.key} ${entry.value}',
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showTranslationDialog(BuildContext context, String text) async {
    final language = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر لغة الترجمة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('العربية'), onTap: () => Navigator.pop(context, 'ar')),
            ListTile(title: const Text('English'), onTap: () => Navigator.pop(context, 'en')),
            ListTile(title: const Text('Français'), onTap: () => Navigator.pop(context, 'fr')),
          ],
        ),
      ),
    );
    
    if (language != null && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('جاري الترجمة...'),
          content: SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
        ),
      );
      
      final aiService = AIService();
      final translated = await aiService.translate(text, language);
      
      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('الترجمة إلى ${language == 'ar' ? 'العربية' : language}'),
            content: SelectableText(translated),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
            ],
          ),
        );
      }
    }
  }

  Widget _reactionButton(String emoji, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (onReaction != null) {
          onReaction!(emoji);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(message.timestamp).format(context);

    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onReaction != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _reactionButton('👍', context),
                        _reactionButton('❤️', context),
                        _reactionButton('😂', context),
                        _reactionButton('😮', context),
                        _reactionButton('😢', context),
                        _reactionButton('🙏', context),
                      ],
                    ),
                  ),
                if (onReply != null)
                  ListTile(
                    leading: const Icon(Icons.reply),
                    title: const Text('رد'),
                    onTap: () {
                      Navigator.pop(context);
                      onReply!.call();
                    },
                  ),
                if (onPin != null)
                  ListTile(
                    leading: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                    title: Text(isPinned ? 'إلغاء التثبيت' : 'تثبيت'),
                    onTap: () {
                      Navigator.pop(context);
                      onPin!.call();
                    },
                  ),
                if (onDelete != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('حذف', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      onDelete!.call();
                    },
                  ),
                if (isBot && !isMe)
                  ListTile(
                    leading: const Icon(Icons.translate, color: Colors.blue),
                    title: const Text('ترجمة'),
                    onTap: () {
                      Navigator.pop(context);
                      _showTranslationDialog(context, message.content);
                    },
                  ),
                // ✅ خيار تحميل الملفات
                if (onDownload != null && (message.type == MessageType.file || 
                    message.type == MessageType.image || 
                    message.type == MessageType.video || 
                    message.type == MessageType.audio))
                  ListTile(
                    leading: const Icon(Icons.download, color: Colors.blue),
                    title: const Text('تحميل الملف'),
                    onTap: () {
                      Navigator.pop(context);
                      onDownload!.call();
                    },
                  ),
              ],
            ),
          ),
        );
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 2, left: 8, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPinned)
                      const Icon(Icons.push_pin, size: 12, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isBot ? Colors.deepPurple : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (message.disappearAfterSeconds != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '⏱️ تختفي بعد ${message.disappearAfterSeconds! ~/ 60 ~/ 60}h',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              Material(
                elevation: 1,
                color: _getBubbleColor(context),
                borderRadius: _getBorderRadius(),
                child: Padding(
                  padding: message.type == MessageType.text
                      ? const EdgeInsets.symmetric(vertical: 10, horizontal: 14)
                      : const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReplyPreview(),
                      _buildMentions(),
                      _buildMessageContent(context),
                      _buildReactions(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                child: Text(
                  time,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: message.content,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox(
              width: 200,
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => const Text(
              "❌ فشل تحميل الصورة",
              style: TextStyle(color: Colors.red),
            ),
          ),
        );

      case MessageType.gif:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: message.content,
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            placeholder: (context, url) => const SizedBox(
              width: 200,
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => const Text(
              "❌ فشل تحميل GIF",
              style: TextStyle(color: Colors.red),
            ),
          ),
        );

      case MessageType.video:
        return _VideoPlayerWidget(url: message.content);

      case MessageType.audio:
      case MessageType.voice:
        final color = isMe ? Colors.white : Theme.of(context).primaryColor;
        return _VoiceMessageBubble(audioUrl: message.content, iconColor: color);

      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, size: 28, color: isMe ? Colors.white : Colors.black54),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                Uri.parse(message.content).pathSegments.last,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isMe ? Colors.white : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // ✅ زر تحميل الملف
            IconButton(
              icon: Icon(Icons.download, size: 18, color: isMe ? Colors.white : Colors.blue),
              onPressed: onDownload,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'تحميل الملف',
            ),
          ],
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              TextFormatter.format(message.content),
              style: const TextStyle(fontSize: 14),
            ),
            if (isBot)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.volume_up, size: 20, color: Colors.deepPurple),
                  tooltip: 'تشغيل الرد صوتيًا',
                  onPressed: () async {
                    try {
                      await TTSService.speak(message.content, language: 'ar');
                    } catch (e) {
                      logger.e("❌ فشل تشغيل TTS: $e");
                    }
                  },
                ),
              ),
          ],
        );
    }
  }
}

// 🎞️ مشغل الفيديو
class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({required this.url});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitializing = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitializing = false;
            });
          }
        }).catchError((e) {
          logger.e("❌ فشل تهيئة مشغل الفيديو: $e");
          if (mounted) setState(() => _hasError = true);
        });
    } catch (e) {
      logger.e("❌ خطأ URL غير صالح للفيديو: $e");
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Text("❌ لا يمكن تشغيل الفيديو.", style: TextStyle(color: Colors.red));
    }

    if (_isInitializing || !_controller.value.isInitialized) {
      return const SizedBox(
        width: 200,
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      width: 200,
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),
              Positioned.fill(
                child: Center(
                  child: IconButton(
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 60,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🎤 رسالة صوتية
class _VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final Color iconColor;
  const _VoiceMessageBubble({required this.audioUrl, required this.iconColor});

  @override
  State<_VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<_VoiceMessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool _isBuffering = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() async {
    try {
      await _player.setUrl(widget.audioUrl);
      if (mounted) {
        setState(() {
          duration = _player.duration ?? Duration.zero;
          _isBuffering = false;
        });
      }

      _player.positionStream.listen((pos) {
        if (mounted) setState(() => position = pos);
      });

      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() {
              isPlaying = false;
              position = Duration.zero;
            });
            _player.seek(Duration.zero);
          }
        }
      });
    } catch (e) {
      logger.e("❌ فشل تهيئة مشغل الصوت: $e");
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void togglePlay() async {
    if (_hasError || _isBuffering) return;
    if (isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
    if (mounted) setState(() => isPlaying = !isPlaying);
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds == 0) return "0:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Text("❌ فشل تشغيل الصوت.", style: TextStyle(color: Colors.red));
    }

    if (_isBuffering) {
      return const SizedBox(
        width: 150,
        child: Center(child: LinearProgressIndicator()),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: widget.iconColor),
          onPressed: togglePlay,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: duration.inMilliseconds == 0
                    ? 0
                    : position.inMilliseconds / duration.inMilliseconds,
                backgroundColor: Colors.grey.shade400,
                valueColor: AlwaysStoppedAnimation<Color>(widget.iconColor),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}