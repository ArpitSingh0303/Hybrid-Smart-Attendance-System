import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hybrid_attendance_app/theme/app_theme.dart';
import '../../core/services/session_service.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class AdminDeviceApprovalScreen extends StatefulWidget {
  const AdminDeviceApprovalScreen({super.key});

  @override
  State<AdminDeviceApprovalScreen> createState() =>
      _AdminDeviceApprovalScreenState();
}

class _AdminDeviceApprovalScreenState extends State<AdminDeviceApprovalScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  final SessionService _sessionService = SessionService();
  List<dynamic> _pendingDevices = [];
  bool _isLoading = true;
  String? _error;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _fetchPendingDevices();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPendingDevices() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final devices = await _sessionService.getPendingDevices();
      if (mounted) {
        setState(() {
          _pendingDevices = devices;
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

  Future<void> _onApprove(dynamic device) async {
    if (_isProcessing) return;
    final student = device['student'] ?? {};
    final studentName = student['name'] ?? 'Student';
    final deviceName = device['deviceName'] ?? 'Unknown Device';

    final confirmed = await _showConfirmDialog(
      context,
      title: 'Approve Request?',
      body: 'This will bind $studentName\'s account to\n$deviceName.',
      actionLabel: 'Approve',
      actionColor: AppColors.success,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      await _sessionService.approveDevice(device['id'].toString());
      if (mounted) {
        setState(() {
          _pendingDevices.removeWhere((d) => d['id'] == device['id']);
          _isProcessing = false;
        });
        _showSnack('✓ Approved for $studentName', AppColors.success);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSnack('Error: ${e.toString().replaceAll('Exception: ', '')}', AppColors.error);
      }
    }
  }

  Future<void> _onReject(dynamic device) async {
    if (_isProcessing) return;
    final student = device['student'] ?? {};
    final studentName = student['name'] ?? 'Student';

    final confirmed = await _showConfirmDialog(
      context,
      title: 'Reject Request?',
      body: 'This will permanently remove the request for $studentName.',
      actionLabel: 'Reject',
      actionColor: AppColors.error,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      await _sessionService.rejectDevice(device['id'].toString());
      if (mounted) {
        setState(() {
          _pendingDevices.removeWhere((d) => d['id'] == device['id']);
          _isProcessing = false;
        });
        _showSnack('✕ Request rejected for $studentName', AppColors.error);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSnack('Error: ${e.toString().replaceAll('Exception: ', '')}', AppColors.error);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: _buildAppBar(isDark),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: RefreshIndicator(
          onRefresh: _fetchPendingDevices,
          color: AppColors.primary,
          child: Column(
            children: [
              // ── Summary strip ──────────────────────────────────────────────
              _SummaryStrip(
                pending: _pendingDevices.length,
                isDark: isDark,
              ),

              const SizedBox(height: 12),

              // ── Request list ───────────────────────────────────────────────
              Expanded(
                child: _buildMainContent(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDark) {
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
              Text('Failed to load requests', 
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchPendingDevices,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }
    if (_pendingDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 52, color: AppColors.textSecondary.withOpacity(0.35)),
            const SizedBox(height: 12),
            const Text("No Pending Device Requests", style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemCount: _pendingDevices.length,
      itemBuilder: (_, i) => _RequestCard(
        device: _pendingDevices[i],
        isDark: isDark,
        isProcessing: _isProcessing,
        onApprove: () => _onApprove(_pendingDevices[i]),
        onReject: () => _onReject(_pendingDevices[i]),
      ),
    );
  }

  AppBar _buildAppBar(bool isDark) => AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: context.appCard,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isDark ? [] : [
                BoxShadow(color: AppColors.black.withOpacity(0.06),
                    blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: context.appTextPrimary),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Device Approvals',
            style: AppTextStyles.headlineSmall(context.appTextPrimary)),
        actions: [
          IconButton(
            icon: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: context.appCard,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isDark ? [] : [
                  BoxShadow(color: AppColors.black.withOpacity(0.06),
                      blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(Icons.refresh_rounded,
                  size: 18, color: context.appTextPrimary),
            ),
            onPressed: _fetchPendingDevices,
          ),
          const SizedBox(width: 4),
        ],
      );

  Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String body,
    required String actionLabel,
    required Color actionColor,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Text(body, style: const TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    ) ?? false;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SUMMARY STRIP
// ═════════════════════════════════════════════════════════════════════════════
class _SummaryStrip extends StatelessWidget {
  final int pending;
  final bool isDark;
  const _SummaryStrip({
    required this.pending,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppDecorations.card(isDark: isDark),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Device Requests',
                    style: AppTextStyles.headlineSmall(context.appTextPrimary)
                        .copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text('Single-device binding approvals',
                    style: AppTextStyles.bodySmall(context.appTextSecondary)),
              ],
            ),
          ),
          _Badge('$pending',  'Pending',  AppColors.warning),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Badge(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value,
          style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5)),
      Text(label,
          style: AppTextStyles.caption(color.withOpacity(0.8))),
    ],
  );
}

// ═════════════════════════════════════════════════════════════════════════════
//  REQUEST CARD
// ═════════════════════════════════════════════════════════════════════════════
class _RequestCard extends StatelessWidget {
  final dynamic device;
  final bool isDark;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.device,
    required this.isDark,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  String get _initials {
    final student = device['student'] ?? {};
    final name = student['name'] ?? 'S';
    final p = name.trim().split(' ');
    return p.length >= 2 ? '${p[0][0]}${p[1][0]}' : p[0][0];
  }

  String get _timeAgo {
    final createdAt = DateTime.tryParse(device['createdAt'] ?? '');
    if (createdAt == null) return 'N/A';
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final student = device['student'] ?? {};
    final studentName = student['name'] ?? 'Unknown Student';
    final rollNo = student['rollNo'] ?? 'N/A';
    final deviceName = device['deviceName'] ?? 'Unknown Device';
    final uuid = device['uuid'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appDivider, width: 1),
        boxShadow: isDark ? [] : [
          BoxShadow(color: AppColors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(_initials,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white)),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(studentName,
                                style: AppTextStyles.bodyMedium(
                                        context.appTextPrimary)
                                    .copyWith(fontWeight: FontWeight.w600)),
                          ),
                          Text(_timeAgo,
                              style: AppTextStyles.caption(
                                  context.appTextSecondary)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _InfoChip(Icons.badge_outlined, rollNo),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Device info block ──────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.inputFillDark
                  : AppColors.inputFillLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appDivider, width: 1),
            ),
            child: Column(
              children: [
                _DeviceRow(
                  label: 'Device Name',
                  value: deviceName,
                  icon: Icons.smartphone_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                _DeviceRow(
                  label: 'UUID',
                  value: uuid,
                  icon: Icons.fingerprint_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),

          // ── Action buttons (only for pending) ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'Approve',
                    icon: Icons.check_rounded,
                    color: AppColors.success,
                    bgColor: AppColors.successLight,
                    onPressed: isProcessing ? () {} : onApprove,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    label: 'Reject',
                    icon: Icons.close_rounded,
                    color: AppColors.error,
                    bgColor: AppColors.errorLight,
                    onPressed: isProcessing ? () {} : onReject,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Device row inside the device info block ───────────────────────────────────
class _DeviceRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _DeviceRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.caption(
                      context.appTextSecondary)),
              Text(value,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall(context.appTextPrimary)
                      .copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onPressed;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.35), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.labelMedium(color)
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: context.appTextSecondary),
      const SizedBox(width: 3),
      Text(label, style: AppTextStyles.bodySmall(context.appTextSecondary)),
    ],
  );
}
