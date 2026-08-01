import 'api_service.dart';

class ReportService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getStudentReport(String studentId) async {
    final response = await _api.get('/report/student/$studentId');
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> getLowAttendanceReport() async {
    return await _api.get('/report/low-attendance');
  }
}
