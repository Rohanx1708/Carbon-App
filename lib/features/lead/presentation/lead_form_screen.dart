import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/lead/data/lead_service.dart';
import 'package:attendance/state/lead_provider.dart';

class LeadFormScreen extends StatefulWidget {
  const LeadFormScreen({super.key});

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();

  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _clientCompanyC = TextEditingController();
  final _companyEmailC = TextEditingController();
  final _companyPhoneC = TextEditingController();
  final _pocDesignationC = TextEditingController();
  final _pocPhoneC = TextEditingController();
  final _industryC = TextEditingController();
  final _requirementsC = TextEditingController();

  String _status = 'Cold';
  bool _submitting = false;

  @override
  void dispose() {
    _clientCompanyC.dispose();
    _companyEmailC.dispose();
    _companyPhoneC.dispose();
    _pocDesignationC.dispose();
    _pocPhoneC.dispose();
    _industryC.dispose();
    _requirementsC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = context.read<LeadProvider>();

    try {
      final lead = Lead(
        clientCompany: _clientCompanyC.text.trim(),
        companyEmail: _companyEmailC.text.trim(),
        companyPhone: _companyPhoneC.text.trim(),
        pocDesignation: _pocDesignationC.text.trim(),
        pocPhone: _pocPhoneC.text.trim(),
        status: _status,
        industry: _industryC.text.trim(),
        requirements: _requirementsC.text.trim(),
        createdAt: DateTime.now(),
      );

      final ok = await provider.add(lead);
      if (!ok) {
        throw provider.error ?? Exception('Failed');
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Lead saved'), backgroundColor: Colors.green),
      );
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  InputDecoration _decoration({required String label, String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTheme.primaryBlue.withAlpha((0.6 * 255).round())),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _sectionTitle(String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withAlpha((0.12 * 255).round()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.grey.shade900),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).round()),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'New Lead', showBack: true, showProfileAction: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create a new lead',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.grey.shade900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add company details, point of contact, and requirements.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3),
                      ),
                      const SizedBox(height: 16),
                      _sectionTitle('Company', Icons.apartment_outlined),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, c) {
                          final twoCol = c.maxWidth >= 520;
                          final gap = twoCol ? 12.0 : 0.0;
                          final w = twoCol ? (c.maxWidth - gap) / 2 : c.maxWidth;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: twoCol ? c.maxWidth : c.maxWidth,
                                child: TextFormField(
                                  controller: _clientCompanyC,
                                  decoration: _decoration(
                                    label: 'Client/Company *',
                                    hint: 'e.g. Acme Pvt Ltd',
                                    prefixIcon: const Icon(Icons.business_outlined),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                              SizedBox(
                                width: w,
                                child: TextFormField(
                                  controller: _companyEmailC,
                                  decoration: _decoration(
                                    label: 'Company Email *',
                                    hint: 'e.g. info@acme.com',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    final value = (v ?? '').trim();
                                    if (value.isEmpty) return 'Required';
                                    if (!_emailRegex.hasMatch(value)) return 'Enter valid email';
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                width: w,
                                child: TextFormField(
                                  controller: _companyPhoneC,
                                  decoration: _decoration(
                                    label: 'Company Phone *',
                                    hint: 'e.g. +91 99999 99999',
                                    prefixIcon: const Icon(Icons.phone_outlined),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  validator: (v) {
                                    final value = (v ?? '').trim();
                                    if (value.isEmpty) return 'Required';
                                    if (value.length != 10) return 'Enter 10-digit phone number';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Point of Contact', Icons.badge_outlined),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, c) {
                          final twoCol = c.maxWidth >= 520;
                          final gap = twoCol ? 12.0 : 0.0;
                          final w = twoCol ? (c.maxWidth - gap) / 2 : c.maxWidth;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: w,
                                child: TextFormField(
                                  controller: _pocDesignationC,
                                  decoration: _decoration(
                                    label: 'Designation (POC) *',
                                    hint: 'e.g. HR Manager',
                                    prefixIcon: const Icon(Icons.work_outline),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                              SizedBox(
                                width: w,
                                child: TextFormField(
                                  controller: _pocPhoneC,
                                  decoration: _decoration(
                                    label: 'Phone (POC) *',
                                    hint: 'e.g. +91 88888 88888',
                                    prefixIcon: const Icon(Icons.call_outlined),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  validator: (v) {
                                    final value = (v ?? '').trim();
                                    if (value.isEmpty) return 'Required';
                                    if (value.length != 10) return 'Enter 10-digit phone number';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Lead Details', Icons.tune),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, c) {
                          final twoCol = c.maxWidth >= 520;
                          final gap = twoCol ? 12.0 : 0.0;
                          final w = twoCol ? (c.maxWidth - gap) / 2 : c.maxWidth;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: w,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _status,
                                  items: const [
                                    DropdownMenuItem(value: 'Cold', child: Text('Cold')),
                                    DropdownMenuItem(value: 'Warm', child: Text('Warm')),
                                    DropdownMenuItem(value: 'Hot', child: Text('Hot')),
                                  ],
                                  onChanged: (v) => setState(() => _status = v ?? 'Cold'),
                                  decoration: _decoration(
                                    label: 'Status',
                                    prefixIcon: const Icon(Icons.local_fire_department_outlined),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: w,
                                child: TextFormField(
                                  controller: _industryC,
                                  decoration: _decoration(
                                    label: 'Industry',
                                    hint: 'e.g. Manufacturing',
                                    prefixIcon: const Icon(Icons.factory_outlined),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: c.maxWidth,
                                child: TextFormField(
                                  controller: _requirementsC,
                                  decoration: _decoration(
                                    label: 'Requirements',
                                    hint: 'Write requirements or notes...',
                                    prefixIcon: const Icon(Icons.description_outlined),
                                  ),
                                  maxLines: 4,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.primaryBlueLight]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withAlpha((0.28 * 255).round()),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _submitting ? null : _submit,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_submitting)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          else
                            const Icon(Icons.save, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            _submitting ? 'Saving...' : 'Save Lead',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
