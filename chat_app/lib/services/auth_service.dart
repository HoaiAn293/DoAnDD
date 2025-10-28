import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'http://10.0.2.2:3000';

  Future<String?> register(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (res.statusCode == 200) return 'success';
      return jsonDecode(res.body)['msg'];
    } catch (e) {
      return 'Lỗi kết nối server';
    }
  }

  Future<String?> login(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (res.statusCode == 200) return 'success';
      return jsonDecode(res.body)['msg'];
    } catch (e) {
      return 'Lỗi kết nối server';
    }
  }
}