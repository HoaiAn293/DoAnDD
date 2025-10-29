import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatService {
  late IO.Socket socket;

  ChatService(String url) {
    socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );
  }

  void connect() => socket.connect();

  void disconnect() => socket.disconnect();

  void joinGroup(String groupId, String username) {
    socket.emit('joinGroup', {'groupId': groupId, 'username': username});
  }

  void leaveGroup(String groupId, String username) {
    socket.emit('leaveGroup', {'groupId': groupId, 'username': username});
  }

  void sendMessage(String groupId, String username, String message, [String? imageUrl]) {
    final payload = {
      'groupId': groupId,
      'username': username,
      'message': message,
      'image': imageUrl,
      'time': DateTime.now().toIso8601String(),
    };
    socket.emit('message', payload);
  }

  void typing(String groupId, String username, bool isTyping) {
    socket.emit('typing', {'groupId': groupId, 'username': username, 'typing': isTyping});
  }

  // Listeners
  void onChatHistory(void Function(List<dynamic>) callback) {
    socket.on('chatHistory', (data) {
      callback(List<dynamic>.from(data));
    });
  }

  void onMessage(void Function(Map<String, dynamic>) callback) {
    socket.on('message', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  void onStatus(void Function(Map<String, dynamic>) callback) {
    socket.on('status', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  void onTyping(void Function(Map<String, dynamic>) callback) {
    socket.on('typing', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  void onRoomInfo(void Function(Map<String, dynamic>) callback) {
    socket.on('roomInfo', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }
}
