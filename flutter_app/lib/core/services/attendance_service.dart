import 'api_service.dart';

class AttendanceService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> markAttendance(Map<String, dynamic> data) async {
    return await _api.post('/attendance/mark', data);
  }

  Future<Map<String, dynamic>> getAttendanceHistory() async {
    return await _api.get('/attendance/history');
  }
}
