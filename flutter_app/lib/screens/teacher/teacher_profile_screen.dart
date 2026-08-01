import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'teacher_dashboard_screen.dart';
import 'teacher_attendance_report_screen.dart';
import 'teacher_analytics_screen.dart';
import '../role_selection/role_selection_screen.dart';
import '../../utils/user_session.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/profile_service.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _profileService.getTeacherProfile();
      if (mounted) {
        setState(() {
          _profileData = response['data'];
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Faculty Profile',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          centerTitle: true,
          actions: [
             IconButton(
               icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
               onPressed: _fetchProfile,
             ),
          ],
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? _buildErrorState()
                : _buildProfileContent(),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text('Error loading profile', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchProfile,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    final data = _profileData ?? {};
    final stats = data['statistics'] ?? {};

    return RefreshIndicator(
      onRefresh: _fetchProfile,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Faculty Header Card ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppDecorations.card(isDark: false),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      (data['name'] ?? 'T')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Prof. ${data['name'] ?? 'Teacher'}',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['department'] ?? 'General',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.dividerLight),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProfileStat('Faculty ID', 'FAC-${data['id'] ?? '0000'}'),
                      Container(height: 40, width: 1, color: AppColors.dividerLight),
                      _buildProfileStat('Sessions', stats['totalSessions']?.toString() ?? '0'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Performance Insights ──
            Text('Academic Overview', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppDecorations.card(isDark: false),
              child: Column(
                children: [
                  _DetailRow(label: 'Total Students', value: stats['totalStudents']?.toString() ?? '0'),
                  const _DetailDivider(),
                  _DetailRow(label: 'Avg. Attendance', value: '${stats['averageAttendance'] ?? 0}%'),
                  const _DetailDivider(),
                  _DetailRow(
                    label: 'Current Status', 
                    value: stats['isActiveSession'] == true ? 'In Class' : 'Idle',
                    valueColor: stats['isActiveSession'] == true ? AppColors.success : AppColors.textSecondary,
                  ),
                  const _DetailDivider(),
                  _DetailRow(label: 'Pending Requests', value: stats['pendingDevices']?.toString() ?? '0'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Account Settings ──
            Text('Account Settings', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              decoration: AppDecorations.card(isDark: false),
              child: Column(
                children: [
                  _buildSettingTile(Icons.email_outlined, 'Email Address', subtitle: data['email'] ?? ''),
                  const Divider(color: AppColors.dividerLight, height: 1),
                  _buildSettingTile(
                    Icons.edit_note_rounded, 
                    'Edit Profile', 
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile editing will be available in a future update.'))
                    ),
                  ),
                  const Divider(color: AppColors.dividerLight, height: 1),
                  _buildSettingTile(Icons.lock_outline_rounded, 'Security Settings'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Logout ──
            Container(
              decoration: AppDecorations.card(isDark: false),
              child: _buildSettingTile(
                Icons.logout_rounded, 
                'Log Out', 
                isDestructive: true,
                onTap: () async {
                  await StorageService().deleteAuthData();
                  UserSession.clear();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const RoleSelectionScreen()), 
                      (Route<dynamic> route) => false,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSettingTile(IconData icon, String title, {String? subtitle, bool isDestructive = false, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.textSecondary, size: 22),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.dividerLight, width: 1)),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: 3,
          onTap: (i) {
            if (i == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherDashboardScreen()));
            if (i == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherAttendanceReportScreen()));
            if (i == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherAnalyticsScreen()));
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_outlined), activeIcon: Icon(Icons.assignment_turned_in_rounded), label: 'Attendance'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics_rounded), label: 'Analytics'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: valueColor ?? AppColors.textPrimary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();
  @override
  Widget build(BuildContext context) => const Divider(height: 24, color: AppColors.dividerLight);
}
