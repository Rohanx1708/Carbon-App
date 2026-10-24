import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_confirm_dialog.dart';
import 'package:attendance/core/widgets/app_dialog.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/features/leave_pool/data/leave_pool_service.dart';

Future<bool> showSetLeaveQuotaDialog(BuildContext context, {required int currentQuota}) async {
  final saved = await AppDialog.show<bool>(
    context,
    dismissible: false,
    builder: (_) => _SetQuotaDialog(currentQuota: currentQuota),
  );
  return saved == true;
}

Future<bool> showAllocateLeaveDialog(
  BuildContext context, {
  required int suggestedDays,
  required int employeeCount,
  required int year,
}) async {
  final saved = await AppDialog.show<bool>(
    context,
    dismissible: false,
    builder: (_) => _AllocateDialog(suggestedDays: suggestedDays, employeeCount: employeeCount, year: year),
  );
  return saved == true;
}

class _SetQuotaDialog extends StatefulWidget {
  const _SetQuotaDialog({required this.currentQuota});

  final int currentQuota;

  @override
  State<_SetQuotaDialog> createState() => _SetQuotaDialogState();
}

class _SetQuotaDialogState extends State<_SetQuotaDialog> {
  final _service = LeavePoolService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _daysC;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _daysC = TextEditingController(text: widget.currentQuota > 0 ? '${widget.currentQuota}' : '');
  }

  @override
  void dispose() {
    _daysC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final days = int.parse(_daysC.text.trim());

    setState(() => _saving = true);
    try {
      await _service.setAnnualQuota(days);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppFeedback.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Yearly leave quota',
      subtitle: 'This is the policy for the year. It does not add days to anyone until you allocate.',
      icon: Icons.event_available_outlined,
      footer: AppDialogButtons(
        confirmLabel: _saving ? 'Saving…' : 'Save quota',
        confirmIcon: Icons.check_rounded,
        onConfirm: _saving ? null : _save,
      ),
      child: Form(
        key: _formKey,
        child: AppTextField(
          controller: _daysC,
          labelAbove: true,
          label: 'Paid leave days',
          hint: 'e.g. 12',
          required: true,
          enabled: !_saving,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            final days = int.tryParse((v ?? '').trim());
            if (days == null || days < 0) return 'Enter the number of paid leave days for the year';
            if (days > 366) return 'Quota cannot be more than 366 days';
            return null;
          },
          onFieldSubmitted: (_) => _save(),
        ),
      ),
    );
  }
}

class _AllocateDialog extends StatefulWidget {
  const _AllocateDialog({required this.suggestedDays, required this.employeeCount, required this.year});

  final int suggestedDays;
  final int employeeCount;
  final int year;

  @override
  State<_AllocateDialog> createState() => _AllocateDialogState();
}

class _AllocateDialogState extends State<_AllocateDialog> {
  final _service = LeavePoolService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _daysC;
  late final TextEditingController _noteC;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _daysC = TextEditingController(text: widget.suggestedDays > 0 ? '${widget.suggestedDays}' : '');
    _noteC = TextEditingController(text: 'Leave allocation ${widget.year}');
  }

  @override
  void dispose() {
    _daysC.dispose();
    _noteC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final days = int.parse(_daysC.text.trim());
    final note = _noteC.text.trim();

    final people = widget.employeeCount;
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Credit everyone?',
      icon: Icons.groups_outlined,
      confirmLabel: 'Allocate',
      message: people <= 0
          ? 'Add $days day${days == 1 ? '' : 's'} to every employee’s leave balance?'
          : 'Add $days day${days == 1 ? '' : 's'} to all $people employee${people == 1 ? '' : 's'}? This cannot be undone from here.',
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await _service.allocateAll(days: days, note: note);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppFeedback.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Allocate leave',
      subtitle: 'Credits the same number of days to every employee for ${widget.year}.',
      icon: Icons.add_card_outlined,
      iconColor: const Color(0xFF0F766E),
      footer: AppDialogButtons(
        confirmLabel: _saving ? 'Allocating…' : 'Allocate',
        confirmIcon: Icons.done_all_rounded,
        onConfirm: _saving ? null : _save,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _daysC,
              labelAbove: true,
              label: 'Days per employee',
              hint: widget.suggestedDays > 0 ? 'Quota is ${widget.suggestedDays}' : 'e.g. 12',
              required: true,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final days = int.tryParse((v ?? '').trim());
                if (days == null || days <= 0) return 'Enter how many days to credit each person';
                if (days > 366) return 'Days cannot be more than 366';
                return null;
              },
            ),
            const SizedBox(height: AppDialog.fieldGap),
            AppTextField(
              controller: _noteC,
              labelAbove: true,
              label: 'Note',
              hint: 'Shown on each person’s balance log',
              required: true,
              enabled: !_saving,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            Text(
              'Set the yearly quota first if you have not already. Allocation adds days on top of current balances.',
              style: TextStyle(fontSize: 12.5, height: 1.4, color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
