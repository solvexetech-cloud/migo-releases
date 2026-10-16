import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

/// PHASE I — Cloudinary upload service (unsigned)
class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  static const String _cloudName = 'zxl1kb8h';
  static const String _uploadPreset = 'migo_unsigned';

  String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload File (mobile/desktop)
  Future<String?> uploadFile(File file, {String? folder}) async {
    try {
      final uri = Uri.parse(_uploadUrl);
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = _uploadPreset;
      if (folder != null && folder.isNotEmpty) {
        request.fields['folder'] = folder;
      }

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint('Cloudinary: ${response.statusCode}');
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String?;
    } catch (e) {
      debugPrint('Cloudinary uploadFile error: $e');
      return null;
    }
  }

  /// Upload raw bytes (web too)
  Future<String?> uploadBytes({
    required List<int> bytes,
    required String filename,
    String? folder,
  }) async {
    try {
      final uri = Uri.parse(_uploadUrl);
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = _uploadPreset;
      if (folder != null && folder.isNotEmpty) {
        request.fields['folder'] = folder;
      }

      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint('Cloudinary: ${response.statusCode}');
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String?;
    } catch (e) {
      debugPrint('Cloudinary uploadBytes error: $e');
      return null;
    }
  }

  /// Unified upload
  Future<String?> upload({
    File? file,
    List<int>? bytes,
    String? filename,
    String? folder,
  }) async {
    if (kIsWeb && bytes != null && filename != null) {
      return uploadBytes(
        bytes: bytes,
        filename: filename,
        folder: folder,
      );
    }
    if (file != null) {
      return uploadFile(file, folder: folder);
    }
    return null;
  }
}