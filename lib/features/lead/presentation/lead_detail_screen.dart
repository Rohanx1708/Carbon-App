import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/lead/data/lead_service.dart';
import 'package:attendance/features/lead/presentation/lead_form_screen.dart';
import 'package:attendance/state/lead_provider.dart';

class LeadDetailScreen extends StatefulWidget {
  final Lead lead;
  const LeadDetailScreen({super.key, required this.lead});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  final LeadService _service = LeadService();
  Future<Lead>? _future;

  @override
  void initState() {
    super.initState();
    final id = widget.lead.id;
    if (id != null) {
      _future = _service.fetchDetails(id);
    }
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

  Future<void> _confirmAndDelete(int leadId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete lead?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await context.read<LeadProvider>().deleteById(leadId);
    if (!mounted) return;

    if (!success) {
      final err = context.read<LeadProvider>().error;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $err'), backgroundColor: Colors.red),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Lead deleted'), backgroundColor: Colors.red),
    );
    navigator.pop(true);
  }

  Widget _body(BuildContext context, Lead lead) {
    final statusColor = _statusColor(lead.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.06 * 255).round()),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha((0.12 * 255).round()),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.business_outlined, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.clientCompany,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.grey.shade900),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _chip('Status', lead.status, statusColor),
                            if (lead.industry.trim().isNotEmpty) _chip('Industry', lead.industry, AppTheme.primaryBlue),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              _sectionTitle('Company'),
              const SizedBox(height: 8),
              _kv('Company Email', lead.companyEmail),
              _kv('Company Phone', lead.companyPhone),
              const SizedBox(height: 16),
              _sectionTitle('Point of Contact'),
              const SizedBox(height: 8),
              _kv('Designation', lead.pocDesignation),
              _kv('Phone', lead.pocPhone),
              const SizedBox(height: 16),
              _sectionTitle('Requirements'),
              const SizedBox(height: 8),
              Text(
                lead.requirements.trim().isEmpty ? '-' : lead.requirements,
                style: TextStyle(fontSize: 14, height: 1.4, color: Colors.grey.shade800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.lead.id;
    if (id == null || _future == null) {
      return Scaffold(
        appBar: const GradientAppBar(title: 'Lead Details', showBack: true, showProfileAction: false),
        body: const Center(child: Text('Lead id not available')),
      );
    }

    return FutureBuilder<Lead>(
      future: _future,
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        if (loading) {
          return Scaffold(
            appBar: const GradientAppBar(title: 'Lead Details', showBack: true, showProfileAction: false),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: const GradientAppBar(title: 'Lead Details', showBack: true, showProfileAction: false),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed: ${snap.error}'),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _future = _service.fetchDetails(id);
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final lead = snap.data!;
        return Scaffold(
          appBar: GradientAppBar(
            title: 'Lead Details',
            showBack: true,
            showProfileAction: false,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (_) => LeadFormScreen(initialLead: lead)),
                      );
                      if (updated == true && context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                      break;
                    case 'delete':
                      await _confirmAndDelete(id);
                      break;
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ];
                },
              ),
            ],
          ),
          body: _body(context, lead),
        );
      },
    );
  }

  static Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha((0.25 * 255).round())),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  static Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.grey.shade900),
    );
  }

  static Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
