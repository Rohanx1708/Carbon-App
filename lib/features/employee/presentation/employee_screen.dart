import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/layout/app_layout.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_empty_state.dart';
import 'package:attendance/core/widgets/app_error_state.dart';
import 'package:attendance/core/widgets/app_loading_state.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:attendance/core/widgets/app_search_field.dart';
import 'package:attendance/core/widgets/app_section_title.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/presentation/app_drawer.dart';
import 'package:attendance/features/employee/data/employee_service.dart';
import 'package:attendance/features/employee/presentation/employee_details_screen.dart';
import 'package:attendance/features/employee/presentation/employee_form_screen.dart';
import 'package:attendance/features/employee/widgets/employee_tile.dart';
import 'package:attendance/state/employee_provider.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  AnimationController? _pageAnimController;
  Animation<double>? _pageFade;
  Animation<Offset>? _pageSlide;

  String get _query => _searchController.text.trim().toLowerCase();

  List<Employee> _filter(List<Employee> employees) {
    if (_query.isEmpty) return employees;
    return employees.where((e) {
      final haystack = [e.name, e.designation, e.department, e.phone, e.email, e.status].join(' ').toLowerCase();
      return haystack.contains(_query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _pageAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _pageFade = CurvedAnimation(parent: _pageAnimController!, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageAnimController!, curve: Curves.easeOutCubic));
    _pageAnimController!.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageAnimController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();
    final filtered = _filter(provider.employees);

    final state = resolveViewState(
      hasData: provider.employees.isNotEmpty,
      isLoading: provider.loading,
      hasLoaded: provider.hasLoaded,
      error: provider.error,
    );
    final Widget listBody;
    if (state == ViewState.loading) {
      listBody = const AppSkeletonList();
    } else if (state == ViewState.error) {
      listBody = AppErrorState(error: provider.error!, onRetry: () => provider.refresh());
    } else if (filtered.isEmpty) {
      listBody = AppEmptyState(
        icon: Icons.people_outline,
        title: _query.isNotEmpty ? 'No matching employees' : 'No employees found',
        message: _query.isNotEmpty
            ? 'Try a different search term'
            : 'Employees from your organization will appear here',
        actionLabel: provider.error != null ? 'Retry' : null,
        onAction: provider.error != null ? () => provider.refresh() : null,
      );
    } else {
      listBody = AppAdaptiveList(
        onRefresh: provider.refresh,
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final emp = filtered[index];
          return EmployeeTile(
            name: emp.name,
            title: emp.designation,
            phone: emp.phone,
            email: emp.email,
            onTap: () async {
              final updated = await Navigator.of(
                context,
              ).push<bool>(MaterialPageRoute(builder: (_) => EmployeeDetailsScreen(employeeId: emp.id)));
              if (updated == true && context.mounted) {
                await context.read<EmployeeProvider>().refresh();
              }
            },
          );
        },
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GradientAppBar(title: 'Employees'),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: AppContentContainer(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          child: FadeTransition(
            opacity: _pageFade ?? const AlwaysStoppedAnimation(1.0),
            child: SlideTransition(
              position: _pageSlide ?? const AlwaysStoppedAnimation(Offset.zero),
              child: Column(
                children: [
                  AppSearchField(
                  controller: _searchController,
                    hint: 'Search employees...',
                  onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
                  AppSectionTitle(
                    title: 'Team Members',
                    trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                        _query.isEmpty ? '${provider.employees.length} employees' : '${filtered.length} shown',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: listBody),
            ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(
            context,
          ).push<bool>(MaterialPageRoute(builder: (_) => const EmployeeFormScreen()));
          if (created == true && context.mounted) {
            await context.read<EmployeeProvider>().refresh();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
