import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/widgets/app_confirm_dialog.dart';
import 'package:attendance/core/widgets/app_detail.dart';
import 'package:attendance/features/holiday/data/holiday_service.dart';
import 'package:attendance/features/holiday/presentation/holiday_form_dialog.dart';
import 'package:attendance/state/profile_provider.dart';

class HolidayDetailScreen extends StatefulWidget {
  const HolidayDetailScreen({super.key, required this.holidayId, this.initial});

  final int holidayId;
  final Holiday? initial;

  @override
  State<HolidayDetailScreen> createState() => _HolidayDetailScreenState();
}

class _HolidayDetailScreenState extends State<HolidayDetailScreen> {
  final _service = HolidayService();
  Future<Holiday>? _future;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _service.fetch(widget.holidayId);
    });
  }

  Future<void> _edit(Holiday h) async {
    if (await showHolidayFormDialog(context, initial: h) && mounted) {
      _changed = true;
      _reload();
    }
  }

  Future<void> _delete(Holiday h) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Delete holiday',
      message: 'Remove "${h.name}" from the holiday calendar?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.delete(h.id);
      if (!mounted) return;
      AppFeedback.success(context, 'Holiday deleted');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppFeedback.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.watch<ProfileProvider>().canEditOfficeTiming;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: FutureBuilder<Holiday>(
        future: _future,
        builder: (context, snap) {
          final h = snap.data ?? widget.initial;
          if (h == null) {
            final waiting = snap.connectionState == ConnectionState.waiting;
            return AppDetailScaffold(
              title: 'Holiday',
              loading: waiting || snap.error == null,
              error: waiting ? null : snap.error,
              errorTitle: 'Could not load holiday',
              onRetry: _reload,
            );
          }

          return AppDetailScaffold(
            title: 'Holiday',
            busy: _busy,
            onRefresh: () async => _reload(),
            actions: canManage
                ? [
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      onPressed: _busy ? null : () => _edit(h),
                    ),
                    AppDetailMenu(
                      items: [
                        AppDetailMenuItem(
                          label: 'Delete',
                          icon: Icons.delete_outline,
                          destructive: true,
                          onTap: () => _delete(h),
                        ),
                      ],
                    ),
                  ]
                : null,
            header: AppDetailHeader(
              title: h.name,
              icon: Icons.celebration_outlined,
              subtitle: [AppDateFormat.fromRaw(h.date), if (h.day.isNotEmpty) h.day].join(' · '),
              subtitleIcon: Icons.event_outlined,
              caption: h.description.trim().isEmpty ? null : h.description.trim(),
              status: h.isActive ? 'active' : 'inactive',
            ),
            sections: [
              AppDetailSection(
                title: 'Holiday',
                icon: Icons.celebration_outlined,
                children: [
                  AppDetailRow(icon: Icons.label_outline, label: 'Name', value: h.name),
                  AppDetailRow(icon: Icons.event_outlined, label: 'Date', value: AppDateFormat.fromRaw(h.date)),
                  AppDetailRow(icon: Icons.today_outlined, label: 'Day', value: h.day),
                  AppDetailRow(
                    icon: Icons.toggle_on_outlined,
                    label: 'Status',
                    value: h.isActive ? 'Active' : 'Inactive',
                  ),
                ],
              ),
              AppDetailSection(
                title: 'Description',
                icon: Icons.notes_outlined,
                children: [AppDetailText(h.description, emptyText: 'No description')],
              ),
              AppDetailSection(
                title: 'Record',
                icon: Icons.history_rounded,
                children: [
                  AppDetailRow(icon: Icons.person_outline, label: 'Created by', value: h.createdByName),
                  if (h.createdAt != null)
                    AppDetailRow(
                      icon: Icons.schedule_outlined,
                      label: 'Created on',
                      value: AppDateFormat.dateTime(h.createdAt!),
                    ),
                  if (h.updatedAt != null)
                    AppDetailRow(
                      icon: Icons.update_outlined,
                      label: 'Last updated',
                      value: AppDateFormat.dateTime(h.updatedAt!),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
