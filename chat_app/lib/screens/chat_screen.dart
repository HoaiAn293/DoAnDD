import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart';
import 'profile_screen.dart';
import 'upload_image.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final String username;
  final String groupId;
  const ChatScreen(this.username, this.groupId, {Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late IO.Socket socket;
  final TextEditingController messageCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();
  List<Map<String, dynamic>> messages = [];
  List<String> members = [];
  bool isTyping = false;
  final String baseUrl = "http://10.0.2.2:3000";

  @override
  void initState() {
    super.initState();
    _initSocket();
    _fetchMessages();
  }

  void _initSocket() {
    socket = IO.io(
      baseUrl,
      IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint("Socket connected: ${socket.id}");
      socket.emit('joinGroup', {
        'groupId': widget.groupId,
        'username': widget.username,
      });
    });

    socket.on('message', (data) {
      final msg = Map<String, dynamic>.from(data);
      if (msg['groupId'] == widget.groupId) {
        setState(() => messages.add(msg));
        _scrollToBottom();
      }
    });

    socket.on('status', (data) {
      if (data is Map && data['groupId'] == widget.groupId) {
        setState(() {
          messages.add({
            'isSystem': true,
            'message': data['message'],
            'time': DateTime.now().toIso8601String(),
          });
        });
        _scrollToBottom();
      }
    });

    socket.on('members', (data) {
      if (data is List) {
        setState(() => members = data.map((e) => e.toString()).toList());
      }
    });

    socket.on('typing', (data) {
      if (data['groupId'] == widget.groupId &&
          data['username'] != widget.username) {
        setState(() => isTyping = data['typing'] == true);
      }
    });

    socket.onDisconnect((_) => debugPrint('Socket disconnected'));
  }

  Future<void> _fetchMessages() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/messages/${widget.groupId}'));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() => messages = data.map((e) => Map<String, dynamic>.from(e)).toList());
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Lỗi tải tin nhắn: $e");
    }
  }

  void sendMessage() {
    final text = messageCtrl.text.trim();
    if (text.isEmpty) return;

    final payload = {
      'groupId': widget.groupId,
      'username': widget.username,
      'message': text,
      'image': null,
      'time': DateTime.now().toIso8601String(),
    };

    socket.emit('message', payload);
    messageCtrl.clear();
    _scrollToBottom();
  }

  String _formatTime(dynamic timeValue) {
    try {
      DateTime dt = DateTime.tryParse(timeValue?.toString() ?? '') ?? DateTime.now();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  void _sendImage(String url) {
    final payload = {
      'groupId': widget.groupId,
      'username': widget.username,
      'message': '',
      'image': url,
      'time': DateTime.now().toIso8601String(),
    };
    socket.emit('message', payload);
    setState(() => messages.add(payload));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(
          scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    socket.emit('leaveGroup', {
      'groupId': widget.groupId,
      'username': widget.username,
    });
    socket.dispose();
    super.dispose();
  }

  void _showMembersDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    "Thành viên",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${members.length}',
                      style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isMe = member == widget.username;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isMe ? const Color(0xFF6C63FF) : Colors.grey[300],
                      child: Text(
                        member[0].toUpperCase(),
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      member,
                      style: TextStyle(
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isMe
                        ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Bạn',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      if (!isMe) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(username: member),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8E85FF)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phòng ${widget.groupId}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${members.length} thành viên',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline, color: Colors.black87),
            onPressed: _showMembersDialog,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(username: widget.username),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Chưa có tin nhắn nào",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Hãy bắt đầu cuộc trò chuyện!",
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isSystem = msg['isSystem'] ?? false;

                if (isSystem) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg['message'],
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }

                final sender = msg['username'] ?? 'unknown';
                final isMe = sender == widget.username;
                final message = msg['message'] ?? '';
                final img = msg['image'];
                final time = _formatTime(msg['time']);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isMe) ...[
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileScreen(username: sender),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[300],
                            child: Text(
                              sender[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(left: 12, bottom: 4),
                                child: Text(
                                  sender,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: isMe
                                    ? const LinearGradient(
                                  colors: [Color(0xFF6C63FF), Color(0xFF8E85FF)],
                                )
                                    : null,
                                color: isMe ? null : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 18),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (img != null && img.toString().isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        img,
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  if (message.isNotEmpty)
                                    Text(
                                      message,
                                      style: TextStyle(
                                        color: isMe ? Colors.white : Colors.black87,
                                        fontSize: 15,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                              child: Text(
                                time,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(3, (index) {
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, -4 * (1 - (value - index * 0.2).abs().clamp(0.0, 1.0))),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6C63FF),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                            onEnd: () => setState(() {}),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Color(0xFF6C63FF), size: 22),
                        onPressed: () async {
                          final url = await uploadImage(fromCamera: true);
                          if (url != null) _sendImage(url);
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.photo, color: Color(0xFF6C63FF), size: 22),
                        onPressed: () async {
                          final url = await uploadImage(fromCamera: false);
                          if (url != null) _sendImage(url);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: messageCtrl,
                          decoration: const InputDecoration(
                            hintText: "Nhắn tin...",
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (v) {
                            socket.emit('typing', {
                              'groupId': widget.groupId,
                              'username': widget.username,
                              'typing': v.trim().isNotEmpty,
                            });
                          },
                          onSubmitted: (_) => sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF8E85FF)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}