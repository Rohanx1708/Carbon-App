import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/leave/data/leave_service.dart';
import 'package:attendance/features/leave/widgets/month_calendar_widget.dart';
import 'package:attendance/state/leave_provider.dart';

class LeaveFormScreen extends StatefulWidget {
  const LeaveFormScreen({super.key});

  @override
  State<LeaveFormScreen> createState() => _LeaveFormScreenState();
}

class _LeaveFormScreenState extends State<LeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  String _type = 'casual';
  String _mode = 'full';
  final _reasonController = TextEditingController();
  PlatformFile? _attachment;
  bool _submitting = false;
  bool _showCalendar = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String _format(DateTime? d) => d == null ? 'Select' : DateFormat('d MMM yyyy').format(d);

  InputDecoration _decoration({required String label, String? hint, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
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
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey.shade900),
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

  Future<void> _pickAttachment() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.any, withData: false);
    if (res != null && res.files.isNotEmpty) {
      setState(() => _attachment = res.files.first);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range')),
      );
      return;
    }
    if (_type == 'sick' && _attachment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment is required for sick leave')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final req = LeaveRequest(
        employeeName: '',
        status: 'pending',
        startDate: _start!,
        endDate: _end!,
        type: _type,
        reason: _reasonController.text.trim(),
        attachmentName: _attachment?.name,
        attachmentPath: _attachment?.path,
      );
      final ok = await context.read<LeaveProvider>().add(req);
      if (!ok) {
        final err = context.read<LeaveProvider>().error;
        throw err ?? Exception('Failed');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave submitted')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'New Leave Request', showBack: true),
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
                        'Request leave',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.grey.shade900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fill the details below to submit a leave request.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                      ),
                      const SizedBox(height: 16),
                      _sectionTitle('Type & Mode', Icons.tune),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _type,
                        items: const [
                          DropdownMenuItem(value: 'casual', child: Text('Casual Leave')),
                          DropdownMenuItem(value: 'sick', child: Text('Sick Leave')),
                        ],
                        onChanged: (v) => setState(() => _type = v ?? 'casual'),
                        decoration: _decoration(
                          label: 'Leave Type *',
                          prefixIcon: const Icon(Icons.event_note_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Leave Mode',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ChoiceChip(
                            label: Text(
                              'Full Day',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _mode == 'full' ? AppTheme.primaryBlue : Colors.grey.shade700,
                              ),
                            ),
                            selected: _mode == 'full',
                            selectedColor: AppTheme.primaryBlue.withAlpha((0.12 * 255).round()),
                            backgroundColor: Colors.grey.shade100,
                            onSelected: (_) => setState(() => _mode = 'full'),
                          ),
                          ChoiceChip(
                            label: Text(
                              'Half Day',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _mode == 'first_half' ? AppTheme.primaryBlue : Colors.grey.shade700,
                              ),
                            ),
                            selected: _mode == 'first_half',
                            selectedColor: AppTheme.primaryBlue.withAlpha((0.12 * 255).round()),
                            backgroundColor: Colors.grey.shade100,
                            onSelected: (_) => setState(() => _mode = 'first_half'),
                          ),
                          ChoiceChip(
                            label: Text(
                              'Alternative',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _mode == 'second_half' ? AppTheme.primaryBlue : Colors.grey.shade700,
                              ),
                            ),
                            selected: _mode == 'second_half',
                            selectedColor: AppTheme.primaryBlue.withAlpha((0.12 * 255).round()),
                            backgroundColor: Colors.grey.shade100,
                            onSelected: (_) => setState(() => _mode = 'second_half'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Dates', Icons.calendar_month_outlined),
                      const SizedBox(height: 12),
                      TextFormField(
                        readOnly: true,
                        onTap: () => setState(() => _showCalendar = !_showCalendar),
                        controller: _dateController,
                        style: const TextStyle(color: Colors.black),
                        decoration: _decoration(
                          label: 'Date Range *',
                          hint: '${_format(_start)} - ${_format(_end)}',
                          prefixIcon: const Icon(Icons.date_range_outlined),
                          suffixIcon: Icon(Icons.expand_more, color: Colors.grey.shade700),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => SizeTransition(
                          sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                          axisAlignment: -1.0,
                          child: FadeTransition(opacity: animation, child: child),
                        ),
                        child: !_showCalendar
                            ? const SizedBox.shrink(key: ValueKey('calendar-hidden'))
                            : Column(
                                key: const ValueKey('calendar-visible'),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 16),
                                  MonthCalendarWidget(
                                    isRangeSelection: true,
                                    startDate: _start,
                                    endDate: _end,
                                    onRangeSelected: (range) {
                                      setState(() {
                                        _start = range?.start;
                                        _end = range?.end;
                                        if (_start != null && _end != null) {
                                          _dateController.text = '${_format(_start)} - ${_format(_end)}';
                                        } else {
                                          _dateController.text = '';
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => setState(() => _showCalendar = false),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Done'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _start = null;
                                              _end = null;
                                              _showCalendar = false;
                                              _dateController.text = '';
                                            });
                                          },
                                          icon: const Icon(Icons.clear),
                                          label: const Text('Clear'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Reason', Icons.chat_bubble_outline),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _reasonController,
                        decoration: _decoration(
                          label: 'Reason *',
                          hint: 'Include comments for your approver',
                          prefixIcon: const Icon(Icons.edit_note_outlined),
                        ),
                        maxLines: 3,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a reason' : null,
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Attachments', Icons.attach_file),
                      const SizedBox(height: 12),
                      DottedBorder(
                        color: Colors.grey.shade300,
                        strokeWidth: 1.5,
                        dashPattern: const [6, 6],
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(14),
                        child: InkWell(
                          onTap: _pickAttachment,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.upload_file, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _attachment?.name ?? 'Upload a file',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _type == 'sick'
                                            ? 'Required for sick leave'
                                            : 'Optional',
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_attachment != null)
                                  IconButton(
                                    tooltip: 'Remove',
                                    onPressed: () => setState(() => _attachment = null),
                                    icon: const Icon(Icons.close),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
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
                            const Icon(Icons.send, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            _submitting ? 'Submitting...' : 'Submit Request',
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


