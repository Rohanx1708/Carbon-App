import 'package:flutter/material.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_loading_state.dart';
import 'package:attendance/core/widgets/app_status_badge.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/presentation/app_drawer.dart';
import 'package:attendance/features/project/presentation/project_detail_screen.dart';
import 'package:attendance/features/project/presentation/project_form_screen.dart';
import 'package:attendance/state/profile_provider.dart';
import 'package:attendance/state/project_provider.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().loadIfNeeded();
    });
  }

  (Color, Color) _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return (AppColors.success, AppColors.successSoft);
      case 'in_progress':
        return (AppColors.info, AppColors.infoSoft);
      case 'draft':
      case 'pending':
        return (AppColors.warning, AppColors.warningSoft);
      default:
        return (AppColors.textSecondary, AppColors.background);
    }
  }

  String _label(String raw) => raw.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final canManage = context.watch<ProfileProvider>().canManageProjects;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GradientAppBar(title: 'Projects'),
      body: AppContentContainer(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: AppLoadingState(
          isLoading: provider.loading,
          hasLoaded: provider.hasLoaded,
          hasData: provider.projects.isNotEmpty,
          refreshing: provider.refreshing,
          error: provider.error,
          onRetry: provider.refresh,
          onRefresh: provider.refresh,
          empty: AppEmptyState(
            icon: Icons.folder_open_outlined,
            title: 'No projects yet',
            message: canManage ? 'Tap + to create a project' : 'Projects you are part of will show up here',
          ),
          child: AppAdaptiveList(
            itemCount: provider.projects.length,
            gridChildAspectRatio: 2.8,
            itemBuilder: (context, i) {
              final p = provider.projects[i];
              final (fg, bg) = _statusColors(p.status);
              return AppListTile(
                leading: AppListTileLeading.icon(Icons.work_outline, accent: fg),
                title: p.name,
                subtitleLines: [
                  if (p.client.displayName.isNotEmpty) p.client.displayName,
                  p.projectTypeLabel.isNotEmpty ? p.projectTypeLabel : _label(p.projectType),
                  if (p.startDate != null) 'Start ${AppDateFormat.fromRaw(p.startDate)}',
                ],
                trailing: AppStatusBadge(label: _label(p.status), foregroundColor: fg, backgroundColor: bg),
                onTap: () {
                  Navigator.of(
                    context,
                  ).push<bool>(MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: p))).then((updated) {
                    if (updated == true && context.mounted) provider.refresh();
                  });
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.of(
                  context,
                ).push<bool>(MaterialPageRoute(builder: (_) => const ProjectFormScreen()));
                if (created == true && context.mounted) {
                  context.read<ProjectProvider>().refresh();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
