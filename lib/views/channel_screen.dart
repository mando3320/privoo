// lib/views/channel_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/channel_service.dart';
import '../../models/channel_model.dart';
import '../../controllers/auth_controller.dart';
import 'chat/smart_chat_screen.dart';

class ChannelScreen extends ConsumerStatefulWidget {
  final String channelId;

  const ChannelScreen({super.key, required this.channelId});

  @override
  ConsumerState<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends ConsumerState<ChannelScreen> {
  final ChannelService _channelService = ChannelService();
  late Future<ChannelModel> _channelFuture;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _loadChannel();
  }

  Future<void> _loadChannel() async {
    _channelFuture = _channelService.getChannel(widget.channelId);
    final channel = await _channelFuture;
    // ✅ استخدم id بدلاً من uid
    final userId = ref.read(authControllerProvider).currentUser?.id;
    setState(() {
      _isSubscribed = channel.subscribers.contains(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChannelModel>(
      future: _channelFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('خطأ: ${snapshot.error}')),
          );
        }

        final channel = snapshot.data!;
        // ✅ استخدم id بدلاً من uid
        final userId = ref.read(authControllerProvider).currentUser?.id;
        final isOwner = channel.ownerId == userId;

        return Scaffold(
          appBar: AppBar(
            title: Text(channel.name),
            actions: [
              if (!_isSubscribed && !isOwner)
                TextButton(
                  onPressed: () async {
                    final ctx = context;
                    await _channelService.subscribeToChannel(widget.channelId);
                    await _loadChannel();
                    if (!mounted) return;
                    setState(() => _isSubscribed = true);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('تم الاشتراك في القناة')),
                    );
                  },
                  child: const Text('اشترك'),
                ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await _channelService.deleteChannel(widget.channelId, userId!);
                    if (mounted) Navigator.pop(context);
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade100,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        channel.name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      channel.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(channel.description),
                    const SizedBox(height: 8),
                    Text('${channel.subscribers.length} مشترك'),
                  ],
                ),
              ),
              if (_isSubscribed || isOwner)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SmartChatScreen(
                            chatId: widget.channelId,
                            receiverId: '',
                            isChannel: true,
                            channelId: widget.channelId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('دخول القناة'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}