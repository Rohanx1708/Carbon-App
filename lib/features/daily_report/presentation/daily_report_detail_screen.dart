import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/widgets/app_detail.dart';
import 'package:attendance/core/widgets/app_html_text.dart';
import 'package:attendance/features/daily_report/data/daily_report_models.dart';
import 'package:attendance/features/daily_report/data/daily_report_service.dart';
import 'package:attendance/features/daily_report/presentation/daily_report_form_screen.dart';
import 'package:attendance/state/profile_provider.dart';

class DailyReportDetailScreen extends StatefulWidget {
  const DailyReportDetailScreen({super.key, required this.reportId, this.initial});

  final int reportId;
  final DailyWorkReport? initial;

  @override
  State<DailyReportDetailScreen> createState() => _DailyReportDetailScreenState();
}

class _DailyReportDetailScreenState extends State<DailyReportDetailScreen> {
  final _service = DailyReportService();
  late Future<DailyWorkReport> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchDetail(widget.reportId);
  }

  Future<void> _reload() async {
    setState(() => _future = _service.fetchDetail(widget.reportId));
    await _future;
  }

  Future<void> _edit(DailyWorkReport report) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DailyReportFormScreen(existing: report)),
    );
    if (ok == true && mounted) {
      AppFeedback.success(context, 'Report updated');
      await _reload();
    }
  }

  bool _canEdit(DailyWorkReport report, ProfileProvider profile) {
    if (profile.isAdminOrManager) return false;
    final employeeId = profile.profile?.employee?.id;
    if (employeeId != null && employeeId > 0 && report.employeeId == employeeId) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();

    return FutureBuilder<DailyWorkReport>(
      future: _future,
      builder: (context, snap) {
        final report = snap.data ?? widget.initial;
        if (report == null) {
          final waiting = snap.connectionState == ConnectionState.waiting;
          return AppDetailScaffold(
            title: 'Work report',
            loading: waiting || snap.error == null,
            error: waiting ? null : snap.error,
            errorTitle: 'Could not load report',
            onRetry: _reload,
          );
        }

        final canEdit = _canEdit(report, profile);

        return AppDetailScaffold(
          title: 'Work report',
          onRefresh: _reload,
          actions: canEdit
              ? [
                  AppDetailMenu(
                    items: [
                      AppDetailMenuItem(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        onTap: () => _edit(report),
                      ),
                    ],
                  ),
                ]
              : null,
          header: AppDetailHeader(
            title: AppDateFormat.fromRaw(report.reportDate),
            avatarText: report.employee.name.isNotEmpty ? report.employee.name : 'WR',
            subtitle: report.employee.name.isNotEmpty ? report.employee.name : 'Work report',
            subtitleIcon: Icons.assignment_outlined,
            caption: [
              if ((report.employee.department ?? '').isNotEmpty) report.employee.department!,
              if ((report.employee.designation ?? '').isNotEmpty) report.employee.designation!,
            ].join(' · '),
            badges: [
              for (final p in report.projects.take(3)) AppDetailHeaderBadge(p.name),
            ],
          ),
          sections: [
            AppDetailSection(
              title: 'Work done',
              icon: Icons.notes_outlined,
              children: [
                AppHtmlText(
                  report.workDone.isEmpty ? '<p>No content</p>' : report.workDone,
                  style: const TextStyle(fontSize: 15, height: 1.45, color: AppColors.textPrimary),
                ),
              ],
            ),
            AppDetailSection(
              title: 'Details',
              icon: Icons.info_outline,
              children: [
                AppDetailRow(icon: Icons.person_outline, label: 'Employee', value: report.employee.name),
                if ((report.employee.email ?? '').isNotEmpty)
                  AppDetailRow(icon: Icons.email_outlined, label: 'Email', value: report.employee.email),
                if ((report.employee.department ?? '').isNotEmpty)
                  AppDetailRow(icon: Icons.apartment_outlined, label: 'Department', value: report.employee.department),
                AppDetailRow(
                  icon: Icons.folder_outlined,
                  label: 'Projects',
                  value: report.projects.isEmpty ? 'None' : report.projects.map((p) => p.name).join(', '),
                ),
                if (report.submittedBy.name.isNotEmpty)
                  AppDetailRow(icon: Icons.send_outlined, label: 'Submitted by', value: report.submittedBy.name),
              ],
            ),
          ],
        );
      },
    );
  }
}
