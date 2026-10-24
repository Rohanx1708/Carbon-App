import 'package:flutter/material.dart';
import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'leave_widgets.dart';

import 'package:attendance/features/leave/data/leave_service.dart';

class LeaveScreenUI extends StatelessWidget {
  final List<LeaveRequest> filteredLeaves;
  final void Function(String value) onSelectFilter;
  final void Function(int index, LeaveRequest r) onEdit;
  final void Function(int index) onDelete;
  final void Function(LeaveRequest r)? onTap;

  const LeaveScreenUI({
    super.key,
    required this.filteredLeaves,
    required this.onSelectFilter,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Donut Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const DonutStat(
              value: 5,
              max: 15,
              title: 'Total Leaves',
              fillColor: AppTheme.accentGreen,
              centerText: '5/15',
            ),
            const SizedBox(width: 40),
            const DonutStat(value: 2, max: 7, title: 'Sick Leave', fillColor: AppTheme.accentRed, centerText: '2/7'),
            const SizedBox(width: 40),
            const DonutStat(
              value: 3,
              max: 8,
              title: 'Casual Leave',
              fillColor: AppTheme.primaryBlue,
              centerText: '3/8',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                '${filteredLeaves.length} requests',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
              ),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              tooltip: 'Sort by',
              onSelected: onSelectFilter,
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'today', child: Text('Today')),
                PopupMenuItem(value: 'this_week', child: Text('This Week')),
                PopupMenuItem(value: 'last_week', child: Text('Last Week')),
                PopupMenuItem(value: 'this_month', child: Text('This Month')),
                PopupMenuItem(value: 'last_month', child: Text('Last Month')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.sort, size: 16, color: context.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Sort by',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 18, color: context.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(sizeFactor: animation, axisAlignment: -1.0, child: child),
            ),
            child: filteredLeaves.isEmpty
                ? const AppEmptyState(
                    key: ValueKey('empty'),
                    icon: Icons.event_busy_outlined,
                    title: 'No leave requests',
                    message: 'Tap + to submit a new leave request',
                  )
                : ListView.separated(
                    key: const ValueKey('list'),
                    itemCount: filteredLeaves.length,
                    separatorBuilder: (_, __) => const SizedBox(height: kAppListTileSpacing),
                    itemBuilder: (context, index) {
                      final r = filteredLeaves[index];
                      return LeaveCardCompact(
                        leave: r,
                        onTap: onTap != null ? () => onTap!(r) : null,
                        onEdit: () => onEdit(index, r),
                        onDelete: () => onDelete(index),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
