import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatService {
  IO.Socket socket = IO.io(
    'http://10.0.2.2:3000',
    IO.OptionBuilder().setTransports(['websocket']).enableAutoConnect().build(),
  );

  void connect() => socket.connect();

  void joinGroup(String groupId, String username) =>
    socket.emit('joinGroup', {'groupId': groupId, 'username': username});

  void sendMessage(String groupId, String username, String message, [String? imageUrl]) {
    final payload = {
      'groupId': groupId,
      'username': username,
      'message': message,
      'image': imageUrl
    };
    socket.emit('message', payload);
  }

  void typing(String groupId, String username, bool isTyping) {
    socket.emit('typing', {'groupId': groupId, 'username': username, 'typing': isTyping});
  }

  void listenMessages(void Function(dynamic) callback) => socket.on('message', callback);
  void listenStatus(void Function(dynamic) callback) => socket.on('status', callback);
  void listenTyping(void Function(dynamic) callback) => socket.on('typing', callback);
}