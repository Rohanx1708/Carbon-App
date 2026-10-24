import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/features/attendance_report/presentation/report_widgets.dart';
import 'package:attendance/features/leave_request/data/leave_request_service.dart';

class LeavePreviewCard extends StatelessWidget {
  const LeavePreviewCard({super.key, required this.preview, this.loading = false, this.error});

  final LeaveRequestPreview? preview;
  final bool loading;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    if (loading && preview == null) {
      return ReportCard(
        child: Text('Checking paid and unpaid days…', style: TextStyle(color: context.textSecondary)),
      );
    }
    if (error != null && preview == null) {
      return ReportCard(
        child: Text('Could not preview this range', style: TextStyle(color: Theme.of(context).colorScheme.error)),
      );
    }
    final p = preview;
    if (p == null) return const SizedBox.shrink();

    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Paid vs unpaid',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            p.unpaidDays > 0
                ? '${p.paidDays} day${p.paidDays == 1 ? '' : 's'} from balance, ${p.unpaidDays} unpaid'
                : 'This range is covered by remaining paid leave',
            style: TextStyle(fontSize: 12.5, height: 1.35, color: context.textSecondary),
          ),
          const SizedBox(height: 12),
          ReportStatGrid(
            columns: 3,
            stats: [
              ReportStat(label: 'Paid', value: p.paidDays, color: AppColors.success),
              ReportStat(label: 'Unpaid', value: p.unpaidDays, color: AppColors.warning),
              ReportStat(label: 'Leave days', value: p.days, color: AppColors.primary),
            ],
          ),
          if (p.balance != null) ...[
            const SizedBox(height: 8),
            Text(
              'Balance after this leave: ${p.balance}',
              style: TextStyle(fontSize: 12.5, color: context.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
