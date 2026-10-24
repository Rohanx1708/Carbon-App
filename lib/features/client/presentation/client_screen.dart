import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_loading_state.dart';
import 'package:attendance/core/widgets/app_status_badge.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/presentation/app_drawer.dart';
import 'package:attendance/features/client/presentation/client_detail_screen.dart';
import 'package:attendance/features/client/presentation/client_form_screen.dart';
import 'package:attendance/state/client_provider.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClientProvider>();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GradientAppBar(title: 'Clients'),
      body: AppContentContainer(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: AppLoadingState(
          isLoading: provider.loading,
          hasLoaded: provider.hasLoaded,
          hasData: provider.clients.isNotEmpty,
          refreshing: provider.refreshing,
          error: provider.error,
          onRetry: provider.refresh,
          onRefresh: provider.refresh,
          empty: const AppEmptyState(
            icon: Icons.corporate_fare_outlined,
            title: 'No clients yet',
            message: 'Clients you add will show up here',
          ),
          child: AppAdaptiveList(
            itemCount: provider.clients.length,
            itemBuilder: (context, i) {
              final c = provider.clients[i];
              final active = c.status.toLowerCase() == 'active';
              return AppListTile(
                leading: AppListTileLeading.icon(Icons.corporate_fare_outlined, accent: AppTheme.primaryBlue),
                title: c.displayName,
                subtitleLines: [
                  if (c.clientName.isNotEmpty && c.clientName != c.companyName) c.clientName,
                  if (c.industry.trim().isNotEmpty) c.industry,
                  if (c.phone.trim().isNotEmpty) c.phone,
                ],
                trailing: AppStatusBadge(
                  label: c.status,
                  foregroundColor: active ? AppColors.success : AppColors.textSecondary,
                  backgroundColor: active ? AppColors.successSoft : AppColors.background,
                ),
                onTap: () {
                  Navigator.of(
                    context,
                  ).push<bool>(MaterialPageRoute(builder: (_) => ClientDetailScreen(client: c))).then((updated) {
                    if (updated == true && context.mounted) provider.refresh();
                  });
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(
            context,
          ).push<bool>(MaterialPageRoute(builder: (_) => const ClientFormScreen()));
          if (created == true && context.mounted) {
            context.read<ClientProvider>().refresh();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
