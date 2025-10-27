import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

Future<String?> uploadImage() async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.camera);
  if (image == null) return null;

  var request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:3000/upload'));
  request.files.add(await http.MultipartFile.fromPath(
      'image', image.path,
      contentType: MediaType('image', 'jpeg')));
  var response = await request.send();

  if (response.statusCode == 200) {
    var respStr = await response.stream.bytesToString();
    return respStr; // url ảnh
  }
  return null;
}
