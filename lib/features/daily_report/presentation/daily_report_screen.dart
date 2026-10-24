import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/layout/app_content_container.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_loader.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/presentation/app_drawer.dart';
import 'package:attendance/features/daily_report/data/daily_report_models.dart';
import 'package:attendance/features/daily_report/data/daily_report_service.dart';
import 'package:attendance/features/attendance_report/presentation/report_widgets.dart';
import 'package:attendance/features/daily_report/presentation/daily_report_detail_screen.dart';
import 'package:attendance/features/daily_report/presentation/daily_report_form_screen.dart';
import 'package:attendance/state/profile_provider.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final _service = DailyReportService();
  final _dateLabel = DateFormat('EEE, d MMM yyyy');
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  Future<List<DailyWorkReport>>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProfileProvider>().loadIfNeeded();
      if (mounted) await _reload();
    });
  }

  bool get _useIndex => context.read<ProfileProvider>().isAdminOrManager;

  Future<List<DailyWorkReport>> _fetch() {
    if (_useIndex) {
      return _service.fetchIndex(date: _date);
    }
    return _service.fetchMy(date: _date);
  }

  Future<void> _reload() async {
    final future = _fetch();
    setState(() {
      _future = future;
    });
    try {
      await future;
    } catch (_) {
      // Shown by FutureBuilder error state.
    }
  }

  Future<void> _shiftDate(int days) async {
    setState(() => _date = DateUtils.dateOnly(_date.add(Duration(days: days))));
    await _reload();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _date = DateUtils.dateOnly(picked));
    await _reload();
  }

  Future<void> _openSubmit() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DailyReportFormScreen()),
    );
    if (ok == true && mounted) {
      AppFeedback.success(context, 'Daily report submitted');
      await _reload();
    }
  }

  Future<void> _openDetail(DailyWorkReport report) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DailyReportDetailScreen(reportId: report.id, initial: report),
      ),
    );
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<ProfileProvider>().isAdminOrManager;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GradientAppBar(title: 'Daily Report'),
      floatingActionButton: isAdmin
          ? null
          : FloatingActionButton.extended(
              onPressed: _openSubmit,
              icon: const Icon(Icons.add),
              label: const Text('Submit report'),
            ),
      body: AppContentContainer(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReportPeriodBar(
              label: _dateLabel.format(_date),
              icon: Icons.event_outlined,
              onPrevious: () => _shiftDate(-1),
              onNext: () => _shiftDate(1),
              onTap: _pickDate,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _future == null
                  ? const AppLoader(message: 'Loading reports')
                  : FutureBuilder<List<DailyWorkReport>>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const AppLoader(message: 'Loading reports');
                        }
                        if (snap.hasError) {
                          return AppEmptyState(
                            icon: Icons.error_outline,
                            title: 'Could not load reports',
                            message: snap.error.toString(),
                            actionLabel: 'Retry',
                            onAction: _reload,
                          );
                        }
                        final reports = snap.data ?? const <DailyWorkReport>[];
                        if (reports.isEmpty) {
                          return RefreshIndicator(
                            onRefresh: _reload,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 80),
                                AppEmptyState(
                                  icon: Icons.assignment_outlined,
                                  title: 'No work reports',
                                  message: isAdmin
                                      ? 'No reports submitted for this date'
                                      : 'Tap Submit report to share what you worked on',
                                ),
                              ],
                            ),
                          );
                        }
                        return RefreshIndicator(
                          onRefresh: _reload,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: reports.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final r = reports[i];
                              final projectNames =
                                  r.projects.map((p) => p.name).where((n) => n.isNotEmpty).join(' · ');
                              final name = r.employee.name.isNotEmpty ? r.employee.name : 'Work report';
                              return AppListTile(
                                leading: AppListTileLeading.icon(
                                  Icons.assignment_outlined,
                                  accent: AppColors.primary,
                                ),
                                title: name,
                                subtitleLines: [
                                  if (projectNames.isNotEmpty) projectNames,
                                ],
                                onTap: () => _openDetail(r),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
