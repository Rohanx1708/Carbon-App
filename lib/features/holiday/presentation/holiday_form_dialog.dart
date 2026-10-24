import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_dialog.dart';
import 'package:attendance/core/widgets/app_picker_fields.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/features/holiday/data/holiday_service.dart';

/// Create (when [initial] is null) or edit a holiday. Resolves to true when saved.
Future<bool> showHolidayFormDialog(BuildContext context, {Holiday? initial, DateTime? date}) async {
  final saved = await AppDialog.show<bool>(
    context,
    builder: (_) => _HolidayFormDialog(initial: initial, initialDate: date),
  );
  return saved == true;
}

class _HolidayFormDialog extends StatefulWidget {
  const _HolidayFormDialog({this.initial, this.initialDate});

  final Holiday? initial;
  final DateTime? initialDate;

  @override
  State<_HolidayFormDialog> createState() => _HolidayFormDialogState();
}

class _HolidayFormDialogState extends State<_HolidayFormDialog> {
  final _service = HolidayService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameC;
  late final TextEditingController _descC;
  DateTime? _date;
  late bool _active;
  bool _saving = false;
  String? _dateError;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final h = widget.initial;
    _nameC = TextEditingController(text: h?.name ?? '');
    _descC = TextEditingController(text: h?.description ?? '');
    _date = h?.dateValue ?? widget.initialDate;
    _active = h?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _dateError = _date == null ? 'Please pick a date' : null);
    if (!(_formKey.currentState?.validate() ?? false) || _dateError != null) return;

    setState(() => _saving = true);
    final date = DateFormat('yyyy-MM-dd').format(_date!);
    try {
      if (_isEdit) {
        await _service.update(
          widget.initial!.id,
          name: _nameC.text.trim(),
          date: date,
          description: _descC.text.trim(),
          isActive: _active,
        );
      } else {
        await _service.create(name: _nameC.text.trim(), date: date, description: _descC.text.trim(), isActive: _active);
      }
      if (!mounted) return;
      AppFeedback.success(context, _isEdit ? 'Holiday updated' : 'Holiday added');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppFeedback.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppDialog(
      title: _isEdit ? 'Edit holiday' : 'Add holiday',
      subtitle: _isEdit ? widget.initial!.name : 'Add a day off to the company calendar',
      icon: Icons.celebration_outlined,
      iconColor: const Color(0xFFEA580C),
      footer: AppDialogButtons(
        confirmLabel: _saving ? 'Saving…' : (_isEdit ? 'Update' : 'Save'),
        confirmIcon: Icons.check_rounded,
        onCancel: _saving ? () {} : () => Navigator.of(context).pop(false),
        onConfirm: _saving ? null : _save,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _nameC,
              label: 'Holiday name',
              labelAbove: true,
              required: true,
              hint: 'e.g. Gandhi Jayanti',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppDialog.fieldGap),
            AppDatePickerField(
              label: 'Date',
              required: true,
              value: _date,
              firstDate: DateTime(DateTime.now().year - 2),
              lastDate: DateTime(DateTime.now().year + 3),
              onChanged: (d) => setState(() {
                _date = d;
                _dateError = null;
              }),
            ),
            if (_dateError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(_dateError!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: AppDialog.fieldGap),
            AppTextField(
              controller: _descC,
              label: 'Description',
              labelAbove: true,
              optional: true,
              hint: 'e.g. National Holiday',
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppDialog.fieldGap),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
                        ),
                        Text(
                          _active ? 'Shown as a holiday for everyone' : 'Hidden from the holiday calendar',
                          style: TextStyle(fontSize: 12, color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(value: _active, onChanged: (v) => setState(() => _active = v)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
