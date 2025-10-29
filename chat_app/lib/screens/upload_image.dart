import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class ServerConfig {
  static String get baseURL {
    return 'http://192.168.1.249:3000';
  }

  static Uri uploadUri() => Uri.parse('$baseURL/upload');
}

Future<String?> uploadImage({bool fromCamera = true}) async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: fromCamera ? ImageSource.camera : ImageSource.gallery,
  );

  if (image == null) return null;

  final request = http.MultipartRequest('POST', ServerConfig.uploadUri());
  request.files.add(await http.MultipartFile.fromPath(
    'image',
    image.path,
    contentType: MediaType('image', 'jpeg'),
  ));

  try {
    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);

      String url = data['url'];

      if (url.contains('localhost')) {
        url = url.replaceFirst(RegExp(r'http://localhost(:\d+)?'), ServerConfig.baseURL);
      }

      debugPrint('Uploaded image URL: $url');
      return url;
    } else {
      debugPrint('Upload failed with status: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error uploading image: $e');
  }

  return null;
}
