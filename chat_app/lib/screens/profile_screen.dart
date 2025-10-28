import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  final String username;
  const ProfileScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String baseUrl = 'http://10.0.2.2:3000';
  bool loading = true;
  Map<String, dynamic>? profile;
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController statusCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => loading = true);
    final res = await http.get(Uri.parse('$baseUrl/profile/${widget.username}'));
    if (res.statusCode == 200) {
      profile = jsonDecode(res.body);
      nameCtrl.text = profile?['displayName'] ?? '';
      statusCtrl.text = profile?['status'] ?? '';
    }
    setState(() => loading = false);
  }

  Future<void> _saveProfile() async {
    final res = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': widget.username,
        'displayName': nameCtrl.text.trim(),
        'status': statusCtrl.text.trim()
      }),
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công')));
      _loadProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi cập nhật')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            CircleAvatar(radius: 40, child: Text((profile?['displayName'] ?? '').substring(0,1))),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên hiển thị')),
            const SizedBox(height: 8),
            TextField(controller: statusCtrl, decoration: const InputDecoration(labelText: 'Trạng thái')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _saveProfile, child: const Text('Lưu'))
          ],
        ),
      ),
    );
  }
}