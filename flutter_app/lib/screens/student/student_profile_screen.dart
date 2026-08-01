import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import 'widgets/dashboard_widgets.dart';
import 'student_dashboard_screen.dart';
import 'student_schedule_screen.dart';
import 'student_stats_screen.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/profile_service.dart';
import '../role_selection/role_selection_screen.dart';
import '../../utils/user_session.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
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
      final response = await _profileService.getStudentProfile();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
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
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: 3,
        onTap: (i) {
          if (i == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentDashboardScreen()));
          if (i == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentScheduleScreen()));
          if (i == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentStatsScreen()));
        },
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
            Text('Failed to load profile', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
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
    final devices = data['devices'] as List? ?? [];
    final regDate = data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now();

    return RefreshIndicator(
      onRefresh: _fetchProfile,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          // ── Identity Card ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppDecorations.card(isDark: false),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    (data['name'] ?? 'S')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  data['name'] ?? 'Student',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data['rollNo'] ?? 'N/A'} • ${data['email'] ?? 'N/A'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.dividerLight),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Attendance', '${stats['percentage'] ?? 0}%'),
                    _buildStat('Attended', '${stats['attended'] ?? 0}'),
                    _buildStat('Total', '${stats['totalSessions'] ?? 0}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Academic Details ──────────────────────────────────
          const SectionHeader(title: 'Academic Details'),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppDecorations.card(isDark: false),
            child: Column(
              children: [
                _DetailRow(label: 'Department', value: data['department'] ?? 'N/A'),
                const _DetailDivider(),
                _DetailRow(label: 'Semester', value: data['semester']?.toString() ?? 'N/A'),
                const _DetailDivider(),
                _DetailRow(label: 'Section', value: data['section'] ?? 'N/A'),
                const _DetailDivider(),
                _DetailRow(label: 'Member Since', value: DateFormat('MMM dd, yyyy').format(regDate)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Linked Devices ──────────────────────────────────────
          const SectionHeader(title: 'Linked Devices'),
          if (devices.isEmpty)
             const Padding(
               padding: EdgeInsets.symmetric(vertical: 8),
               child: Text('No devices linked', style: TextStyle(color: AppColors.textSecondary)),
             )
          else
            ...devices.map((device) => _DeviceCard(device: device)),
          
          const SizedBox(height: 28),

          // ── Settings & Actions ──────────────────────────────────────
          const SectionHeader(title: 'Settings'),
          Container(
            decoration: AppDecorations.card(isDark: false),
            child: Column(
              children: [
                _ProfileTile(
                  icon: Icons.edit_note_rounded, 
                  title: 'Edit Profile', 
                  subtitle: 'Update your personal info', 
                  onTap: () => _showFutureUpdateSnackBar(context),
                ),
                const Divider(height: 1, color: AppColors.dividerLight),
                _ProfileTile(icon: Icons.notifications_none_rounded, title: 'Notifications', subtitle: 'Alerts and updates', onTap: (){}),
                const Divider(height: 1, color: AppColors.dividerLight),
                _ProfileTile(icon: Icons.security_rounded, title: 'Privacy & Security', subtitle: 'Manage account security', onTap: (){}),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Logout Button ──────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              label: Text('Log Out', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.error)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEECEB),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showFutureUpdateSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile editing will be available in a future update.')),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await StorageService().deleteAuthData();
    UserSession.clear();
    if (!mounted) return;
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
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

class _DeviceCard extends StatelessWidget {
  final Map<String, dynamic> device;
  const _DeviceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    final bool isApproved = device['isApproved'] == true;
    final bool isActive = device['isActive'] == true;
    final uuid = device['uuid']?.toString() ?? '';
    final maskedUuid = uuid.length > 8 ? '${uuid.substring(0, 4)}...${uuid.substring(uuid.length - 4)}' : uuid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(isDark: false),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.smartphone_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Primary Device', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('UUID: $maskedUuid', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusTag(
                label: isApproved ? 'Approved' : 'Pending', 
                color: isApproved ? AppColors.success : AppColors.warning
              ),
              const SizedBox(height: 4),
              if (isActive) 
                const Text('Active', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w700))
              else
                const Text('Inactive', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }
}
