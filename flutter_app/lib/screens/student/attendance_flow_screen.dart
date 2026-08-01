import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/services/attendance_service.dart';
import '../../core/services/device_service.dart';
import '../../core/services/session_service.dart';
import '../../utils/user_session.dart';
import 'package:intl/intl.dart';

class AttendanceFlowScreen extends StatefulWidget {
  const AttendanceFlowScreen({super.key});

  @override
  State<AttendanceFlowScreen> createState() => _AttendanceFlowScreenState();
}

class _AttendanceFlowScreenState extends State<AttendanceFlowScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final DeviceService _deviceService = DeviceService();
  final SessionService _sessionService = SessionService();
  
  bool _isLoading = false;
  bool _isFetchingSession = true;
  String? _statusMessage;
  bool _isSuccess = false;
  bool _isDevicePending = false;
  Map<String, dynamic>? _activeSession;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await Future.wait([
      _initDevice(),
      _fetchActiveSession(),
    ]);
  }

  Future<void> _initDevice() async {
    try {
      await _deviceService.initDeviceIdentity();
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Device identity error: $e';
        });
      }
    }
  }

  Future<void> _fetchActiveSession() async {
    try {
      final response = await _sessionService.getActiveSession();
      if (mounted) {
        setState(() {
          _activeSession = response['data'];
          _isFetchingSession = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingSession = false);
      }
    }
  }

  Future<void> _handleMarkAttendance() async {
    if (UserSession.deviceUUID == null || UserSession.deviceHash == null) {
      await _initDevice();
      if (UserSession.deviceUUID == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize device identity'), backgroundColor: AppColors.error),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final response = await _attendanceService.markAttendance({
        'email': UserSession.studentEmail,
        'uuid': UserSession.deviceUUID,
        'deviceHash': UserSession.deviceHash,
      });

      if (mounted) {
        setState(() {
          _isSuccess = true;
          _statusMessage = response['message'] ?? 'Attendance marked';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_statusMessage!), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        setState(() {
          _isLoading = false;
          if (errorStr.contains('403')) {
            _isDevicePending = true;
            _statusMessage = 'Device Approval Pending';
          } else {
            _statusMessage = errorStr.replaceAll('Exception: ', '');
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_statusMessage!),
            backgroundColor: _isDevicePending ? AppColors.warning : AppColors.error,
          ),
        );
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
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppColors.textPrimary),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // ── Subject Info Card ──────────────────────────────────────────
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: AppDecorations.card(isDark: false),
                  child: _isFetchingSession 
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _activeSession?['subjectName'] ?? 'Active Session',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _activeSession != null 
                          ? 'Room: ${_activeSession!['room']} • ${_activeSession!['department']}'
                          : 'Validate your device and presence to mark attendance.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_activeSession != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${DateFormat.jm().format(DateTime.parse(_activeSession!['startTime']))} - ${DateFormat.jm().format(DateTime.parse(_activeSession!['endTime']))}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Validation Steps Card ────────────────────────────────────────────────────
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  decoration: AppDecorations.card(isDark: false),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ValidationStep(
                        icon: _isSuccess ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: _isSuccess ? AppColors.success : AppColors.textSecondary,
                        text: 'Network verified',
                      ),
                      const SizedBox(height: 16),
                      _ValidationStep(
                        icon: _isDevicePending ? Icons.pending_actions_rounded : (_isSuccess ? Icons.check_circle_rounded : Icons.radio_button_unchecked),
                        color: _isDevicePending ? AppColors.warning : (_isSuccess ? AppColors.success : AppColors.textSecondary),
                        text: _isDevicePending ? 'Device approval pending' : 'Device validated',
                      ),
                      const SizedBox(height: 16),
                      _ValidationStep(
                        icon: _isSuccess ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: _isSuccess ? AppColors.success : AppColors.textSecondary,
                        text: 'Presence verified',
                      ),
                      const SizedBox(height: 32),
                      if (_isLoading)
                        const Center(
                          child: CupertinoActivityIndicator(
                            radius: 20,
                            color: AppColors.primary,
                          ),
                        )
                      else if (_statusMessage != null)
                        Text(
                          _statusMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: _isSuccess ? AppColors.success : (_isDevicePending ? AppColors.warning : AppColors.error),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Status Buttons ─────────────────────────────────────────────
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16),
                  child: Column(
                    children: [
                      if (!_isSuccess && !_isDevicePending)
                        _StatusButton(
                          color: AppColors.primary,
                          icon: Icons.fingerprint_rounded,
                          text: _isLoading ? 'Processing...' : 'Mark Attendance',
                          onTap: _isLoading ? () {} : _handleMarkAttendance,
                        ),
                      if (_isSuccess)
                        _StatusButton(
                          color: AppColors.success,
                          icon: Icons.check_circle_outline_rounded,
                          text: 'Attendance Recorded',
                          onTap: () => Navigator.pop(context),
                        ),
                      if (_isDevicePending)
                        _StatusButton(
                          color: AppColors.warning,
                          icon: Icons.hourglass_empty_rounded,
                          text: 'Approval Pending',
                          onTap: () => Navigator.pop(context),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _ValidationStep extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _ValidationStep({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatusButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _StatusButton({
    required this.color,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}