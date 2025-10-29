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
      _showSnackBar(ok ? 'Đã gửi yêu cầu kết bạn' : 'Lỗi gửi yêu cầu', ok);
    } catch (_) {
      _showSnackBar('Lỗi kết nối', false);
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
        _showSnackBar('Đã chấp nhận kết bạn', true);
      } else {
        _showSnackBar('Không thể chấp nhận', false);
      }
    } catch (_) {
      _showSnackBar('Lỗi kết nối', false);
    }
  }

  Future<void> _removeFriend(String friend) async {
    try {
      await http.post(Uri.parse('$baseUrl/friend-remove'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': widget.username, 'friend': friend}));
      await _load();
      _showSnackBar('Đã xóa bạn bè', true);
    } catch (_) {
      _showSnackBar('Lỗi kết nối', false);
    }
  }

  Future<void> _blockUser(String target) async {
    try {
      await http.post(Uri.parse('$baseUrl/block'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'by': widget.username, 'target': target}));
      await _load();
      _showSnackBar('Đã chặn người dùng', true);
    } catch (_) {
      _showSnackBar('Lỗi kết nối', false);
    }
  }

  void _showSnackBar(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Kết quả tìm kiếm (${searchResults.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: searchResults.length,
              itemBuilder: (_, i) {
                final u = searchResults[i];
                final uname = u['username'] ?? '';
                final display = (u['displayName'] ?? uname) as String;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        display.isNotEmpty ? display[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    title: Text(
                      display,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    subtitle: Text(
                      '@$uname',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    trailing: FilledButton.icon(
                      onPressed: () => _sendFriendRequest(uname),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Kết bạn'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsAndFriends() {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Friend Requests Section
            if (requests.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade50, Colors.orange.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yêu cầu kết bạn',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${requests.length} yêu cầu đang chờ',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              for (var r in requests)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.orange.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.orange.shade100,
                      child: Text(
                        r.toString().isNotEmpty ? r.toString()[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                    title: Text(
                      r.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    subtitle: Text(
                      'Muốn kết bạn với bạn',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    trailing: FilledButton.icon(
                      onPressed: () => _acceptRequest(r),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Chấp nhận'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // Friends List Section
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.people, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Danh sách bạn bè',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${friends.length} bạn bè',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (friends.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có bạn bè',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tìm kiếm và kết bạn với mọi người',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            for (var f in friends)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      f.toString().isNotEmpty ? f.toString()[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                  title: Text(
                    f.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: Text(
                    'Bạn bè',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.person_remove, color: Colors.orange.shade700),
                        onPressed: () => _removeFriend(f),
                        tooltip: 'Xóa bạn',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.orange.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.block, color: Colors.red.shade700),
                        onPressed: () => _blockUser(f),
                        tooltip: 'Chặn',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Bạn bè',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Làm mới',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm bạn bè...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (v) => _searchUsers(v.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                if (searchResults.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() => searchResults = []);
                      searchCtrl.clear();
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
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