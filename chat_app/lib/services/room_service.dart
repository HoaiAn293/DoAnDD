import 'dart:convert';
import 'package:http/http.dart' as http;

class RoomService {
  final String baseUrl = 'http://10.0.2.2:3000';

  Future<List<Map<String, dynamic>>> getRooms() async {
    final res = await http.get(Uri.parse('$baseUrl/rooms'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } else {
      throw Exception('Lỗi tải danh sách phòng');
    }
  }

  Future<Map<String, dynamic>> createRoom(String name, String type,
      {String? password}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/rooms'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'type': type,
        'password': password,
        'creator': 'YourUsername'
      }),
    );
    return jsonDecode(res.body);
  }
}

