import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/features/leave/data/leave_service.dart';

class LeaveBalanceListTile extends StatelessWidget {
  final int total;
  final int used;
  final int remaining;
  const LeaveBalanceListTile({
    super.key,
    required this.total,
    required this.used,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.beach_access, color: AppTheme.primaryBlue),
        ),
        title: const Text(
          'Casual Leave Balance',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Row(
          children: [
            _chip('Total', total.toString(), AppTheme.primaryBlue),
            const SizedBox(width: 8),
            _chip('Used', used.toString(), AppTheme.accentOrange),
            const SizedBox(width: 8),
            _chip('Remaining', remaining.toString(), AppTheme.accentGreen),
          ],
        ),
      ),
    );
  }

  static Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class LeaveCardCompact extends StatelessWidget {
  final LeaveRequest leave;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const LeaveCardCompact({
    super.key,
    required this.leave,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String _fmt(DateTime d) {
      final s = DateFormat('EEE, MMM d, yyyy').format(d);
      // Ensure September shows as 'Sept' instead of 'Sep'
      return s.contains('Sep ') ? s.replaceFirst('Sep ', 'Sept ') : s;
    }
    final datePrimary = _fmt(leave.startDate);
    final statusVal = (leave.status).toLowerCase();

    Color statusColor;
    String statusLabel;
    switch (statusVal) {
      case 'approved':
        statusColor = AppTheme.accentGreen;
        statusLabel = 'Approved';
        break;
      case 'rejected':
        statusColor = AppTheme.accentRed;
        statusLabel = 'Rejected';
        break;
      default:
        statusColor = AppTheme.accentOrange;
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
        titleLabel =
            '${leave.type[0].toUpperCase()}${leave.type.substring(1)} Leave';
    }

    final Color stripeColor = leave.type == 'sick'
        ? AppTheme.accentRed
        : (leave.type == 'casual'
              ? AppTheme.primaryBlue
              : AppTheme.accentPurple);

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

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        constraints: const BoxConstraints(minHeight: 90),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 6, color: stripeColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${titleLabel} Application',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                datePrimary,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                leave.type == 'casual' ? 'Casual' : (leave.type == 'sick' ? 'Sick' : titleLabel),
                                style: TextStyle(
                                  fontSize: 14  ,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: statusColor.withOpacity(0.25)),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.chevron_right, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StepperRow(currentStep: currentStep),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final int currentStep; // 1..3
  const _StepperRow({required this.currentStep});

  Color _dotColor(BuildContext context, bool active) {
    return active ? const Color(0xFF7C3AED) : Colors.grey.shade400; // purple
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
            ? Icon(
                Icons.check,
                size: 12,
                color: Colors.white,
              )
            : Text(
                index.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : color,
                ),
              ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.grey.shade800 : Colors.grey.shade600,
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
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _step(context, 'Create', 1, currentStep),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(height: 2, color: Colors.grey.shade300),
            ),
          ),
          _step(context, 'Review', 2, currentStep),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(height: 2, color: Colors.grey.shade300),
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
                      trackColor: Colors.grey.shade300,
                      strokeWidth: 10,
                    ),
                  ),
                  display == '1' 
                    ? Icon(
                        Icons.check,
                        size: 24,
                        color: Colors.grey.shade800,
                      )
                    : Text(
                        display,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade800,
                        ),
                      ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
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

  _DonutPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

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
