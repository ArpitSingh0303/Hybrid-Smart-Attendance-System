import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  DATA MODELS & MOCK DATA
// ═══════════════════════════════════════════════════════════════════════════════

enum ClassStatus { open, closed }

class SubjectClass {
  final String subject;
  final String courseCode;
  final String time;
  final ClassStatus status;
  const SubjectClass({
    required this.subject,
    required this.courseCode,
    required this.time,
    required this.status,
  });
}

class WeeklyBar {
  final String day;
  final double present; // 0–1
  final double absent;  // 0–1
  const WeeklyBar(this.day, this.present, this.absent);
}

class NotificationItem {
  final String title;
  final String body;
  final IconData icon;
  const NotificationItem({required this.title, required this.body, required this.icon});
}

const kWeeklyBars = [
  WeeklyBar('M', 0.40, 0.0),
  WeeklyBar('T', 0.70, 0.0),
  WeeklyBar('W', 0.90, 0.0),
  WeeklyBar('T', 0.50, 0.0),
  WeeklyBar('F', 0.60, 0.0),
];

const kNotifications = [
  NotificationItem(
    title: 'Welcome to App',
    body: 'Check your schedule daily.',
    icon: Icons.notifications_none_rounded,
  ),
];

// ═══════════════════════════════════════════════════════════════════════════════
//  TODAY'S CLASSES SECTION
// ═══════════════════════════════════════════════════════════════════════════════

class TodaysClassesSection extends StatelessWidget {
  final List<SubjectClass> classes;
  const TodaysClassesSection({super.key, required this.classes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Today's Active Session"),
        if (classes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text("No active sessions currently.", style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ...classes.map((c) => ClassCard(cls: c)),
      ],
    );
  }
}

class ClassCard extends StatelessWidget {
  final SubjectClass cls;
  const ClassCard({super.key, required this.cls});

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
              Expanded(
                child: Text(
                  cls.subject,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: cls.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Course code: ${cls.courseCode}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Time: ${cls.time}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final ClassStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isOpen = status == ClassStatus.open;
    final bg = isOpen ? AppColors.primary.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15);
    final fg = isOpen ? AppColors.primary : AppColors.error;
    final label = isOpen ? 'Attendance Open' : 'Closed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ATTENDANCE SUMMARY SECTION (Side-by-side Layout)
// ═══════════════════════════════════════════════════════════════════════════════

class AttendanceSummarySection extends StatelessWidget {
  final double percentage;
  final List<WeeklyBar> weeklyData;
  const AttendanceSummarySection({
    super.key,
    required this.percentage,
    required this.weeklyData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Attendance Summary'),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 120,
                decoration: AppDecorations.card(isDark: false),
                child: Center(child: AttendanceRing(percentage: percentage)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 120,
                padding: const EdgeInsets.all(12),
                decoration: AppDecorations.card(isDark: false),
                child: const Opacity(
                  opacity: 0.5,
                  child: AbsorbPointer(
                    child: WeeklyBarChart(data: kWeeklyBars),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CIRCULAR PROGRESS PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class AttendanceRing extends StatelessWidget {
  final double percentage; // 0–100
  const AttendanceRing({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(
        painter: _RingPainter(progress: percentage / 100),
        child: Center(
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; 
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    canvas.drawArc(
      rect, 
      -math.pi / 2, 
      2 * math.pi, 
      false, 
      Paint()..color = const Color(0xFF00BFA5)..style = PaintingStyle.stroke..strokeWidth = 10
    );
    
    canvas.drawArc(
      rect, 
      -math.pi / 2, 
      2 * math.pi * progress, 
      false, 
      Paint()..color = AppColors.primary..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round
    );
  }
  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  MINI BAR CHART
// ═══════════════════════════════════════════════════════════════════════════════

class WeeklyBarChart extends StatelessWidget {
  final List<WeeklyBar> data;
  const WeeklyBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        final double barWidth = totalWidth * 0.12;
        final double availableHeight = constraints.maxHeight - 20;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: data.map((bar) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: barWidth,
                  height: availableHeight * bar.present, 
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bar.day,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  BOTTOM ROW  — Weekly Timetable | Notifications
// ═══════════════════════════════════════════════════════════════════════════════

class DashboardBottomRow extends StatelessWidget {
  const DashboardBottomRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Weekly Timetable'),
              AspectRatio(
                aspectRatio: 1 / 0.8, 
                child: Container(
                  decoration: AppDecorations.card(isDark: false),
                  child: const Center(child: Text("Coming Soon", style: TextStyle(color: Colors.grey, fontSize: 12))),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Notifications'),
              Container(
                height: 140, 
                decoration: AppDecorations.card(isDark: false),
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  shrinkWrap: true, 
                  children: kNotifications.map((n) => NotificationTile(item: n)).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationItem item;
  const NotificationTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 20, color: AppColors.primaryLight),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(item.body, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SECTION HEADER & BOTTOM NAV
// ═══════════════════════════════════════════════════════════════════════════════

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    );
  }
}

class DashboardBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const DashboardBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.dividerLight, width: 1)),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Schedule'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Stats'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
