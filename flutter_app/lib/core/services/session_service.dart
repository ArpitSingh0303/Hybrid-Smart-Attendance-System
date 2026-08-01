import 'api_service.dart';

class SessionService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getActiveSession() async {
    return await _api.get('/session/active');
  }

  Future<Map<String, dynamic>> getTeacherSession(String sessionId) async {
    return await _api.get('/teacher/session/$sessionId');
  }

  Future<List<dynamic>> getPendingDevices() async {
    final response = await _api.get('/teacher/pending-devices');
    return response['data'] ?? [];
  }

  Future<Map<String, dynamic>> approveDevice(String deviceId) async {
    return await _api.post('/teacher/approve-device/$deviceId', {});
  }

  Future<Map<String, dynamic>> rejectDevice(String deviceId) async {
    return await _api.post('/teacher/reject-device/$deviceId', {});
  }

  Future<Map<String, dynamic>> getTeacherDashboard() async {
    return await _api.get('/teacher/dashboard');
  }

  Future<Map<String, dynamic>> createSession({
    required String subjectName,
    required String department,
    required int semester,
    required String section,
    required String room,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return await _api.post('/session/create', {
      'subjectName': subjectName,
      'department': department,
      'semester': semester,
      'section': section,
      'room': room,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    });
  }
}
