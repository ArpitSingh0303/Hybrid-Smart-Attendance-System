import 'api_service.dart';
import 'storage_service.dart';

class StudentAuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String rollNo,
    required String department,
    required int semester,
    required String section,
  }) async {
    return await _api.post(
      '/student/signup',
      {
        'name': name,
        'email': email,
        'password': password,
        'rollNo': rollNo,
        'department': department,
        'semester': semester,
        'section': section,
      },
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/student/login',
      {
        'email': email,
        'password': password,
      },
    );

    if (response['token'] != null) {
      await _storage.saveToken(response['token']);
    }

    return response;
  }
}
