import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/session_service.dart';

// ── Deep-dark colour tokens local to this screen ──────────────────────────────
const _bg        = Color(0xFF0D0F18);
const _card      = Color(0xFF161827);
const _cardBdr   = Color(0xFF252740);
const _textHi    = Color(0xFFF0F0FF);
const _textLo    = Color(0xFF7B7E9A);
const _accent1   = Color(0xFF6C63FF);  // violet – bar primary
const _accent2   = Color(0xFF00D4AA);  // teal   – line week 3
const _accent3   = Color(0xFF4C9EFF);  // blue   – line week 2
const _accent4   = Color(0xFFFF6B8A);  // rose   – line week 1

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final SessionService _sessionService = SessionService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _fetchData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _sessionService.getTeacherDashboard();
      if (mounted) {
        setState(() {
          _data = response['data'];
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
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent1));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: _accent4, size: 48),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _textLo)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchData,
                style: ElevatedButton.styleFrom(backgroundColor: _accent1, foregroundColor: Colors.white),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _data?['statistics'] ?? {};
    final lowAttendanceCount = (_data?['lowAttendanceStudents'] as List?)?.length ?? 0;

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: _accent1,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        children: [
          _OverviewRow(
            avg: '${stats['averageAttendance'] ?? 0}%',
            present: stats['presentToday']?.toString() ?? '0',
            absent: stats['absentToday']?.toString() ?? '0',
          ),
          const SizedBox(height: 24),

          const _SectionLabel('Historical Attendance (%)'),
          const SizedBox(height: 12),
          const _ChartCard(
            height: 240,
            child: Center(child: Text("Subject-wise analytics coming soon", style: TextStyle(color: _textLo))),
          ),

          const SizedBox(height: 24),

          const _SectionLabel('Weekly Trend'),
          const SizedBox(height: 12),
          const _ChartCard(
            height: 220,
            child: Center(child: Text("Trend analytics coming soon", style: TextStyle(color: _textLo))),
          ),

          const SizedBox(height: 24),

          _BottomStatsRow(
            totalStudents: stats['totalStudents']?.toString() ?? '0',
            totalSessions: stats['totalSessions']?.toString() ?? '0',
            lowAttendance: lowAttendanceCount.toString(),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) => AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _cardBdr, width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: _textHi),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Analytics',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textHi,
                letterSpacing: -0.3)),
      );
}

class _OverviewRow extends StatelessWidget {
  final String avg;
  final String present;
  final String absent;
  const _OverviewRow({required this.avg, required this.present, required this.absent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _OverviewChip('Average', avg, _accent2)),
        const SizedBox(width: 10),
        Expanded(child: _OverviewChip('Present', present, _accent1)),
        const SizedBox(width: 10),
        Expanded(child: _OverviewChip('Absent', absent, _accent4)),
      ],
    );
  }
}

class _OverviewChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _OverviewChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w500, color: _textLo)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.5)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _textHi,
          letterSpacing: -0.2));
}

class _ChartCard extends StatelessWidget {
  final Widget child;
  final double height;
  const _ChartCard({required this.child, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBdr, width: 1),
      ),
      child: child,
    );
  }
}

class _BottomStatsRow extends StatelessWidget {
  final String totalStudents;
  final String totalSessions;
  final String lowAttendance;
  const _BottomStatsRow({
    required this.totalStudents,
    required this.totalSessions,
    required this.lowAttendance,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BottomStatCard(
            label: 'Students',
            value: totalStudents,
            sub: 'Enrolled',
            icon: Icons.people_rounded,
            color: _accent1,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BottomStatCard(
            label: 'Sessions',
            value: totalSessions,
            sub: 'Total',
            icon: Icons.event_note_rounded,
            color: _accent3,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BottomStatCard(
            label: 'Low Att.',
            value: lowAttendance,
            sub: 'Students',
            icon: Icons.warning_amber_rounded,
            color: _accent4,
          ),
        ),
      ],
    );
  }
}

class _BottomStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  const _BottomStatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBdr, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textHi,
                  letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w500, color: _textLo)),
          Text(sub,
              style: GoogleFonts.inter(fontSize: 10, color: _textLo.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}
