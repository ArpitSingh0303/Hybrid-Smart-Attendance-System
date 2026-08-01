import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _headers() async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    final token = await _storage.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Request failed');
    }

    return data;
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Request failed');
    }

    return data;
  }
}
