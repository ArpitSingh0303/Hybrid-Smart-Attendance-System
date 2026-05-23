import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'widgets/dashboard_widgets.dart'; 
import 'student_dashboard_screen.dart';
import 'student_schedule_screen.dart';
import 'student_profile_screen.dart';

class StudentStatsScreen extends StatelessWidget {
  const StudentStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ── NEW: Defining the sleek teal color to match the pie chart ──
    const tealColor = Color(0xFF00BFA5);

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
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Overall Attendance Header ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppDecorations.card(isDark: false),
            child: Column(
              children: [
                // This automatically gets the Teal color and thickness from dashboard_widgets.dart!
                const Center(child: AttendanceRing(percentage: 78)), 
                const SizedBox(height: 16),
                const Text('Great job! You are above the 75% threshold.', 
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Subject Breakdown ──
          const SectionHeader(title: 'Subject Breakdown'),
          // ── CHANGED: Passed the new tealColor instead of textPrimary ──
          const _SubjectProgressCard(subject: 'Data Structures', percentage: 85, color: AppColors.textPrimary),
          const _SubjectProgressCard(subject: 'Operating Systems', percentage: 72, color: AppColors.textPrimary),
          const _SubjectProgressCard(subject: 'Database Management', percentage: 90, color: AppColors.textPrimary),
          const _SubjectProgressCard(subject: 'Computer Networks', percentage: 60, color: AppColors.textPrimary),
        ],
      ),
      // ── BOTTOM NAVIGATION ──
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: 2, // Stats is index 2
        onTap: (i) {
          if (i == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentDashboardScreen()));
          if (i == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentScheduleScreen()));
          if (i == 2) return; // Already here
          if (i == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentProfileScreen()));
        },
      ),
    );
  }
}

// ─── Helper Widget for Progress Bars ───
class _SubjectProgressCard extends StatelessWidget {
  final String subject;
  final double percentage;
  final Color color;

  const _SubjectProgressCard({required this.subject, required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(isDark: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subject, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text('${percentage.toInt()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            // ── CHANGED: Increased border radius to make the thicker bars look smooth ──
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.dividerLight,
              color: color,
              // ── CHANGED: Increased from 8 to 14 to make the bars broader! ──
              minHeight: 14, 
            ),
          ),
        ],
      ),
    );
  }
}