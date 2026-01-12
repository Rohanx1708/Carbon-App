import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/presentation/app_drawer.dart';
import 'package:attendance/features/lead/presentation/lead_detail_screen.dart';
import 'package:attendance/features/lead/presentation/lead_form_screen.dart';
import 'package:attendance/state/lead_provider.dart';

class LeadScreen extends StatefulWidget {
  const LeadScreen({super.key});

  @override
  State<LeadScreen> createState() => _LeadScreenState();
}

class _LeadScreenState extends State<LeadScreen> {
  final _searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  List<dynamic> _filtered(List<dynamic> leads) {
    final q = _searchC.text.trim().toLowerCase();
    if (q.isEmpty) return leads;
    return leads.where((l) {
      final client = (l.clientCompany as String).toLowerCase();
      final email = (l.companyEmail as String).toLowerCase();
      final phone = (l.companyPhone as String).toLowerCase();
      final industry = (l.industry as String).toLowerCase();
      final status = (l.status as String).toLowerCase();
      return client.contains(q) || email.contains(q) || phone.contains(q) || industry.contains(q) || status.contains(q);
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'hot':
        return AppTheme.accentRed;
      case 'warm':
        return AppTheme.accentOrange;
      default:
        return AppTheme.accentGreen;
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LeadFormScreen()),
    );
    if (created == true) {
      if (!mounted) return;
      await context.read<LeadProvider>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LeadProvider>();
    final list = _filtered(vm.leads);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GradientAppBar(title: 'Leads'),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search leads...',
                    prefixIcon: Icon(Icons.search, color: AppTheme.primaryBlue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: vm.loading
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                        ? const _EmptyState()
                        : ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final lead = list[i];
                              final statusColor = _statusColor(lead.status as String);
                              return Container(
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
                                child: ListTile(
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha((0.12 * 255).round()),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.business_outlined, color: statusColor),
                                  ),
                                  title: Text(
                                    lead.clientCompany as String,
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Text(
                                        lead.companyEmail as String,
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${lead.companyPhone} • ${lead.industry}',
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha((0.12 * 255).round()),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: statusColor.withAlpha((0.25 * 255).round())),
                                    ),
                                    child: Text(
                                      lead.status as String,
                                      style: TextStyle(fontWeight: FontWeight.w700, color: statusColor, fontSize: 12),
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => LeadDetailScreen(lead: lead),
                                      ),
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
          Text(
            'No Leads Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first lead',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
