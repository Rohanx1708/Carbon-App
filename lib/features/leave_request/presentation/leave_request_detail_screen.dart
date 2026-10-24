import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/widgets/app_detail.dart';
import 'package:attendance/core/widgets/app_prompt_dialog.dart';
import 'package:attendance/features/leave_request/data/leave_request_service.dart';
import 'package:attendance/state/leave_request_provider.dart';
import 'package:attendance/state/profile_provider.dart';

class LeaveRequestDetailScreen extends StatefulWidget {
  const LeaveRequestDetailScreen({super.key, required this.requestId, this.initial});

  final int requestId;
  final LeaveRequestItem? initial;

  @override
  State<LeaveRequestDetailScreen> createState() => _LeaveRequestDetailScreenState();
}

class _LeaveRequestDetailScreenState extends State<LeaveRequestDetailScreen> {
  final LeaveRequestService _service = LeaveRequestService();
  Future<LeaveRequestItem>? _future;
  bool _acting = false;
  LeaveRequestPreview? _preview;
  bool _previewing = false;
  Object? _previewError;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchDetail(widget.requestId).then((r) {
      _loadPreview(r);
      return r;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadIfNeeded();
    });
  }

  void _reload() {
    setState(() {
      _preview = null;
      _previewError = null;
      _future = _service.fetchDetail(widget.requestId).then((r) {
        _loadPreview(r);
        return r;
      });
    });
  }

  Future<void> _loadPreview(LeaveRequestItem r) async {
    if (!mounted || !context.read<ProfileProvider>().isAdminOrManager) return;
    if (r.startDate.isEmpty || r.endDate.isEmpty) return;
    setState(() {
      _previewing = true;
      _previewError = null;
    });
    try {
      final preview = await _service.preview(startDate: r.startDate, endDate: r.endDate);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _previewing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewError = e;
        _preview = null;
        _previewing = false;
      });
    }
  }

  Future<String?> _askNote({
    required String title,
    required String subtitle,
    required String hint,
    required String confirmLabel,
    bool destructive = false,
  }) {
    return AppPromptDialog.show(
      context,
      title: title,
      subtitle: subtitle,
      label: destructive ? 'Cancel reason' : 'Note',
      hint: hint,
      confirmLabel: confirmLabel,
      destructive: destructive,
      icon: destructive ? Icons.cancel_outlined : Icons.rate_review_outlined,
      minLines: 2,
      maxLines: 4,
    );
  }

  Future<void> _approve(LeaveRequestItem r) async {
    final note = await _askNote(
      title: 'Approve leave',
      subtitle: r.employeeDisplayName,
      hint: 'Review note for the employee',
      confirmLabel: 'Approve',
    );
    if (note == null || !mounted) return;
    setState(() => _acting = true);
    final ok = await context.read<LeaveRequestProvider>().approve(requestId: r.id, reviewNote: note);
    if (!mounted) return;
    setState(() => _acting = false);
    if (!ok) {
      AppFeedback.error(context, context.read<LeaveRequestProvider>().error ?? Exception('Approve failed'));
      return;
    }
    AppFeedback.success(context, 'Request approved');
    Navigator.pop(context, true);
  }

  Future<void> _reject(LeaveRequestItem r) async {
    final note = await _askNote(
      title: 'Reject leave',
      subtitle: r.employeeDisplayName,
      hint: 'Reason for rejection',
      confirmLabel: 'Reject',
      destructive: true,
    );
    if (note == null || !mounted) return;
    setState(() => _acting = true);
    final ok = await context.read<LeaveRequestProvider>().reject(requestId: r.id, reviewNote: note);
    if (!mounted) return;
    setState(() => _acting = false);
    if (!ok) {
      AppFeedback.error(context, context.read<LeaveRequestProvider>().error ?? Exception('Reject failed'));
      return;
    }
    AppFeedback.success(context, 'Request rejected');
    Navigator.pop(context, true);
  }

  Future<void> _cancel(LeaveRequestItem r) async {
    final reason = await _askNote(
      title: 'Cancel leave',
      subtitle: r.dateRangeLabel,
      hint: 'Plans changed',
      confirmLabel: 'Cancel leave',
      destructive: true,
    );
    if (reason == null || !mounted) return;
    setState(() => _acting = true);
    final ok = await context.read<LeaveRequestProvider>().cancel(requestId: r.id, cancelReason: reason);
    if (!mounted) return;
    setState(() => _acting = false);
    if (!ok) {
      AppFeedback.error(context, context.read<LeaveRequestProvider>().error ?? Exception('Cancel failed'));
      return;
    }
    AppFeedback.success(context, 'Leave cancelled');
    Navigator.pop(context, true);
  }

  static int? _days(LeaveRequestItem r) {
    if (r.days != null && r.days! > 0) return r.days;
    final a = AppDateFormat.tryParse(r.startDate);
    final b = AppDateFormat.tryParse(r.endDate) ?? a;
    if (a == null || b == null || b.isBefore(a)) return null;
    return DateTime(b.year, b.month, b.day).difference(DateTime(a.year, a.month, a.day)).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final canReview = profile.canReviewLeaveAndWfh;
    final canCancel = profile.isAdminOrManager;

    return FutureBuilder<LeaveRequestItem>(
      future: _future,
      builder: (context, snap) {
        final r = snap.data ?? widget.initial;
        if (r == null) {
          final waiting = snap.connectionState == ConnectionState.waiting;
          return AppDetailScaffold(
            title: 'Leave Request',
            loading: waiting || snap.error == null,
            error: waiting ? null : snap.error,
            errorTitle: 'Could not load request',
            onRetry: _reload,
          );
        }

        final status = r.status.toLowerCase();
        final pending = status == 'pending';
        final cancelled = status == 'cancelled' || status == 'canceled';
        final canCancelThis = canCancel && (pending || status == 'approved');
        final reviewed = (r.reviewNote ?? '').trim().isNotEmpty || r.reviewedAt != null;
        final days = _days(r);
        final previewFromRequest = r.paidDays != null || r.unpaidDays != null
            ? LeaveRequestPreview(
                days: r.days ?? ((r.paidDays ?? 0) + (r.unpaidDays ?? 0)),
                paidDays: r.paidDays ?? 0,
                unpaidDays: r.unpaidDays ?? 0,
              )
            : null;

        return AppDetailScaffold(
          title: 'Leave Request',
          busy: _acting,
          onRefresh: () async => _reload(),
          actions: [
            if (canCancelThis && pending)
              AppDetailMenu(
                items: [
                  AppDetailMenuItem(
                    label: 'Cancel leave',
                    icon: Icons.cancel_outlined,
                    destructive: true,
                    onTap: () => _cancel(r),
                  ),
                ],
              ),
          ],
          header: AppDetailHeader(
            title: r.employeeDisplayName,
            avatarText: r.employeeDisplayName,
            subtitle: r.dateRangeLabel,
            subtitleIcon: Icons.event_busy_outlined,
            caption: r.employee?.department,
            status: r.status.isEmpty ? 'pending' : r.status,
          ),
          sections: [
            AppDetailSection(
              title: 'Leave',
              icon: Icons.event_busy_outlined,
              children: [
                AppDetailRow(
                  icon: Icons.play_arrow_outlined,
                  label: 'Start date',
                  value: AppDateFormat.fromRaw(r.startDate),
                ),
                AppDetailRow(icon: Icons.stop_outlined, label: 'End date', value: AppDateFormat.fromRaw(r.endDate)),
                if (days != null)
                  AppDetailRow(
                    icon: Icons.timelapse_outlined,
                    label: 'Duration',
                    value: days == 1 ? '1 day' : '$days days',
                  ),
                if (r.leaveType != null)
                  AppDetailRow(icon: Icons.category_outlined, label: 'Type', value: appLabelize(r.leaveType!)),
                AppDetailRow(
                  icon: Icons.schedule_outlined,
                  label: 'Requested on',
                  value: AppDateFormat.dateTime(r.createdAt),
                ),
              ],
            ),
            if (canReview && (previewFromRequest != null || _preview != null || _previewing || _previewError != null))
              AppDetailSection(
                title: 'Paid vs unpaid',
                icon: Icons.account_balance_wallet_outlined,
                children: [
                  if (_previewing && _preview == null && previewFromRequest == null)
                    const AppDetailText('Checking paid and unpaid days…')
                  else if (_previewError != null && _preview == null && previewFromRequest == null)
                    const AppDetailText('Could not preview this range')
                  else ...[
                    AppDetailRow(
                      icon: Icons.check_circle_outline,
                      label: 'Paid',
                      value: '${(_preview ?? previewFromRequest)!.paidDays}',
                    ),
                    AppDetailRow(
                      icon: Icons.money_off_outlined,
                      label: 'Unpaid',
                      value: '${(_preview ?? previewFromRequest)!.unpaidDays}',
                    ),
                    AppDetailRow(
                      icon: Icons.timelapse_outlined,
                      label: 'Leave days',
                      value: '${(_preview ?? previewFromRequest)!.days}',
                    ),
                    if ((_preview ?? previewFromRequest)!.balance != null)
                      AppDetailRow(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Balance after',
                        value: '${(_preview ?? previewFromRequest)!.balance}',
                      ),
                  ],
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
            if (cancelled || (r.cancelReason ?? '').trim().isNotEmpty)
              AppDetailSection(
                title: 'Cancellation',
                icon: Icons.cancel_outlined,
                children: [
                  if (r.cancelledAt != null)
                    AppDetailRow(
                      icon: Icons.schedule_outlined,
                      label: 'Cancelled at',
                      value: AppDateFormat.dateTime(r.cancelledAt!),
                    ),
                  AppDetailRow(icon: Icons.comment_outlined, label: 'Reason', value: r.cancelReason),
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
              : !pending && canCancelThis
              ? AppDetailActionBar(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                      onPressed: _acting ? null : () => _cancel(r),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel leave'),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}
