import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'widgets/dashboard_widgets.dart'; 
import 'student_dashboard_screen.dart';
import 'student_schedule_screen.dart';
import 'student_profile_screen.dart';
import '../../core/services/report_service.dart';
import '../../utils/user_session.dart';

class StudentStatsScreen extends StatefulWidget {
  const StudentStatsScreen({super.key});

  @override
  State<StudentStatsScreen> createState() => _StudentStatsScreenState();
}

class _StudentStatsScreenState extends State<StudentStatsScreen> {
  final ReportService _reportService = ReportService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _statsData;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (UserSession.studentId == null) {
      setState(() {
        _error = "Student ID not found. Please log in again.";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _reportService.getStudentReport(UserSession.studentId.toString());
      if (mounted) {
        setState(() {
          _statsData = response;
          _isLoading = false;
        });
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false, 
        title: Text(
          'Analytics',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: 2,
        onTap: (i) {
          if (i == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentDashboardScreen()));
          if (i == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentScheduleScreen()));
          if (i == 2) return;
          if (i == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentProfileScreen()));
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadStats,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final double percentage = double.tryParse(_statsData?['percentage']?.toString() ?? '0') ?? 0.0;
    final int total = _statsData?['totalSessions'] ?? 0;
    final int attended = _statsData?['attended'] ?? 0;
    final bool isLow = _statsData?['lowAttendance'] ?? false;

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        children: [
          // ── Overall Attendance Header ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppDecorations.card(isDark: false),
            child: Column(
              children: [
                Center(child: AttendanceRing(percentage: percentage)), 
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(label: 'Total Sessions', value: total.toString()),
                    _StatItem(label: 'Attended', value: attended.toString()),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isLow ? AppColors.error : AppColors.success).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isLow 
                      ? 'Attendance is below 75% threshold.' 
                      : 'Great job! You are above the 75% threshold.', 
                    style: TextStyle(
                      color: isLow ? AppColors.error : AppColors.success, 
                      fontWeight: FontWeight.w700, 
                      fontSize: 13
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Subject Breakdown ──
          const SectionHeader(title: 'Subject Breakdown'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppDecorations.card(isDark: false),
            child: const Text(
              'Subject-wise attendance will be available in a future update.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
