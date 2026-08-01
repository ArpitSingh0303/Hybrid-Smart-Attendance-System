class UserSession {
  // ── Teacher Details ──
  static String teacherName = 'Teacher';
  static String teacherEmail = '';
  static String teacherId = 'FAC-0000';
  static String teacherDept = 'General';
  static int? teacherDbId;

  // ── Student Details ──
  static String studentName = 'Student';
  static String studentRollNo = '000000';
  static String studentEmail = '';
  static int? studentId;

  // ── Device Identity ──
  static String? deviceUUID;
  static String? deviceHash;

  static void clear() {
    teacherName = 'Teacher';
    teacherEmail = '';
    teacherId = 'FAC-0000';
    teacherDept = 'General';
    teacherDbId = null;

    studentName = 'Student';
    studentRollNo = '000000';
    studentEmail = '';
    studentId = null;
  }
}
