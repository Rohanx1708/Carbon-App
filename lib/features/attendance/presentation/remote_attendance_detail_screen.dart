import 'package:flutter/material.dart';

import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/core/widgets/app_detail.dart';
import 'package:attendance/features/attendance/data/remote_attendance_service.dart';

class RemoteAttendanceDetailScreen extends StatefulWidget {
  const RemoteAttendanceDetailScreen({super.key, required this.attendanceId, this.initial});

  final int attendanceId;
  final RemoteAttendanceRecord? initial;

  @override
  State<RemoteAttendanceDetailScreen> createState() => _RemoteAttendanceDetailScreenState();
}

class _RemoteAttendanceDetailScreenState extends State<RemoteAttendanceDetailScreen> {
  final RemoteAttendanceService _service = RemoteAttendanceService();
  Future<RemoteAttendanceRecord>? _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchDetail(widget.attendanceId);
  }

  void _reload() {
    setState(() {
      _future = _service.fetchDetail(widget.attendanceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RemoteAttendanceRecord>(
      future: _future,
      builder: (context, snap) {
        final r = snap.data ?? widget.initial;
        if (r == null) {
          final waiting = snap.connectionState == ConnectionState.waiting;
          return AppDetailScaffold(
            title: 'Attendance',
            loading: waiting || snap.error == null,
            error: waiting ? null : snap.error,
            errorTitle: 'Could not load attendance',
            onRetry: _reload,
          );
        }

        final leaveReason = (r.leaveReason ?? '').trim();
        final notes = (r.notes ?? '').trim();

        return AppDetailScaffold(
          title: 'Attendance',
          onRefresh: () async => _reload(),
          header: AppDetailHeader(
            title: r.employeeDisplayName,
            avatarText: r.employeeDisplayName,
            subtitle: AppDateFormat.fromRaw(r.attendanceDate),
            subtitleIcon: Icons.event_outlined,
            caption: r.employee?.department,
            status: r.status,
            badges: [if (r.isLate) const AppDetailHeaderBadge('Late', icon: Icons.schedule)],
          ),
          sections: [
            AppDetailSection(
              title: 'Attendance',
              icon: Icons.access_time,
              children: [
                AppDetailRow(icon: Icons.event_outlined, label: 'Date', value: AppDateFormat.fromRaw(r.attendanceDate)),
                AppDetailRow(icon: Icons.login, label: 'Check in', value: r.checkIn),
                AppDetailRow(icon: Icons.logout, label: 'Check out', value: r.checkOut),
                AppDetailRow(icon: Icons.flag_outlined, label: 'Status', value: appLabelize(r.status)),
                if (r.markedBy != null && r.markedBy!.name.isNotEmpty)
                  AppDetailRow(icon: Icons.how_to_reg_outlined, label: 'Marked by', value: r.markedBy!.name),
                AppDetailRow(icon: Icons.update, label: 'Updated', value: AppDateFormat.dateTime(r.updatedAt)),
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
            if (leaveReason.isNotEmpty || notes.isNotEmpty)
              AppDetailSection(
                title: 'Notes',
                icon: Icons.notes_outlined,
                children: [
                  if (leaveReason.isNotEmpty) AppDetailRow(label: 'Leave reason', value: leaveReason),
                  if (notes.isNotEmpty) AppDetailRow(label: 'Notes', value: notes),
                ],
              ),
          ],
        );
      },
    );
  }
}
