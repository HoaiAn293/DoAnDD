import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart';
import 'profile_screen.dart';
import 'upload_image.dart';

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
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    socket = IO.io(
      'http://10.0.2.2:3000',
      IO.OptionBuilder().setTransports(['websocket']).enableAutoConnect().build(),
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('Socket connected: ${socket.id}');
      socket.emit('joinGroup', {'groupId': widget.groupId, 'username': widget.username});
    });

    socket.onConnectError((err) => debugPrint('ConnectError: $err'));
    socket.onError((err) => debugPrint('SocketError: $err'));
    socket.onDisconnect((_) => debugPrint('Socket disconnected'));

    socket.on('status', (data) {
      setState(() {
        messages.add({
          'isSystem': true,
          'message': data.toString(),
          'time': DateTime.now().toIso8601String(),
        });
      });
      _scrollToBottom();
    });

    socket.on('message', (data) {
      setState(() {
        messages.add({
          'isSystem': false,
          'sender': data['sender'] ?? data['username'] ?? 'unknown',
          'message': data['message'] ?? data['text'] ?? '',
          'image': data['image'],
          'time': DateTime.now().toIso8601String(),
        });
      });
      _scrollToBottom();
    });

    socket.on('typing', (data) {
      if (data['groupId'] == widget.groupId && data['username'] != widget.username) {
        setState(() {
          isTyping = data['typing'] == true;
        });
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(
          scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void sendMessage() {
    final text = messageCtrl.text.trim();
    if (text.isEmpty) return;
    final payload = {
      'groupId': widget.groupId,
      'username': widget.username,
      'message': text,
    };
    if (socket.connected) socket.emit('message', payload);
    setState(() {
      messages.add({
        'isSystem': false,
        'sender': widget.username,
        'message': text,
        'time': DateTime.now().toIso8601String(),
      });
    });
    messageCtrl.clear();
    _scrollToBottom();
  }

  String _formatTime(dynamic timeValue) {
    try {
      DateTime dt;
      if (timeValue is DateTime) dt = timeValue;
      else dt = DateTime.tryParse(timeValue?.toString() ?? '') ?? DateTime.now();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        elevation: 1,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Group Chat', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(username: widget.username)));
            },
          ),
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
                        Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Chưa có tin nhắn nào', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isSystem = msg['isSystem'] ?? false;
                      if (isSystem) {
                        return _buildSystemMessage(msg['message'] ?? '');
                      }

                      final sender = msg['sender'] ?? '';
                      final isMe = sender == widget.username;
                      final time = msg['time'];
                      final imageUrl = (msg['image']?.toString() ?? '').isNotEmpty ? msg['image'].toString() : null;
                      final messageText = msg['message'] ?? '';

                      return _buildChatBubble(
                        sender: sender,
                        message: messageText,
                        timeStr: time,
                        isMe: isMe,
                        imageUrl: imageUrl,
                      );
                    },
                  ),
          ),
          if (isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Align(alignment: Alignment.centerLeft, child: Text('Đang nhập...', style: TextStyle(color: Colors.grey[600]))),
            ),
          Container(
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(icon: Icon(Icons.emoji_emotions_outlined, color: const Color(0xFF7F8C8D)), onPressed: () {}),
                  IconButton(
                    icon: const Icon(Icons.image_outlined, color: Color(0xFF7F8C8D)),
                    onPressed: () async {
                      final url = await uploadImage();
                      if (url != null) {
                        final payload = {'groupId': widget.groupId, 'username': widget.username, 'message': '', 'image': url};
                        if (socket.connected) socket.emit('message', payload);
                        setState(() {
                          messages.add({'isSystem': false, 'sender': widget.username, 'message': '', 'image': url, 'time': DateTime.now().toIso8601String()});
                        });
                        _scrollToBottom();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không chọn ảnh')));
                      }
                    },
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: messageCtrl,
                        decoration: const InputDecoration(hintText: 'Nhập tin nhắn...', border: InputBorder.none, hintStyle: TextStyle(color: Color(0xFF95A5A6))),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (v) {
                          if (socket.connected) socket.emit('typing', {'groupId': widget.groupId, 'username': widget.username, 'typing': v.trim().isNotEmpty});
                        },
                        onSubmitted: (_) => sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF3949AB), Color(0xFF5E35B1)]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFF3949AB).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22), onPressed: sendMessage),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(16)),
        child: Text(message, style: TextStyle(color: Colors.grey[700], fontSize: 12), textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildChatBubble({
    required String sender,
    required String message,
    required dynamic timeStr,
    required bool isMe,
    String? imageUrl,
  }) {
    final timeText = _formatTime(timeStr);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(padding: const EdgeInsets.only(left: 12, bottom: 4), child: Text(sender, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3949AB)))),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(radius: 16, backgroundColor: const Color(0xFF3949AB).withOpacity(0.1), child: Text(sender.isNotEmpty ? sender[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFF3949AB), fontWeight: FontWeight.bold, fontSize: 14))),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isMe ? const LinearGradient(colors: [Color(0xFF3949AB), Color(0xFF5E35B1)]) : null,
                    color: isMe ? null : Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(isMe ? 20 : 4), topRight: Radius.circular(isMe ? 4 : 20), bottomLeft: const Radius.circular(20), bottomRight: const Radius.circular(20)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                            maxHeight: 300,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => Container(height: 140, color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image))),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(height: 140, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
                              },
                            ),
                          ),
                        ),
                      if (message.isNotEmpty) const SizedBox(height: 6),
                      if (message.isNotEmpty) Text(message, style: TextStyle(color: isMe ? Colors.white : const Color(0xFF2C3E50), fontSize: 15, height: 1.4)),
                    ],
                  ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 8),
                Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(timeText, style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
              ],
            ],
          ),
          if (!isMe) Padding(padding: const EdgeInsets.only(left: 48, top: 4), child: Text(timeText, style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    try {
      socket.dispose();
    } catch (_) {}
    messageCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }
}