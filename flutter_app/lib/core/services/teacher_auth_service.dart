import 'api_service.dart';
import 'storage_service.dart';

class TeacherAuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String department,
  }) async {
    return await _api.post(
      '/teacher/signup',
      {
        'name': name,
        'email': email,
        'password': password,
        'department': department,
      },
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/teacher/login',
      {
        'email': email,
        'password': password,
      },
    );

    if (response['token'] != null) {
      await _storage.saveToken(response['token']);
      await _storage.saveRole('teacher');
      if (response['data'] != null && response['data']['id'] != null) {
        await _storage.saveUserId(response['data']['id'].toString());
      }
    }

    return response;
  }
}
