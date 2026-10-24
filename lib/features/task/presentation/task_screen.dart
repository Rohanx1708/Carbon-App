import 'package:flutter/material.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_loading_state.dart';
import 'package:attendance/core/widgets/app_search_field.dart';
import 'package:attendance/core/widgets/app_status_badge.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/presentation/app_drawer.dart';
import 'package:attendance/features/task/data/task_models.dart';
import 'package:attendance/features/task/presentation/task_detail_screen.dart';
import 'package:attendance/features/task/presentation/task_form_screen.dart';
import 'package:attendance/state/profile_provider.dart';
import 'package:attendance/state/task_provider.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final _searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  List<TaskItem> _filter(List<TaskItem> tasks) {
    final q = _searchC.text.trim().toLowerCase();
    if (q.isEmpty) return tasks;
    return tasks.where((t) {
      final hay = [t.title, t.taskCode, t.project.name, t.assigneeName, t.status, t.priority].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  (Color fg, Color bg) _priorityColors(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return (AppColors.error, AppColors.errorSoft);
      case 'low':
        return (AppColors.textSecondary, AppColors.background);
      case 'medium':
      default:
        return (AppColors.warning, AppColors.warningSoft);
    }
  }

  String _cap(String s) {
    if (s.isEmpty) return s;
    return s
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final filtered = _filter(provider.tasks);
    final canManage = context.watch<ProfileProvider>().canManageTasks;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GradientAppBar(title: 'Tasks'),
      body: AppContentContainer(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: Column(
          children: [
            AppSearchField(controller: _searchC, hint: 'Search tasks…', onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            Expanded(
              child: AppLoadingState(
                isLoading: provider.loading,
                hasLoaded: provider.hasLoaded,
                hasData: filtered.isNotEmpty,
                refreshing: provider.refreshing,
                error: provider.error,
                onRetry: provider.refresh,
                onRefresh: provider.refresh,
                empty: AppEmptyState(
                  icon: Icons.task_alt_outlined,
                  title: provider.tasks.isEmpty ? 'No tasks yet' : 'No matching tasks',
                  message: provider.tasks.isEmpty
                      ? (canManage ? 'Tap + to create a task' : 'Tasks assigned to you will show up here')
                      : 'Try another search',
                ),
                child: AppAdaptiveList(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final t = filtered[i];
                    final (fg, bg) = _priorityColors(t.priority);
                    return AppListTile(
                      leading: AppListTileLeading.icon(Icons.task_alt_outlined, accent: fg),
                      title: t.title,
                      subtitleLines: [
                        if (t.taskCode.isNotEmpty) t.taskCode,
                        if (t.project.name.isNotEmpty) t.project.name,
                        'Due ${AppDateFormat.fromRaw(t.dueDate, fallback: '—')} · ${t.assigneeName}',
                      ],
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AppStatusBadge(label: _cap(t.priority), foregroundColor: fg, backgroundColor: bg),
                          const SizedBox(height: 4),
                          Text(
                            _cap(t.status),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textSecondary),
                          ),
                        ],
                      ),
                      onTap: () async {
                        final updated = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => TaskDetailScreen(taskId: t.id, initial: t),
                          ),
                        );
                        if (updated == true && context.mounted) {
                          await provider.refresh();
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.of(
                  context,
                ).push<bool>(MaterialPageRoute(builder: (_) => const TaskFormScreen()));
                if (created == true && context.mounted) {
                  await context.read<TaskProvider>().refresh();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
