import 'dart:convert';
import 'package:http/http.dart' as http;

class RoomService {
  final String baseUrl = 'http://localhost:3000';

  Future<List<Map<String, dynamic>>> getRooms() async {
    final res = await http.get(Uri.parse('$baseUrl/rooms'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } else {
      throw Exception('Lỗi tải danh sách phòng');
    }
  }

  Future<Map<String, dynamic>> createRoom(String name, String type) async {
    final res = await http.post(
      Uri.parse('$baseUrl/create-room'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'type': type}),
    );
    return jsonDecode(res.body);
  }
}
