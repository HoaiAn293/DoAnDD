import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatService {
  IO.Socket socket = IO.io('http://10.0.2.2:3000', IO.OptionBuilder()
      .setTransports(['websocket'])
      .build());

  void joinGroup(String groupId) => socket.emit('joinGroup', groupId);

  void sendMessage(String groupId, String message, [String? imageUrl]) {
    socket.emit('message', {'groupId': groupId, 'message': message, 'image': imageUrl});
  }

  void listenMessages(void Function(dynamic) callback) => socket.on('message', callback);
  void listenStatus(void Function(dynamic) callback) => socket.on('status', callback);
}
