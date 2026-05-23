import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'teacher_dashboard_screen.dart';
import 'teacher_attendance_report_screen.dart';
import 'teacher_profile_screen.dart';

class TeacherAnalyticsScreen extends StatefulWidget {
  const TeacherAnalyticsScreen({super.key});

  @override
  State<TeacherAnalyticsScreen> createState() => _TeacherAnalyticsScreenState();
}

class _TeacherAnalyticsScreenState extends State<TeacherAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false, // Hide back button for main tabs
          title: Text(
            'Analytics',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row: Unified Bar Charts ──
Row(
  children: [
    Expanded(
      child: _BarChartCard(
        title: 'Attendance (%)',
        bars: const [
          {'label': 'M', 'value': 0.8}, {'label': 'T', 'value': 0.6}, {'label': 'W', 'value': 0.9},
          {'label': 'T', 'value': 0.7}, {'label': 'F', 'value': 0.85}, {'label': 'S', 'value': 0.4}, {'label': 'S', 'value': 0.5},
        ],
        barColor: const Color(0xFF00BFA5), // Sleek Teal
      ),
    ),
    const SizedBox(width: 16),
    Expanded(
      child: _BarChartCard(
        title: 'Absence Rate',
        bars: const [
          {'label': 'M', 'value': 0.2}, {'label': 'T', 'value': 0.4}, {'label': 'W', 'value': 0.1},
          {'label': 'T', 'value': 0.3}, {'label': 'F', 'value': 0.15}, {'label': 'S', 'value': 0.6}, {'label': 'S', 'value': 0.5},
        ],
        barColor: const Color(0xFFEF4444), // Consistent Red for absence
      ),
    ),
  ],
),
              const SizedBox(height: 24),

              // ── Middle: Curved Line Chart ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.dividerLight),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Weekly Trend', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // The Custom Curved Chart
                    SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _LineChartPainter(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // X-Axis Labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']
                          .map((day) => Text(day, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Bottom: Notifications / Action Card ──
              Text('Notifications', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Dark card matching your mockup's bottom button
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text('Classes Online', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),

       // ── Bottom Navigation Bar ──
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.dividerLight, width: 1)),
          ),
          child: SafeArea(
            child: BottomNavigationBar(
              currentIndex: 2, // Analytics is index 2
              onTap: (i) {
                if (i == 0) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherDashboardScreen()));
                } else if (i == 1) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherAttendanceReportScreen()));
                } else if (i == 3) { // ── NEW: Added routing to Profile ──
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherProfileScreen()));
                }
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_outlined), activeIcon: Icon(Icons.assignment_turned_in_rounded), label: 'Attendance'),
                BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics_rounded), label: 'Analytics'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> bars;
  final Color barColor; // Added parameter

  const _BarChartCard({required this.title, required this.bars, required this.barColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dividerLight),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          Row(
            // ── CHANGED: Even distribution ──
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bars.map((bar) {
              return Column(
                children: [
                  Container(
                    // ── CHANGED: Increased thickness to 18 ──
                    width: 18, 
                    height: 80 * (bar['value'] as double),
                    decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(6)),
                  ),
                  const SizedBox(height: 8),
                  Text(bar['label'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
// ── Painter: Custom Curved Line Chart ──
class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Create the smooth curve path
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.cubicTo(size.width * 0.2, size.height * 0.8, size.width * 0.2, size.height * 0.2, size.width * 0.4, size.height * 0.4);
    path.cubicTo(size.width * 0.6, size.height * 0.6, size.width * 0.8, size.height * 0.1, size.width, size.height * 0.3);

    // Draw the gradient fill under the curve
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primary.withOpacity(0.3), AppColors.primary.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}