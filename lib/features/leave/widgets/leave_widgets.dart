import 'package:flutter/material.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_status_badge.dart';
import 'package:attendance/features/leave/data/leave_service.dart';

class LeaveCardCompact extends StatelessWidget {
  final LeaveRequest leave;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const LeaveCardCompact({super.key, required this.leave, this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final datePrimary = AppDateFormat.date(leave.startDate);
    final statusVal = (leave.status).toLowerCase();

    Color statusFg;
    Color statusBg;
    String statusLabel;
    switch (statusVal) {
      case 'approved':
        statusFg = AppColors.success;
        statusBg = AppColors.successSoft;
        statusLabel = 'Approved';
        break;
      case 'rejected':
        statusFg = AppColors.error;
        statusBg = AppColors.errorSoft;
        statusLabel = 'Rejected';
        break;
      default:
        statusFg = AppColors.warning;
        statusBg = AppColors.warningSoft;
        statusLabel = 'Awaiting';
    }

    String titleLabel;
    switch (leave.type) {
      case 'casual':
        titleLabel = 'Casual Leave';
        break;
      case 'sick':
        titleLabel = 'Sick Leave';
        break;
      default:
        titleLabel = '${leave.type[0].toUpperCase()}${leave.type.substring(1)} Leave';
    }

    final Color stripeColor = leave.type == 'sick'
        ? AppColors.error
        : (leave.type == 'casual' ? AppColors.primary : AppColors.info);

    int currentStep;
    switch (statusVal) {
      case 'approved':
        currentStep = 3;
        break;
      case 'rejected':
        currentStep = 2; // stopped at review
        break;
      default:
        currentStep = 1; // created
    }

    return AppListTile(
      accentColor: stripeColor,
      overline: '$titleLabel application',
      title: datePrimary,
      subtitle: leave.type == 'casual' ? 'Casual' : (leave.type == 'sick' ? 'Sick' : titleLabel),
      highlightSubtitle: true,
      trailing: AppStatusBadge(label: statusLabel, backgroundColor: statusBg, foregroundColor: statusFg),
      footer: _StepperRow(currentStep: currentStep),
      onTap: onTap,
    );
  }
}

class _StepperRow extends StatelessWidget {
  final int currentStep; // 1..3
  const _StepperRow({required this.currentStep});

  Color _dotColor(BuildContext context, bool active) {
    return active ? AppColors.primary : Theme.of(context).colorScheme.outline;
  }

  Widget _step(BuildContext context, String label, int index, int current) {
    final bool active = index <= current;
    final Color color = _dotColor(context, active);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: index == 1 && active
              ? Icon(Icons.check, size: 12, color: Colors.white)
              : Text(
                  index.toString(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: active ? Colors.white : color),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? context.textPrimary : context.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.subtleBorder),
      ),
      child: Row(
        children: [
          _step(context, 'Create', 1, currentStep),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(height: 2, color: context.subtleBorder),
            ),
          ),
          _step(context, 'Review', 2, currentStep),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(height: 2, color: context.subtleBorder),
            ),
          ),
          _step(context, 'Approved', 3, currentStep),
        ],
      ),
    );
  }
}

class DonutStat extends StatelessWidget {
  final double value;
  final double max;
  final String title;
  final String? subtitle;
  final String? centerText;
  final Color fillColor;
  final double size;

  const DonutStat({
    super.key,
    required this.value,
    required this.max,
    required this.title,
    this.subtitle,
    this.centerText,
    required this.fillColor,
    this.size = 88,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    final display = (centerText ?? value.round().toString().padLeft(2, '0'));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: clamped),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, animatedProgress, _) {
            return SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size.square(size),
                    painter: _DonutPainter(
                      progress: animatedProgress,
                      color: fillColor,
                      trackColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
                      strokeWidth: 10,
                    ),
                  ),
                  display == '1'
                      ? Icon(Icons.check, size: 24, color: context.textPrimary)
                      : Text(
                          display,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimary),
                        ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textPrimary),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.textSecondary),
          ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _DonutPainter({required this.progress, required this.color, required this.trackColor, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final progPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Track
    canvas.drawCircle(center, radius, trackPaint);
    // Progress arc (start at 270 degrees)
    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = -90 * 3.1415926535 / 180;
    final sweepAngle = 2 * 3.1415926535 * progress;
    canvas.drawArc(rect, startAngle, sweepAngle, false, progPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
