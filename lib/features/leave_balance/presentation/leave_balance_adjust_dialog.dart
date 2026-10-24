import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/widgets/app_dialog.dart';
import 'package:attendance/core/widgets/app_dropdown.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/features/leave_balance/data/leave_balance_service.dart';

Future<bool> showAdjustLeaveBalanceDialog(BuildContext context, {required LeaveBalancePerson person}) async {
  final saved = await AppDialog.show<bool>(context, dismissible: false, builder: (_) => _AdjustDialog(person: person));
  return saved == true;
}

class _AdjustDialog extends StatefulWidget {
  const _AdjustDialog({required this.person});

  final LeaveBalancePerson person;

  @override
  State<_AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends State<_AdjustDialog> {
  final _service = LeaveBalanceService();
  final _formKey = GlobalKey<FormState>();
  final _daysC = TextEditingController();
  final _noteC = TextEditingController();
  String _type = 'credit';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _daysC.dispose();
    _noteC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final days = int.tryParse(_daysC.text.trim())!;
    final note = _noteC.text.trim();
    if (_type == 'debit' && days > widget.person.balance) {
      setState(
        () => _error =
            '${widget.person.name} only has ${widget.person.balance} day${widget.person.balance == 1 ? '' : 's'} remaining',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.adjust(employeeId: widget.person.employeeId, type: _type, days: days, note: note);
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
    final credit = _type == 'credit';
    return AppDialog(
      title: 'Adjust balance',
      subtitle:
          '${widget.person.name} · ${widget.person.balance} day${widget.person.balance == 1 ? '' : 's'} remaining',
      icon: credit ? Icons.add_circle_outline : Icons.remove_circle_outline,
      iconColor: credit ? AppColors.success : AppColors.error,
      footer: AppDialogButtons(
        confirmLabel: _saving ? 'Saving…' : (credit ? 'Add days' : 'Remove days'),
        confirmIcon: credit ? Icons.add_rounded : Icons.remove_rounded,
        destructive: !credit,
        onConfirm: _saving ? null : _save,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDropdown<String>(
              labelAbove: true,
              label: 'Type',
              required: true,
              value: _type,
              onChanged: _saving
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() {
                        _type = v;
                        _error = null;
                      });
                    },
              items: appDropdownItems(context, const [
                MapEntry('credit', 'Credit — add days'),
                MapEntry('debit', 'Debit — remove days'),
              ]),
            ),
            const SizedBox(height: AppDialog.fieldGap),
            AppTextField(
              controller: _daysC,
              labelAbove: true,
              label: 'Days',
              hint: 'e.g. 12',
              required: true,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final days = int.tryParse((v ?? '').trim());
                if (days == null || days <= 0) {
                  return 'Enter how many days to ${_type == 'credit' ? 'add' : 'remove'}';
                }
                if (days > 366) return 'Days cannot be more than 366';
                return null;
              },
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: AppDialog.fieldGap),
            AppTextField(
              controller: _noteC,
              labelAbove: true,
              label: 'Note',
              hint: credit ? 'Annual allocation 2026' : 'Correction',
              required: true,
              enabled: !_saving,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}
