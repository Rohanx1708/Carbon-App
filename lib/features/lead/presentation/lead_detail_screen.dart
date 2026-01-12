import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/lead/data/lead_service.dart';

class LeadDetailScreen extends StatelessWidget {
  final Lead lead;
  const LeadDetailScreen({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (lead.status.toLowerCase()) {
      case 'hot':
        statusColor = AppTheme.accentRed;
        break;
      case 'warm':
        statusColor = AppTheme.accentOrange;
        break;
      default:
        statusColor = AppTheme.accentGreen;
    }

    return Scaffold(
      appBar: const GradientAppBar(title: 'Lead Details', showBack: true, showProfileAction: false),
      body: SingleChildScrollView(
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
                              if (lead.industry.trim().isNotEmpty)
                                _chip('Industry', lead.industry, AppTheme.primaryBlue),
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
      ),
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
