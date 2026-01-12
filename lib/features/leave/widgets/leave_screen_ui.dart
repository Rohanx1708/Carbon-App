import 'package:flutter/material.dart';
import 'package:attendance/core/theme/app_theme.dart';
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
            const DonutStat(
              value: 2,
              max: 7,
              title: 'Sick Leave',
              fillColor: AppTheme.accentRed,
              centerText: '2/7',
            ),
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
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
                    Icon(Icons.sort, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text('Sort by', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey.shade600),
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
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1.0,
                child: child,
              ),
            ),
            child: filteredLeaves.isEmpty
                ? const _EmptyState(key: ValueKey('empty'))
                : ListView.separated(
                    key: const ValueKey('list'),
                    itemCount: filteredLeaves.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final r = filteredLeaves[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 250 + (index % 12) * 30),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 12),
                              child: child,
                            ),
                          );
                        },
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: onTap != null ? () => onTap!(r) : null,
                          child: LeaveCardCompact(
                            leave: r,
                            onEdit: () => onEdit(index, r),
                            onDelete: () => onDelete(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.event_available_outlined,
              size: 64,
              color: AppTheme.primaryBlue.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Leave Requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to submit a new leave request',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


