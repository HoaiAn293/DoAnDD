import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FriendsScreen extends StatefulWidget {
  final String username;
  const FriendsScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final String baseUrl = 'http://10.0.2.2:3000';
  bool loading = true;
  List<dynamic> friends = [];
  List<dynamic> requests = [];
  final TextEditingController searchCtrl = TextEditingController();
  List<dynamic> searchResults = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      searchResults = [];
    });

    try {
      final res = await http.get(Uri.parse('$baseUrl/profile/${widget.username}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        friends = List<dynamic>.from(data['friends'] ?? []);
      } else {
        friends = [];
      }

      final rres = await http.get(Uri.parse('$baseUrl/friend-requests/${widget.username}'));
      if (rres.statusCode == 200) {
        requests = List<dynamic>.from(jsonDecode(rres.body)['pending'] ?? []);
      } else {
        requests = [];
      }
    } catch (_) {
      friends = [];
      requests = [];
    }

    setState(() => loading = false);
  }

  Future<void> _searchUsers(String q) async {
    if (q.trim().isEmpty) {
      setState(() => searchResults = []);
      return;
    }
    try {
      final res = await http.get(Uri.parse('$baseUrl/users?q=${Uri.encodeComponent(q)}'));
      if (res.statusCode == 200) {
        setState(() => searchResults = jsonDecode(res.body));
      } else {
        setState(() => searchResults = []);
      }
    } catch (_) {
      setState(() => searchResults = []);
    }
  }

  Future<void> _sendFriendRequest(String to) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/friend-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'from': widget.username, 'to': to}),
      );
      final ok = res.statusCode == 200;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Đã gửi yêu cầu' : 'Lỗi gửi yêu cầu')));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi kết nối')));
    }
  }

  Future<void> _acceptRequest(String from) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/friend-accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'from': from, 'to': widget.username}),
      );
      if (res.statusCode == 200) {
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chấp nhận')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể chấp nhận')));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi kết nối')));
    }
  }

  Future<void> _removeFriend(String friend) async {
    try {
      await http.post(Uri.parse('$baseUrl/friend-remove'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': widget.username, 'friend': friend}));
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa bạn')));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi kết nối')));
    }
  }

  Future<void> _blockUser(String target) async {
    try {
      await http.post(Uri.parse('$baseUrl/block'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'by': widget.username, 'target': target}));
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chặn người dùng')));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi kết nối')));
    }
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Widget _buildSearchResults() {
    if (searchResults.isEmpty) {
      return const SizedBox.shrink();
    }
    return Expanded(
      child: ListView.builder(
        itemCount: searchResults.length,
        itemBuilder: (_, i) {
          final u = searchResults[i];
          final uname = u['username'] ?? '';
          final display = (u['displayName'] ?? uname) as String;
          return ListTile(
            leading: CircleAvatar(child: Text(display.isNotEmpty ? display[0].toUpperCase() : '?')),
            title: Text(display),
            subtitle: Text(uname),
            trailing: ElevatedButton(
              child: const Text('Kết bạn'),
              onPressed: () => _sendFriendRequest(uname),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestsAndFriends() {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Yêu cầu kết bạn', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (requests.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Không có yêu cầu'),
              ),
            for (var r in requests)
              ListTile(
                title: Text(r),
                trailing: ElevatedButton(onPressed: () => _acceptRequest(r), child: const Text('Chấp nhận')),
              ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Danh sách bạn bè', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (friends.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Chưa có bạn bè'),
              ),
            for (var f in friends)
              ListTile(
                title: Text(f),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.person_off), onPressed: () => _removeFriend(f)),
                    IconButton(icon: const Icon(Icons.block), onPressed: () => _blockUser(f)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bạn bè'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          decoration: const InputDecoration(hintText: 'Tìm người bằng tên hoặc hiển thị'),
                          onSubmitted: (v) => _searchUsers(v.trim()),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.search), onPressed: () => _searchUsers(searchCtrl.text.trim())),
                      if (searchResults.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => searchResults = []);
                            searchCtrl.clear();
                          },
                        ),
                    ],
                  ),
                ),
                if (searchResults.isNotEmpty) _buildSearchResults() else _buildRequestsAndFriends(),
              ],
            ),
    );
  }
}