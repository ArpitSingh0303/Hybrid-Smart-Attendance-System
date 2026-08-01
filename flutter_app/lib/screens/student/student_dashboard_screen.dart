import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import 'widgets/dashboard_widgets.dart';
import 'student_schedule_screen.dart' hide ClassStatus;
import 'student_stats_screen.dart';
import 'student_profile_screen.dart';
import '../../utils/user_session.dart';
import '../../core/services/session_service.dart';
import '../../core/services/report_service.dart';
import 'package:intl/intl.dart';
import 'attendance_flow_screen.dart';
import 'attendance_history_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  STUDENT DASHBOARD SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  bool _isLoading = true;
  String? _error;
  List<SubjectClass> _activeClasses = [];
  double _attendancePercentage = 0.0;
  int _totalSessions = 0;
  int _attendedSessions = 0;
  bool _isLowAttendance = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  final SessionService _sessionService = SessionService();
  final ReportService _reportService = ReportService();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Fetch Active Session
      final sessionData = await _sessionService.getActiveSession();
      final List<SubjectClass> active = [];
      if (sessionData['data'] != null) {
        final data = sessionData['data'];
        final startTime = data['startTime'] != null ? DateTime.parse(data['startTime']) : null;
        final endTime = data['endTime'] != null ? DateTime.parse(data['endTime']) : null;
        
        String timeStr = 'N/A';
        if (startTime != null && endTime != null) {
          timeStr = '${DateFormat.jm().format(startTime)} - ${DateFormat.jm().format(endTime)}';
        }

        active.add(SubjectClass(
          subject: data['subjectName'] ?? 'Active Session',
          courseCode: 'Room: ${data['room'] ?? 'N/A'}',
          time: timeStr,
          status: ClassStatus.open,
        ));
      }
      
      // 2. Fetch Attendance Report Summary
      if (UserSession.studentId != null) {
        final reportData = await _reportService.getStudentReport(UserSession.studentId.toString());
        
        if (mounted) {
          setState(() {
            _activeClasses = active;
            _attendancePercentage = double.tryParse(reportData['percentage']?.toString() ?? '0') ?? 0.0;
            _totalSessions = reportData['totalSessions'] ?? 0;
            _attendedSessions = reportData['attended'] ?? 0;
            _isLowAttendance = reportData['lowAttendance'] ?? false;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _activeClasses = active;
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
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? 40.0 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _DashboardAppBar(horizontalPadding: horizontalPadding),

            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load dashboard',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _fetchDashboardData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    GestureDetector(
                      onTap: _activeClasses.isNotEmpty 
                        ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceFlowScreen()))
                        : null,
                      child: TodaysClassesSection(classes: _activeClasses),
                    ),
                    const SizedBox(height: 28),

                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AttendanceHistoryScreen()),
                      ),
                      child: AttendanceSummarySection(
                        percentage: _attendancePercentage,
                        weeklyData: kWeeklyBars,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Summary Details ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppDecorations.card(isDark: false),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SummaryItem(label: 'Total', value: _totalSessions.toString()),
                          _SummaryItem(label: 'Attended', value: _attendedSessions.toString()),
                          _SummaryItem(
                            label: 'Status', 
                            value: _isLowAttendance ? 'Low' : 'Good',
                            color: _isLowAttendance ? AppColors.error : AppColors.success,
                          ),
                        ],
                      ),
                    ),
                    if (_isLowAttendance) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your attendance is below the required threshold.',
                                style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),

                    const Opacity(
                      opacity: 0.3,
                      child: AbsorbPointer(child: DashboardBottomRow()),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),

      // ── Bottom Navigation ─────────────────────────────────────────────
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: _navIndex,
        onTap: (i) {
          if (_navIndex == i) return;

          setState(() => _navIndex = i);
          
          if (i == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (i == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StudentScheduleScreen()),
            );
          } else if (i == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StudentStatsScreen()),
            );
          } else if (i == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StudentProfileScreen()),
            );
          }
        },
      ),
    );
  } // Closes the build method
} // Closes the _StudentDashboardScreenState class

// ═══════════════════════════════════════════════════════════════════════════════
//  SLIVER APP BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _DashboardAppBar extends StatelessWidget {
  final double horizontalPadding;
  const _DashboardAppBar({required this.horizontalPadding});

  @override
  Widget build(BuildContext context) {
    // Dynamically calculate font size based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth > 400 ? 22.0 : 18.0;

    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 90,
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          color: AppColors.background,
          // Use the responsive padding passed from the parent
          padding: EdgeInsets.fromLTRB(horizontalPadding, 45, horizontalPadding, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Greeting with dynamic font size
              Expanded(
                child: Text(
                  'Welcome, ${UserSession.studentName}',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              // Notification bell
              _IconBtn(
                icon: Icons.notifications_outlined,
                badge: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _SummaryItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary)),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool badge;
  final VoidCallback onTap;
  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 22),
          ),
          if (badge)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
