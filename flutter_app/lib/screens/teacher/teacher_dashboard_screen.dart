import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/services/session_service.dart';

// Screens for Navigation
import 'teacher_attendance_report_screen.dart';
import 'teacher_analytics_screen.dart';
import 'teacher_profile_screen.dart';
import 'create_session_screen.dart';
import '../admin/admin_device_approval_screen.dart';

// Global User Session Data
import '../../utils/user_session.dart';
import 'package:intl/intl.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _navIndex = 0;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _dashboardData;
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _sessionService.getTeacherDashboard();
      if (response['success'] == true) {
        final data = response['data'];
        
        // ── Populate UserSession if not already set ──
        final teacher = data['teacher'];
        if (teacher != null) {
          UserSession.teacherName = teacher['name'] ?? UserSession.teacherName;
          UserSession.teacherEmail = teacher['email'] ?? UserSession.teacherEmail;
          UserSession.teacherDept = teacher['department'] ?? UserSession.teacherDept;
          UserSession.teacherId = teacher['id']?.toString() ?? UserSession.teacherId;
          UserSession.teacherDbId = teacher['id'] ?? UserSession.teacherDbId;
        }

        if (mounted) {
          setState(() {
            _dashboardData = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = response['message'] ?? 'Failed to load dashboard';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading dashboard',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadDashboard,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final stats = _dashboardData?['statistics'] ?? {};
    final activeSession = _dashboardData?['activeSession'];
    final pendingDevices = _dashboardData?['pendingDevices'] as List? ?? [];
    final lowAttendanceStudents = _dashboardData?['lowAttendanceStudents'] as List? ?? [];

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          title: Text(
            'Teacher Dashboard',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
              onPressed: () {},
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── Dynamic Welcome Greeting ──
            const Text(
              'Welcome back,',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Prof. ${UserSession.teacherName}',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // ── Statistics Section ──
            Row(
              children: [
                _StatCard(label: 'Students', value: stats['totalStudents']?.toString() ?? '0', color: AppColors.primary),
                const SizedBox(width: 12),
                _StatCard(label: 'Avg Att.', value: '${stats['averageAttendance'] ?? 0}%', color: AppColors.success),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(label: 'Present Today', value: stats['presentToday']?.toString() ?? '0', color: AppColors.success),
                const SizedBox(width: 12),
                _StatCard(label: 'Absent Today', value: stats['absentToday']?.toString() ?? '0', color: AppColors.error),
              ],
            ),
            const SizedBox(height: 32),

            // ── Active Session Section ──
            Text(
              "Active Session",
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            if (activeSession == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: AppDecorations.card(isDark: false),
                child: Column(
                  children: [
                    const Icon(Icons.event_busy_rounded, color: AppColors.textSecondary, size: 48),
                    const SizedBox(height: 16),
                    const Text("No Active Session", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreateSessionScreen()),
                          );
                          if (result == true) _loadDashboard();
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text("Start New Session"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              _ActiveClassCard(session: activeSession),
            
            const SizedBox(height: 32),

            // ── Pending Devices Section ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pending Device Requests",
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                if (pendingDevices.isNotEmpty)
                  Text(
                    '${pendingDevices.length} total',
                    style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (pendingDevices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("No Pending Device Requests", style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              ...pendingDevices.take(3).map((d) => _DeviceRequestTile(
                device: d, 
                onReview: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDeviceApprovalScreen()));
                  _loadDashboard();
                },
              )),

            const SizedBox(height: 32),

            // ── Low Attendance Students ──
            Text(
              "Low Attendance Students",
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            if (lowAttendanceStudents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("No students below 75% attendance.", style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              Container(
                decoration: AppDecorations.card(isDark: false),
                child: Column(
                  children: lowAttendanceStudents.take(5).map((s) => _LowAttendanceTile(student: s)).toList(),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
        
        bottomNavigationBar: _TeacherBottomNav(
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.card(isDark: false).copyWith(
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

class _DeviceRequestTile extends StatelessWidget {
  final Map<String, dynamic> device;
  final VoidCallback onReview;
  const _DeviceRequestTile({required this.device, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final student = device['student'] ?? {};
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(isDark: false),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2), child: const Icon(Icons.phone_android_rounded, color: AppColors.primary)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student['name'] ?? 'Unknown Student', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(student['rollNo'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          TextButton(onPressed: onReview, child: const Text('Review', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _LowAttendanceTile extends StatelessWidget {
  final Map<String, dynamic> student;
  const _LowAttendanceTile({required this.student});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(student['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(student['rollNo'] ?? '', style: const TextStyle(fontSize: 12)),
      trailing: Text('${student['percentage']}%', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w800)),
    );
  }
}

class _ActiveClassCard extends StatelessWidget {
  final Map<String, dynamic> session;
  const _ActiveClassCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final startTime = session['startTime'] != null ? DateTime.parse(session['startTime']) : null;
    final endTime = session['endTime'] != null ? DateTime.parse(session['endTime']) : null;
    final timeRange = (startTime != null && endTime != null) 
        ? "${DateFormat.jm().format(startTime)} - ${DateFormat.jm().format(endTime)}" 
        : "N/A";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppDecorations.card(isDark: false).copyWith(
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  session['subjectName'] ?? 'Active Class',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(6)),
                child: const Text("LIVE", style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${session['department']} • Semester ${session['semester']} • Section ${session['section']}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.meeting_room_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(session['room'] ?? 'N/A', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 20),
              const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(timeRange, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherAttendanceReportScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('View Live Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// ── Teacher Bottom Navigation ──
class _TeacherBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  
  const _TeacherBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) {
        if (i == currentIndex) return;
        
        if (i == 0) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherDashboardScreen()));
        } else if (i == 1) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherAttendanceReportScreen()));
        } else if (i == 2) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherAnalyticsScreen()));
        } else if (i == 3) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherProfileScreen()));
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_rounded), label: 'Attendance'),
        BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Analytics'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }
}
