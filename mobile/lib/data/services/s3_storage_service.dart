import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class S3StorageService {
  final ApiService _apiService = ApiService();

  Future<String?> uploadProductImage({
    required Uint8List imageBytes,
    required String filename,
  }) async {
    try {
      final uri = Uri.parse('${_apiService.baseUrl}/storage/upload');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 10));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['image_url'] as String?;
      }
    } catch (e) {
      debugPrint('S3 upload error: $e');
    }
    return null;
  }

  Future<String?> getPresignedUploadUrl(String filename) async {
    try {
      final uri = Uri.parse('${_apiService.baseUrl}/storage/presigned-url?filename=$filename');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['upload_url'] as String?;
      }
    } catch (e) {
      debugPrint('S3 getPresignedUploadUrl error: $e');
    }
    return null;
  }
}
