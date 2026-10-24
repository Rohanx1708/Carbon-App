import 'dart:async';

import 'package:flutter/material.dart';
import 'package:attendance/core/widgets/app_dialog.dart';
import 'package:attendance/core/widgets/app_dropdown.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_error_state.dart';
import 'package:attendance/core/widgets/app_loading_state.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/core/widgets/app_status_badge.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/presentation/app_drawer.dart';
import 'package:attendance/features/lead/presentation/lead_detail_screen.dart';
import 'package:attendance/features/lead/presentation/lead_form_screen.dart';
import 'package:attendance/features/lead/data/lead_service.dart';
import 'package:attendance/state/lead_provider.dart';

class LeadScreen extends StatefulWidget {
  const LeadScreen({super.key});

  @override
  State<LeadScreen> createState() => _LeadScreenState();
}

class _LeadScreenState extends State<LeadScreen> {
  final _searchC = TextEditingController();
  Timer? _debounce;
  String? _selectedStatus;
  String? _selectedStage;
  String? _selectedSource;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchC.dispose();
    super.dispose();
  }

  void _load() {
    context.read<LeadProvider>().load(
      status: _selectedStatus,
      stage: _selectedStage,
      source: _selectedSource,
      search: _searchC.text,
    );
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _load();
    });
  }

  bool get _hasFilters => _selectedStatus != null || _selectedStage != null || _selectedSource != null;

  Future<void> _openFilterDialog() async {
    String? tempStatus = _selectedStatus;
    String? tempStage = _selectedStage;
    String? tempSource = _selectedSource;

    final applied = await AppDialog.show<bool>(
      context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final active = [tempStatus, tempStage, tempSource].where((v) => v != null).length;
            return AppDialog(
              title: 'Filter leads',
              subtitle: active == 0 ? 'Showing all leads' : '$active filter${active == 1 ? '' : 's'} selected',
              icon: Icons.filter_list_rounded,
              footer: AppDialogButtons(
                cancelLabel: 'Clear',
                onCancel: active == 0
                    ? () {}
                    : () => setLocalState(() {
                        tempStatus = null;
                        tempStage = null;
                        tempSource = null;
                      }),
                confirmLabel: 'Apply',
                confirmIcon: Icons.check_rounded,
                onConfirm: () => Navigator.of(context).pop(true),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _filterDropdown(
                    label: 'Status',
                    icon: Icons.local_fire_department_outlined,
                    value: tempStatus,
                    options: LeadOptions.statusFilterOptions(),
                    onChanged: (v) => setLocalState(() => tempStatus = v),
                  ),
                  const SizedBox(height: AppDialog.fieldGap),
                  _filterDropdown(
                    label: 'Stage',
                    icon: Icons.flag_outlined,
                    value: tempStage,
                    options: LeadOptions.stageFilterOptions(),
                    onChanged: (v) => setLocalState(() => tempStage = v),
                  ),
                  const SizedBox(height: AppDialog.fieldGap),
                  _filterDropdown(
                    label: 'Source',
                    icon: Icons.travel_explore_outlined,
                    value: tempSource,
                    options: const {'website': 'Website', 'cold_visit': 'Cold visit', 'other': 'Other'},
                    onChanged: (v) => setLocalState(() => tempSource = v),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (applied != true || !mounted) return;
    setState(() {
      _selectedStatus = tempStatus;
      _selectedStage = tempStage;
      _selectedSource = tempSource;
    });
    _load();
  }

  Widget _filterDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return AppDropdown<String?>(
      label: label,
      labelAbove: true,
      value: value,
      prefixIcon: Icon(icon, size: 18),
      items: appDropdownItems<String?>(context, [
        const MapEntry<String?, String>(null, 'All'),
        ...options.entries.map((e) => MapEntry<String?, String>(e.key, e.value)),
      ]),
      onChanged: onChanged,
    );
  }

  (Color fg, Color bg) _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'hot':
        return (AppColors.error, AppColors.errorSoft);
      case 'warm':
        return (AppColors.warning, AppColors.warningSoft);
      default:
        return (AppColors.success, AppColors.successSoft);
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const LeadFormScreen()));
    if (created == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GradientAppBar(title: 'Leads'),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: AppContentContainer(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.05 * 255).round()),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchC,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search leads...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                    suffixIcon: IconButton(
                      onPressed: _openFilterDialog,
                      icon: Icon(Icons.filter_list, color: _hasFilters ? AppTheme.primaryBlue : context.textSecondary),
                      tooltip: 'Filter',
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Selector<LeadProvider, ({bool loading, bool hasLoaded, Object? error, List<Lead> leads})>(
                  selector: (_, provider) => (
                    loading: provider.loading,
                    hasLoaded: provider.hasLoaded,
                    error: provider.error,
                    leads: provider.leads,
                  ),
                  builder: (context, data, _) {
                    switch (resolveViewState(
                      hasData: data.leads.isNotEmpty,
                      isLoading: data.loading,
                      hasLoaded: data.hasLoaded,
                      error: data.error,
                    )) {
                      case ViewState.loading:
                        return const AppSkeletonList();
                      case ViewState.error:
                        return AppErrorState(error: data.error!, onRetry: _load);
                      case ViewState.empty:
                        return const _EmptyState();
                      case ViewState.success:
                        break;
                    }
                    return AppAdaptiveList(
                      itemCount: data.leads.length,
                      onRefresh: () async => _load(),
                      itemBuilder: (context, i) {
                        final lead = data.leads[i];
                        final status = lead.leadStatus;
                        final (fg, bg) = _statusColors(status);
                        final email = lead.companyEmail.trim();
                        final stageLabel = (lead.stage ?? '').replaceAll('_', ' ');
                        return AppListTile(
                          leading: AppListTileLeading.icon(Icons.business_outlined, accent: fg),
                          title: lead.companyName,
                          subtitleLines: [
                            if (lead.leadCode != null && lead.leadCode!.isNotEmpty) lead.leadCode!,
                            if (email.isNotEmpty) email,
                            '${lead.companyPhone} • ${lead.industry}${stageLabel.isNotEmpty ? ' • $stageLabel' : ''}',
                          ],
                          trailing: AppStatusBadge(label: status, backgroundColor: bg, foregroundColor: fg),
                          onTap: () {
                            Navigator.of(context)
                                .push<bool>(MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: lead)))
                                .then((updated) {
                                  if (updated == true && context.mounted) _load();
                                });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New Lead',
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.business_center_outlined,
              size: 64,
              color: AppTheme.primaryBlue.withAlpha((0.6 * 255).round()),
            ),
          ),
          const SizedBox(height: 24),
          Text('No Leads Found', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first lead',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
