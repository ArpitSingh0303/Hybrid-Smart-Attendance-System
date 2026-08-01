import 'api_service.dart';

class ProfileService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getStudentProfile() async {
    return await _api.get('/student/profile');
  }

  Future<Map<String, dynamic>> getTeacherProfile() async {
    return await _api.get('/teacher/profile');
  }
}
