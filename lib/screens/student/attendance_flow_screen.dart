import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Needed for the dotted iOS-style spinner
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class AttendanceFlowScreen extends StatelessWidget {
  const AttendanceFlowScreen({super.key});

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
                  color: AppColors.black.withOpacity(0.06),
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
    constraints: const BoxConstraints(maxWidth: 500), // Limits width on tablets
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(isDark: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Subject',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Course code: 82703',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Time: 5:00 PM',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
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
        mainAxisSize: MainAxisSize.min, // Ensures card only takes needed height
        children: [
          const _ValidationStep(
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
            text: 'Checking Wi-Fi...',
          ),
          const SizedBox(height: 16),
          const _ValidationStep(
            icon: Icons.check_circle_rounded,
            color: AppColors.warning,
            text: 'Validating device...',
          ),
          const SizedBox(height: 16),
          const _ValidationStep(
            icon: Icons.check_circle_rounded,
            color: AppColors.warning,
            text: 'Verifying presence...',
          ),
          // FIX: Replaced Spacer() with SizedBox to maintain consistent layout
          const SizedBox(height: 32), 
          
          // Dotted Loading Indicator
          const Center(
            child: CupertinoActivityIndicator(
              radius: 20,
              color: AppColors.primary,
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
                      _StatusButton(
                        color: AppColors.success,
                        icon: Icons.check_circle_outline_rounded,
                        text: 'Attendance Recorded',
                        onTap: () {},
                      ),
                      const SizedBox(height: 16),
                      _StatusButton(
                        color: AppColors.error,
                        icon: Icons.cancel_outlined,
                        text: 'Connect to class Wi-Fi',
                        onTap: () {},
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