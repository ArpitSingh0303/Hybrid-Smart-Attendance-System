import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/services/session_service.dart';
import 'teacher_dashboard_screen.dart';
import 'teacher_analytics_screen.dart';
import 'teacher_profile_screen.dart';

class TeacherAttendanceReportScreen extends StatefulWidget {
  final String? sessionId;
  const TeacherAttendanceReportScreen({super.key, this.sessionId});

  @override
  State<TeacherAttendanceReportScreen> createState() => _TeacherAttendanceReportScreenState();
}

class _TeacherAttendanceReportScreenState extends State<TeacherAttendanceReportScreen>
    with SingleTickerProviderStateMixin {
  final SessionService _sessionService = SessionService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _sessionData;
  List<dynamic> _attendance = [];
  
  final _searchCtrl  = TextEditingController();
  final _searchFocus = FocusNode();
  String  _query     = '';

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _fetchSessionData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSessionData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? sId = widget.sessionId;
      if (sId == null) {
        final active = await _sessionService.getActiveSession();
        if (active['data'] != null) {
          sId = active['data']['id'].toString();
        }
      }

      if (sId == null) {
        setState(() {
          _error = "No active session found";
          _isLoading = false;
        });
        return;
      }

      final response = await _sessionService.getTeacherSession(sId);
      if (mounted) {
        setState(() {
          _sessionData = response['data'];
          _attendance = _sessionData?['attendance'] ?? [];
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

  List<dynamic> get _filtered {
    if (_query.isEmpty) return _attendance;
    return _attendance.where((a) {
      final student = a['student'] ?? {};
      final name = (student['name'] ?? '').toString().toLowerCase();
      final roll = (student['rollNo'] ?? '').toString().toLowerCase();
      return name.contains(_query.toLowerCase()) || roll.contains(_query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: _buildBody(),
      ),
      bottomNavigationBar: _TeacherBottomNav(
        currentIndex: 1,
        onTap: (i) {
           if (i == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherDashboardScreen()));
           if (i == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherAnalyticsScreen()));
           if (i == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherProfileScreen()));
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
                onPressed: _fetchSessionData,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final students = _filtered;
    final total = _attendance.length;
    final present = _attendance.where((a) => a['status'] == 'present').length;
    final absent = total - present;

    return RefreshIndicator(
      onRefresh: _fetchSessionData,
      color: AppColors.primary,
      child: Column(
        children: [
          _SummaryStrip(
            subject: _sessionData?['subjectName'] ?? 'Session',
            code: _sessionData?['id']?.toString() ?? 'N/A',
            total: total,
            present: present,
            absent: absent,
          ),

          _SearchBar(
            controller: _searchCtrl,
            focusNode: _searchFocus,
          ),

          const SizedBox(height: 12),

          Expanded(
            child: students.isEmpty
                ? _EmptyState(query: _query)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    itemCount: students.length,
                    itemBuilder: (_, i) => _StudentTile(
                      attendance: students[i],
                      index: i,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Text('Attendance Report',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final String subject;
  final String code;
  final int total;
  final int present;
  final int absent;
  const _SummaryStrip({
    required this.subject,
    required this.code,
    required this.total,
    required this.present,
    required this.absent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: AppDecorations.card(isDark: false),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('Session ID: $code',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _StatBadge('$total', 'Total', AppColors.primary),
          const SizedBox(width: 12),
          _StatBadge('$present', 'Pres.', AppColors.success),
          const SizedBox(width: 12),
          _StatBadge('$absent', 'Abs.', AppColors.error),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBadge(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5)),
        Text(label,
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  const _SearchBar({
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search student or roll no.',
          hintStyle: const TextStyle(color: AppColors.textDisabledLight, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.cardSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.dividerLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.dividerLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final dynamic attendance;
  final int index;
  const _StudentTile({
    required this.attendance,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final student = attendance['student'] ?? {};
    final isPresent = attendance['status'] == 'present';
    final name = student['name'] ?? 'Unknown';
    final roll = student['rollNo'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerLight, width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 14)),
                Text(roll,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isPresent ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isPresent ? AppColors.success.withValues(alpha: 0.5) : AppColors.error.withValues(alpha: 0.5)),
            ),
            child: Text(
              isPresent ? 'Present' : 'Absent',
              style: TextStyle(
                color: isPresent ? AppColors.success : AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search_rounded,
              size: 64, color: AppColors.textSecondary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? 'No students found' : 'No results for "$query"',
            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.dividerLight, width: 1)),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_outlined), activeIcon: Icon(Icons.assignment_turned_in_rounded), label: 'Attendance'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics_rounded), label: 'Analytics'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
