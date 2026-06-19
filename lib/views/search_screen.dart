// lib/views/search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/user_search_service.dart';
import '../../controllers/auth_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserSearchService _searchService = UserSearchService();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String _searchType = 'name';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> results = [];
      if (_searchType == 'name') {
        results = await _searchService.searchByName(query);
      } else {
        final result = await _searchService.searchByPhone(query);
        if (result != null) results = [result];
      }
      setState(() => _results = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startChat(String userId, String name) async {
    // ✅ استخدم id بدلاً من uid
    final currentUserId = ref.read(authControllerProvider).currentUser?.id;
    if (currentUserId == null) return;
    
    final chatId = [currentUserId, userId]..sort();
    final chatIdStr = '${chatId[0]}_${chatId[1]}';
    
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/chat',
        arguments: {
          'chatId': chatIdStr,
          'receiverId': userId,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'ابحث عن مستخدم...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'name', label: Text('بالاسم')),
                    ButtonSegment(value: 'phone', label: Text('برقم الهاتف')),
                  ],
                  selected: {_searchType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _searchType = newSelection.first;
                      _results.clear();
                      _searchController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const Center(child: Text('لا توجد نتائج'))
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user['name'][0].toUpperCase()),
                      ),
                      title: Text(user['name']),
                      subtitle: Text(user['phone'] ?? ''),
                      trailing: ElevatedButton(
                        onPressed: () => _startChat(user['id'], user['name']),
                        child: const Text('مراسلة'),
                      ),
                    );
                  },
                ),
    );
  }
}