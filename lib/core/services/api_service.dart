import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    print('URL: ${ApiConstants.baseUrl}$endpoint');
    print('BODY: $body');
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    print('STATUS: ${response.statusCode}');
    print('RESPONSE: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Request failed');
    }

    return data;
  }
}