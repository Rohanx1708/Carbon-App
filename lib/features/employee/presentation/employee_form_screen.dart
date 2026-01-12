import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_topbar.dart';

class EmployeeFormScreen extends StatefulWidget {
  const EmployeeFormScreen({super.key});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _firstNameC = TextEditingController();
  final _lastNameC = TextEditingController();
  final _fatherNameC = TextEditingController();
  final _titleC = TextEditingController();
  final _phoneC = TextEditingController();
  final _emailC = TextEditingController();
  final _officialEmailC = TextEditingController();
  final _aadhaarC = TextEditingController();
  final _panC = TextEditingController();
  final _presentAddressC = TextEditingController();
  final _permanentAddressC = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _firstNameC.dispose();
    _lastNameC.dispose();
    _fatherNameC.dispose();
    _titleC.dispose();
    _phoneC.dispose();
    _emailC.dispose();
    _officialEmailC.dispose();
    _aadhaarC.dispose();
    _panC.dispose();
    _presentAddressC.dispose();
    _permanentAddressC.dispose();
    super.dispose();
  }

  InputDecoration _decoration({required String label, String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
      hintText: hint,
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final map = <String, String>{
        'firstName': _firstNameC.text.trim(),
        'lastName': _lastNameC.text.trim(),
        'fatherName': _fatherNameC.text.trim(),
        'title': _titleC.text.trim(),
        'phone': _phoneC.text.trim(),
        'email': _emailC.text.trim(),
        'officialEmail': _officialEmailC.text.trim(),
        'aadhaar': _aadhaarC.text.trim(),
        'pan': _panC.text.trim(),
        'presentAddress': _presentAddressC.text.trim(),
        'permanentAddress': _permanentAddressC.text.trim(),
      };
      if (!mounted) return;
      Navigator.pop(context, map);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Add Employee', showBack: true),
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
                        'Employee details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.grey.shade900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fill personal info and contact details to create the employee profile.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3),
                      ),
                      const SizedBox(height: 16),
                      _sectionTitle('Basic Info', Icons.person_outline),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, c) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _firstNameC,
                                      decoration: _decoration(
                                        label: 'First name *',
                                        prefixIcon: const Icon(Icons.badge_outlined),
                                      ),
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _lastNameC,
                                      decoration: _decoration(
                                        label: 'Last name *',
                                        prefixIcon: const Icon(Icons.badge_outlined),
                                      ),
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _fatherNameC,
                                decoration: _decoration(
                                  label: 'Father name',
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _titleC,
                                decoration: _decoration(
                                  label: 'Job title',
                                  prefixIcon: const Icon(Icons.work_outline),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Contact', Icons.call_outlined),
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
                                  controller: _phoneC,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  decoration: _decoration(
                                    label: 'Phone *',
                                    prefixIcon: const Icon(Icons.phone_outlined),
                                  ),
                                  validator: (v) {
                                    final value = (v ?? '').trim();
                                    if (value.isEmpty) return 'Required';
                                    if (value.length != 10) return 'Enter 10-digit phone number';
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                width: w,
                                child: TextFormField(
                                  controller: _emailC,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _decoration(
                                    label: 'Email *',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                  ),
                                  validator: (v) {
                                    final value = (v ?? '').trim();
                                    if (value.isEmpty) return 'Required';
                                    if (!_emailRegex.hasMatch(value)) return 'Enter valid email';
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                width: c.maxWidth,
                                child: TextFormField(
                                  controller: _officialEmailC,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _decoration(
                                    label: 'Official email',
                                    prefixIcon: const Icon(Icons.mark_email_read_outlined),
                                  ),
                                  validator: (v) {
                                    final value = (v ?? '').trim();
                                    if (value.isEmpty) return null;
                                    if (!_emailRegex.hasMatch(value)) return 'Enter valid email';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Identity', Icons.verified_user_outlined),
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
                                  controller: _aadhaarC,
                                  decoration: _decoration(
                                    label: 'Aadhaar',
                                    prefixIcon: const Icon(Icons.credit_card_outlined),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: w,
                                child: TextFormField(
                                  controller: _panC,
                                  decoration: _decoration(
                                    label: 'PAN',
                                    prefixIcon: const Icon(Icons.badge_outlined),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Address', Icons.home_outlined),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _presentAddressC,
                        maxLines: 2,
                        decoration: _decoration(
                          label: 'Present address',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _permanentAddressC,
                        maxLines: 2,
                        decoration: _decoration(
                          label: 'Permanent address',
                          prefixIcon: const Icon(Icons.location_city_outlined),
                        ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            const Icon(Icons.person_add_alt, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            _submitting ? 'Saving...' : 'Add Employee',
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


