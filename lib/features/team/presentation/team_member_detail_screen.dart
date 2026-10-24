import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/widgets/app_detail.dart';
import 'package:attendance/core/widgets/app_list_tile.dart';
import 'package:attendance/features/attendance_report/data/attendance_report_service.dart';
import 'package:attendance/features/attendance_report/presentation/report_widgets.dart';
import 'package:attendance/features/team/data/team_models.dart';
import 'package:attendance/features/team/data/team_service.dart';

class _MemberDetailBundle {
  const _MemberDetailBundle({this.balance, required this.logs});

  final TeamLeaveBalance? balance;
  final TeamLeaveBalanceDetail logs;
}

class TeamMemberDetailScreen extends StatefulWidget {
  const TeamMemberDetailScreen({super.key, required this.member, this.balance});

  final TeamMember member;
  final TeamLeaveBalance? balance;

  @override
  State<TeamMemberDetailScreen> createState() => _TeamMemberDetailScreenState();
}

class _TeamMemberDetailScreenState extends State<TeamMemberDetailScreen>
    with ReportLoader<TeamMemberDetailScreen, _MemberDetailBundle> {
  final _service = TeamService();

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  Future<_MemberDetailBundle> fetch() async {
    TeamLeaveBalanceDetail logs;
    try {
      logs = await _service.fetchLeaveBalanceLogs(widget.member.id);
    } catch (_) {
      logs = TeamLeaveBalanceDetail(employeeId: widget.member.id, balance: widget.member.leaveBalance, logs: const []);
    }

    var balance = widget.balance;
    if (balance == null) {
      try {
        final all = await _service.fetchLeaveBalances();
        for (final b in all) {
          if (b.employee.id == widget.member.id) {
            balance = b;
            break;
          }
        }
      } catch (_) {}
    }

    return _MemberDetailBundle(balance: balance, logs: logs);
  }

  AppStatusTone _tone(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AppStatusTone.success;
      case 'leave':
      case 'on_leave':
        return AppStatusTone.warning;
      case 'absent':
        return AppStatusTone.error;
      case 'wfh':
      case 'holiday':
        return AppStatusTone.info;
      default:
        return AppStatusTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final b = data?.balance ?? widget.balance;
    final logs = data?.logs;
    final today = m.today;
    final style = AttendanceStatusStyle.of(today.status);
    final balanceValue = logs?.balance ?? b?.balance ?? m.leaveBalance;

    return AppDetailScaffold(
      title: m.name,
      loading: loading && data == null,
      error: error,
      errorTitle: 'Could not load this person',
      onRetry: reload,
      onRefresh: reload,
      header: AppDetailHeader(
        title: m.name,
        avatarText: m.name,
        subtitle: [m.designation, m.department].where((s) => s.isNotEmpty).join(' · '),
        caption: m.email.isEmpty ? null : m.email,
        status: m.todayKnown ? style.label : null,
        statusTone: m.todayKnown ? _tone(today.status) : null,
        stats: [
          AppDetailStat(icon: Icons.account_balance_wallet_outlined, label: 'Balance', value: '$balanceValue'),
          if (b != null)
            AppDetailStat(icon: Icons.hourglass_empty_outlined, label: 'Pending', value: '${b.pendingDays}'),
        ],
      ),
      sections: [
        if (m.todayKnown)
          AppDetailSection(
            title: 'Today',
            icon: Icons.today_outlined,
            children: [
              AppDetailRow(icon: Icons.flag_outlined, label: 'Status', value: style.label),
              AppDetailRow(
                icon: Icons.login_outlined,
                label: 'Check in',
                value: today.checkIn == null ? '—' : formatReportTime(today.checkIn),
              ),
              AppDetailRow(
                icon: Icons.logout_outlined,
                label: 'Check out',
                value: today.checkOut == null ? '—' : formatReportTime(today.checkOut),
              ),
              if (today.isLate) const AppDetailRow(icon: Icons.schedule_outlined, label: 'Late', value: 'Yes'),
            ],
          ),
        AppDetailSection(
          title: 'Contact',
          icon: Icons.contact_mail_outlined,
          children: [
            AppDetailRow(icon: Icons.email_outlined, label: 'Email', value: m.email),
            AppDetailRow(icon: Icons.phone_outlined, label: 'Phone', value: m.phone),
            AppDetailRow(icon: Icons.apartment_outlined, label: 'Department', value: m.department),
            AppDetailRow(icon: Icons.badge_outlined, label: 'Designation', value: m.designation),
          ],
        ),
        AppDetailSection(
          title: 'Leave balance',
          icon: Icons.beach_access_outlined,
          children: [
            AppDetailRow(icon: Icons.savings_outlined, label: 'Remaining', value: '$balanceValue'),
            if (b != null) ...[
              AppDetailRow(icon: Icons.add_circle_outline, label: 'Credited this year', value: '${b.creditedThisYear}'),
              AppDetailRow(icon: Icons.check_circle_outline, label: 'Paid used', value: '${b.paidUsed}'),
              AppDetailRow(icon: Icons.remove_circle_outline, label: 'Unpaid used', value: '${b.unpaidUsed}'),
              AppDetailRow(icon: Icons.pending_outlined, label: 'Pending days', value: '${b.pendingDays}'),
            ],
          ],
        ),
        AppDetailSection(
          title: 'Balance log',
          icon: Icons.history_outlined,
          count: logs?.logs.length,
          children: [
            if (logs == null)
              const AppDetailText('Loading log…')
            else if (logs.logs.isEmpty)
              const AppDetailText('No leave credits or deductions yet')
            else
              for (final log in logs.logs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppListTile(
                    leading: AppListTileLeading.icon(
                      (log.days ?? 0) < 0 ? Icons.remove : Icons.add,
                      accent: (log.days ?? 0) < 0 ? AppColors.error : AppColors.success,
                    ),
                    title: appLabelize(log.type ?? 'Balance update'),
                    subtitleLines: [
                      if (log.days != null) '${log.days} day${log.days == 1 ? '' : 's'}',
                      if (log.note != null) log.note!,
                      if (log.actor != null) 'By ${log.actor}',
                      if (log.createdAt != null) AppDateFormat.fromRaw(log.createdAt, withTime: true),
                    ],
                    showChevron: false,
                  ),
                ),
          ],
        ),
      ],
    );
  }
}
