import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_loading_state.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/widgets/app_status_badge.dart';
import 'package:attendance/core/widgets/app_status_calendar.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/holiday/data/holiday_service.dart';
import 'package:attendance/features/holiday/presentation/holiday_detail_screen.dart';
import 'package:attendance/features/holiday/presentation/holiday_form_dialog.dart';
import 'package:attendance/features/settings/presentation/office_week_offs_builder.dart';
import 'package:attendance/state/profile_provider.dart';

class HolidaysScreen extends StatefulWidget {
  const HolidaysScreen({super.key});

  @override
  State<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen> {
  final _service = HolidayService();

  List<Holiday> _holidays = const [];
  bool _loading = false;
  bool _refreshing = false;
  bool _hasLoaded = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _refresh(force: false);
  }

  Future<void> _refresh({bool force = true}) async {
    setState(() {
      _error = null;
      _loading = !_hasLoaded && _holidays.isEmpty;
      _refreshing = _hasLoaded;
    });
    try {
      final list = await _service.fetchAll(force: force);
      if (!mounted) return;
      setState(() {
        _holidays = list;
        _hasLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_holidays.isEmpty) _error = e;
        _hasLoaded = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _add() async {
    if (await showHolidayFormDialog(context) && mounted) await _refresh();
  }

  Future<void> _open(Holiday h) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HolidayDetailScreen(holidayId: h.id, initial: h),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.watch<ProfileProvider>().canEditOfficeTiming;

    return Scaffold(
      appBar: const GradientAppBar(title: 'Holidays', showBack: true, showProfileAction: false),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Add holiday'),
            )
          : null,
      body: AppContentContainer(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: AppLoadingState(
          isLoading: _loading,
          hasLoaded: _hasLoaded,
          hasData: _holidays.isNotEmpty,
          refreshing: _refreshing,
          error: _error,
          onRetry: _refresh,
          onRefresh: _refresh,
          loading: const AppSkeletonList(header: AppSkeletonBlock(height: 400)),
          empty: AppEmptyState(
            icon: Icons.celebration_outlined,
            title: 'No holidays yet',
            message: canManage ? 'Tap Add holiday to create the first one' : 'Company holidays will appear here',
          ),
          child: OfficeWeekOffsBuilder(
            builder: (context, weekOffs) => AppStatusCalendarView<Holiday>(
              items: _holidays,
              weekOffs: weekOffs,
              daysOf: (h) => appCalendarDaysBetween(h.date, h.date),
              toneOf: (h) => h.isActive ? AppCalendarTone.error : AppCalendarTone.neutral,
              emptyMessage: 'No holidays on these dates',
              legend: const [
                AppCalendarLegend('Holiday', AppCalendarTone.error),
                AppCalendarLegend('Inactive', AppCalendarTone.neutral),
              ],
              itemBuilder: (context, h) => AppListTile(
                leading: AppListTileLeading.icon(
                  Icons.celebration_outlined,
                  accent: h.isActive ? AppColors.error : AppColors.textSecondary,
                ),
                title: h.name,
                subtitleLines: [
                  [AppDateFormat.fromRaw(h.date), if (h.day.isNotEmpty) h.day].join(' · '),
                  if (h.description.trim().isNotEmpty) h.description.trim(),
                ],
                trailing: AppStatusBadge(
                  label: h.isActive ? 'Active' : 'Inactive',
                  foregroundColor: h.isActive ? AppColors.success : AppColors.textSecondary,
                  backgroundColor: h.isActive ? AppColors.successSoft : AppColors.textSecondary.withValues(alpha: 0.12),
                ),
                onTap: () => _open(h),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
