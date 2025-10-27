import 'package:flutter/material.dart';
import '../screens/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> rooms = [];

  void _showCreateRoomDialog() {
    final TextEditingController roomNameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    String roomType = 'public';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Tạo phòng mới',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: roomNameController,
                  decoration: InputDecoration(
                    labelText: 'Tên phòng',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.meeting_room_outlined),
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: roomType,
                  decoration: InputDecoration(
                    labelText: 'Loại phòng',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'public', child: Text('Công khai 🌐')),
                    DropdownMenuItem(value: 'private', child: Text('Riêng tư 🔒')),
                  ],
                  onChanged: (val) => setStateDialog(() => roomType = val!),
                ),
                if (roomType == 'private') ...[
                  const SizedBox(height: 15),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu phòng',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (roomNameController.text.trim().isEmpty) return;
                    if (roomType == 'private' &&
                        passwordController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Phòng riêng tư cần có mật khẩu'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      rooms.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'name': roomNameController.text.trim(),
                        'type': roomType,
                        'password': roomType == 'private'
                            ? passwordController.text.trim()
                            : null,
                        'creator': widget.username,
                      });
                    });

                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Tạo phòng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _joinRoom(Map<String, dynamic> room) {
    if (room['type'] == 'private') {
      _showPasswordDialog(room);
    } else {
      _navigateToChat(room);
    }
  }

  void _showPasswordDialog(Map<String, dynamic> room) {
    final TextEditingController passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nhập mật khẩu phòng'),
        content: TextField(
          controller: passController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Mật khẩu',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (passController.text == room['password']) {
                Navigator.pop(context);
                _navigateToChat(room);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sai mật khẩu phòng 🔒'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007AFF)),
            child: const Text('Vào phòng'),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(Map<String, dynamic> room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(widget.username, room['id']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF007AFF),
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              'Xin chào, ${widget.username}',
              style: const TextStyle(color: Colors.black87, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout, color: Colors.grey),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRoomDialog,
        backgroundColor: const Color(0xFF007AFF),
        child: const Icon(Icons.add, size: 30),
      ),
      body: rooms.isEmpty
          ? const Center(
        child: Text(
          'Chưa có phòng nào.\nNhấn + để tạo phòng mới!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: room['type'] == 'public'
                    ? Colors.greenAccent
                    : Colors.redAccent,
                child: Icon(
                  room['type'] == 'public'
                      ? Icons.public
                      : Icons.lock_outline,
                  color: Colors.white,
                ),
              ),
              title: Text(
                room['name'],
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              subtitle: Text(
                room['type'] == 'public'
                    ? 'Phòng công khai 🌐'
                    : 'Phòng riêng tư 🔒',
                style: TextStyle(
                  color: room['type'] == 'public'
                      ? Colors.green[700]
                      : Colors.red[700],
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF007AFF)),
                onPressed: () => _joinRoom(room),
              ),
            ),
          );
        },
      ),
    );
  }
}
