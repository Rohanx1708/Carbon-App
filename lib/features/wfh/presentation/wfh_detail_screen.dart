import 'package:flutter/material.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/widgets/app_detail.dart';
import 'package:attendance/core/widgets/app_prompt_dialog.dart';
import 'package:attendance/features/wfh/data/wfh_models.dart';
import 'package:attendance/features/wfh/data/wfh_service.dart';
import 'package:attendance/state/profile_provider.dart';
import 'package:attendance/state/wfh_provider.dart';

class WfhDetailScreen extends StatefulWidget {
  const WfhDetailScreen({super.key, required this.requestId, this.initial});

  final int requestId;
  final WfhRequest? initial;

  @override
  State<WfhDetailScreen> createState() => _WfhDetailScreenState();
}

class _WfhDetailScreenState extends State<WfhDetailScreen> {
  final WfhService _service = WfhService();
  Future<WfhRequest>? _future;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchDetail(widget.requestId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadIfNeeded();
    });
  }

  void _reload() {
    setState(() {
      _future = _service.fetchDetail(widget.requestId);
    });
  }

  Future<String?> _askReviewNote({required String title, required String hint}) {
    return AppPromptDialog.show(
      context,
      title: title,
      label: 'Review note',
      hint: hint,
      confirmLabel: 'Confirm',
      icon: Icons.rate_review_outlined,
      minLines: 2,
      maxLines: 4,
    );
  }

  Future<void> _approve(WfhRequest r) async {
    final note = await _askReviewNote(title: 'Approve WFH', hint: 'Review note for the employee');
    if (note == null || !mounted) return;
    setState(() => _acting = true);
    final ok = await context.read<WfhProvider>().approve(requestId: r.id, reviewNote: note);
    if (!mounted) return;
    setState(() => _acting = false);
    if (!ok) {
      AppFeedback.error(context, context.read<WfhProvider>().error ?? Exception('Approve failed'));
      return;
    }
    AppFeedback.success(context, 'Request approved');
    Navigator.pop(context, true);
  }

  Future<void> _reject(WfhRequest r) async {
    final note = await _askReviewNote(title: 'Reject WFH', hint: 'Reason for rejection');
    if (note == null || !mounted) return;
    setState(() => _acting = true);
    final ok = await context.read<WfhProvider>().reject(requestId: r.id, reviewNote: note);
    if (!mounted) return;
    setState(() => _acting = false);
    if (!ok) {
      AppFeedback.error(context, context.read<WfhProvider>().error ?? Exception('Reject failed'));
      return;
    }
    AppFeedback.success(context, 'Request rejected');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final canReview = context.watch<ProfileProvider>().canReviewLeaveAndWfh;

    return FutureBuilder<WfhRequest>(
      future: _future,
      builder: (context, snap) {
        final r = snap.data ?? widget.initial;
        if (r == null) {
          final waiting = snap.connectionState == ConnectionState.waiting;
          return AppDetailScaffold(
            title: 'WFH Request',
            loading: waiting || snap.error == null,
            error: waiting ? null : snap.error,
            errorTitle: 'Could not load request',
            onRetry: _reload,
          );
        }

        final pending = r.status.toLowerCase() == 'pending';
        final reviewed = (r.reviewNote ?? '').trim().isNotEmpty || r.reviewedAt != null;

        return AppDetailScaffold(
          title: 'WFH Request',
          busy: _acting,
          onRefresh: () async => _reload(),
          header: AppDetailHeader(
            title: r.employeeDisplayName,
            avatarText: r.employeeDisplayName,
            subtitle: 'WFH on ${AppDateFormat.fromRaw(r.wfhDate)}',
            subtitleIcon: Icons.home_work_outlined,
            caption: r.employee?.department,
            status: r.status.isEmpty ? 'pending' : r.status,
          ),
          sections: [
            AppDetailSection(
              title: 'Request',
              icon: Icons.home_work_outlined,
              children: [
                AppDetailRow(icon: Icons.event_outlined, label: 'WFH date', value: AppDateFormat.fromRaw(r.wfhDate)),
                AppDetailRow(
                  icon: Icons.schedule_outlined,
                  label: 'Requested on',
                  value: AppDateFormat.dateTime(r.createdAt),
                ),
              ],
            ),
            AppDetailSection(
              title: 'Employee',
              icon: Icons.contact_mail_outlined,
              children: [
                AppDetailRow(icon: Icons.email_outlined, label: 'Email', value: r.employee?.email),
                AppDetailRow(icon: Icons.apartment_outlined, label: 'Department', value: r.employee?.department),
              ],
            ),
            AppDetailSection(
              title: 'Reason',
              icon: Icons.notes_outlined,
              children: [AppDetailText(r.reason, emptyText: 'No reason given')],
            ),
            if (reviewed)
              AppDetailSection(
                title: 'Review',
                icon: Icons.rate_review_outlined,
                children: [
                  if (r.reviewer != null)
                    AppDetailRow(icon: Icons.person_outline, label: 'Reviewer', value: r.reviewer!.name),
                  if (r.reviewedAt != null)
                    AppDetailRow(
                      icon: Icons.schedule_outlined,
                      label: 'Reviewed at',
                      value: AppDateFormat.dateTime(r.reviewedAt!),
                    ),
                  AppDetailRow(icon: Icons.comment_outlined, label: 'Note', value: r.reviewNote),
                ],
              ),
          ],
          bottomBar: pending && canReview
              ? AppDetailActionBar(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                      onPressed: _acting ? null : () => _reject(r),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Reject'),
                    ),
                    FilledButton.icon(
                      onPressed: _acting ? null : () => _approve(r),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Approve'),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}
