import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_dialog.dart';
import 'package:attendance/core/widgets/app_picker_fields.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/features/employee/data/employee_service.dart';

class MarkHolidayResult {
  const MarkHolidayResult({required this.date, required this.notes});

  final String date;
  final String notes;
}

class MarkAttendanceResult {
  const MarkAttendanceResult({
    required this.employeeId,
    required this.attendanceDate,
    required this.status,
    this.checkIn,
    this.checkOut,
  });

  final int employeeId;
  final String attendanceDate;
  final String status;
  final String? checkIn;
  final String? checkOut;
}

Future<MarkHolidayResult?> showMarkHolidayDialog(BuildContext context) {
  return AppDialog.show<MarkHolidayResult>(context, builder: (_) => const _MarkHolidayDialog());
}

Future<MarkAttendanceResult?> showMarkAttendanceDialog(BuildContext context, {required List<Employee> employees}) {
  return AppDialog.show<MarkAttendanceResult>(context, builder: (_) => _MarkAttendanceDialog(employees: employees));
}

class _MarkHolidayDialog extends StatefulWidget {
  const _MarkHolidayDialog();

  @override
  State<_MarkHolidayDialog> createState() => _MarkHolidayDialogState();
}

class _MarkHolidayDialogState extends State<_MarkHolidayDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesC = TextEditingController();
  DateTime? _date = DateUtils.dateOnly(DateTime.now());
  String? _dateError;

  @override
  void dispose() {
    _notesC.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _dateError = _date == null ? 'Pick a date' : null);
    final notesOk = _formKey.currentState?.validate() ?? false;
    if (_dateError != null || !notesOk) return;
    Navigator.of(
      context,
    ).pop(MarkHolidayResult(date: DateFormat('yyyy-MM-dd').format(_date!), notes: _notesC.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Mark holiday',
      subtitle: 'Applies holiday attendance to everyone for the selected date.',
      icon: Icons.celebration_outlined,
      iconColor: const Color(0xFF2563EB),
      footer: AppDialogButtons(confirmLabel: 'Mark holiday', confirmIcon: Icons.check_rounded, onConfirm: _submit),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDatePickerField(
              label: 'Date',
              required: true,
              value: _date,
              onChanged: (d) => setState(() {
                _date = DateUtils.dateOnly(d);
                _dateError = null;
              }),
            ),
            if (_dateError != null) ...[
              const SizedBox(height: 6),
              Text(_dateError!, style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: AppDialog.fieldGap),
            AppTextField(
              controller: _notesC,
              label: 'Notes',
              labelAbove: true,
              required: true,
              hint: 'e.g. Gandhi Jayanti',
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkAttendanceDialog extends StatefulWidget {
  const _MarkAttendanceDialog({required this.employees});

  final List<Employee> employees;

  @override
  State<_MarkAttendanceDialog> createState() => _MarkAttendanceDialogState();
}

class _MarkAttendanceDialogState extends State<_MarkAttendanceDialog> {
  late int? _employeeId;
  DateTime? _date = DateUtils.dateOnly(DateTime.now());
  String _status = 'present';
  TimeOfDay? _checkIn = const TimeOfDay(hour: 9, minute: 30);
  TimeOfDay? _checkOut = const TimeOfDay(hour: 18, minute: 30);
  String? _employeeError;
  String? _dateError;

  static const _statuses = [('present', 'Present'), ('absent', 'Absent'), ('leave', 'Leave'), ('wfh', 'WFH')];

  bool get _needsTimes => _status == 'present' || _status == 'wfh';

  @override
  void initState() {
    super.initState();
    _employeeId = widget.employees.isEmpty ? null : widget.employees.first.id;
  }

  void _submit() {
    setState(() {
      _employeeError = _employeeId == null ? 'Select an employee' : null;
      _dateError = _date == null ? 'Pick a date' : null;
    });
    if (_employeeError != null || _dateError != null) return;

    Navigator.of(context).pop(
      MarkAttendanceResult(
        employeeId: _employeeId!,
        attendanceDate: DateFormat('yyyy-MM-dd').format(_date!),
        status: _status,
        checkIn: _needsTimes && _checkIn != null ? AppTimePickerField.apiFormat(_checkIn!) : null,
        checkOut: _needsTimes && _checkOut != null ? AppTimePickerField.apiFormat(_checkOut!) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppDialog(
      title: 'Mark attendance',
      subtitle: 'Record attendance for an employee on a specific date.',
      icon: Icons.how_to_reg_outlined,
      iconColor: const Color(0xFF16A34A),
      footer: AppDialogButtons(confirmLabel: 'Save', confirmIcon: Icons.save_outlined, onConfirm: _submit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Employee',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textSecondary),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            value: _employeeId,
            decoration: InputDecoration(
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: [
              for (final e in widget.employees)
                DropdownMenuItem(
                  value: e.id,
                  child: Text(e.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() {
              _employeeId = v;
              _employeeError = null;
            }),
          ),
          if (_employeeError != null) ...[
            const SizedBox(height: 6),
            Text(_employeeError!, style: TextStyle(fontSize: 12.5, color: scheme.error)),
          ],
          const SizedBox(height: AppDialog.fieldGap),
          AppDatePickerField(
            label: 'Date',
            required: true,
            value: _date,
            onChanged: (d) => setState(() {
              _date = DateUtils.dateOnly(d);
              _dateError = null;
            }),
          ),
          if (_dateError != null) ...[
            const SizedBox(height: 6),
            Text(_dateError!, style: TextStyle(fontSize: 12.5, color: scheme.error)),
          ],
          const SizedBox(height: AppDialog.fieldGap),
          Text(
            'Status',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _statuses)
                ChoiceChip(
                  label: Text(s.$2),
                  selected: _status == s.$1,
                  onSelected: (_) => setState(() => _status = s.$1),
                ),
            ],
          ),
          if (_needsTimes) ...[
            const SizedBox(height: AppDialog.fieldGap),
            Row(
              children: [
                Expanded(
                  child: AppTimePickerField(
                    label: 'Check in',
                    value: _checkIn,
                    onChanged: (t) => setState(() => _checkIn = t),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTimePickerField(
                    label: 'Check out',
                    value: _checkOut,
                    onChanged: (t) => setState(() => _checkOut = t),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
