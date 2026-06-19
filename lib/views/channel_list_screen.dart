// lib/views/channel_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/channel_service.dart';
import '../../models/channel_model.dart';
import '../../controllers/auth_controller.dart';
import 'create_channel_screen.dart';
import 'channel_screen.dart';

class ChannelListScreen extends ConsumerStatefulWidget {
  const ChannelListScreen({super.key});

  @override
  ConsumerState<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends ConsumerState<ChannelListScreen> {
  final ChannelService _channelService = ChannelService();
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    // ✅ استخدم id بدلاً من uid
    final userId = ref.read(authControllerProvider).currentUser?.id;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('القنوات'),
        bottom: TabBar(
          tabs: const [
            Tab(text: 'قنواتي'),
            Tab(text: 'قنوات عامة'),
          ],
          onTap: (index) => setState(() => _selectedTab = index),
        ),
      ),
      body: _selectedTab == 0
          ? _buildMyChannels(userId ?? '')
          : _buildPublicChannels(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateChannelScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMyChannels(String userId) {
    return StreamBuilder<List<ChannelModel>>(
      stream: _channelService.getUserChannels(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final channels = snapshot.data ?? [];
        
        if (channels.isEmpty) {
          return const Center(child: Text('لا توجد قنوات بعد'));
        }
        
        return ListView.builder(
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(channel.name[0].toUpperCase()),
              ),
              title: Text(channel.name),
              subtitle: Text('${channel.subscribers.length} مشترك'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChannelScreen(channelId: channel.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPublicChannels() {
    return StreamBuilder<List<ChannelModel>>(
      stream: _channelService.getPublicChannels(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final channels = snapshot.data ?? [];
        
        if (channels.isEmpty) {
          return const Center(child: Text('لا توجد قنوات عامة'));
        }
        
        return ListView.builder(
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index];
            // ✅ استخدم id بدلاً من uid
            final currentUserId = ref.read(authControllerProvider).currentUser?.id;
            final isSubscribed = channel.subscribers.contains(currentUserId);
            
            return ListTile(
              leading: CircleAvatar(
                child: Text(channel.name[0].toUpperCase()),
              ),
              title: Text(channel.name),
              subtitle: Text('${channel.subscribers.length} مشترك'),
              trailing: isSubscribed
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : ElevatedButton(
                      onPressed: () => _subscribe(channel.id),
                      child: const Text('اشترك'),
                    ),
              onTap: isSubscribed
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChannelScreen(channelId: channel.id),
                        ),
                      );
                    }
                  : null,
            );
          },
        );
      },
    );
  }

  Future<void> _subscribe(String channelId) async {
    await _channelService.subscribeToChannel(channelId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم الاشتراك في القناة')),
    );
  }
}