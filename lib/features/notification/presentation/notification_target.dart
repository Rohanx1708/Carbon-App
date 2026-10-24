import 'package:flutter/material.dart';

import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/features/attendance/presentation/remote_attendance_detail_screen.dart';
import 'package:attendance/features/document/presentation/document_detail_screen.dart';
import 'package:attendance/features/employee/presentation/employee_details_screen.dart';
import 'package:attendance/features/holiday/presentation/holiday_detail_screen.dart';
import 'package:attendance/features/leave_balance/presentation/leave_balance_screen.dart';
import 'package:attendance/features/leave_request/presentation/leave_request_detail_screen.dart';
import 'package:attendance/features/leave_request/presentation/leave_request_screen.dart';
import 'package:attendance/features/meeting/data/meeting_service.dart';
import 'package:attendance/features/meeting/presentation/meeting_detail_screen.dart';
import 'package:attendance/features/meeting/presentation/meeting_screen.dart';
import 'package:attendance/features/notification/data/notification_models.dart';
import 'package:attendance/features/task/presentation/task_detail_screen.dart';
import 'package:attendance/features/wfh/presentation/wfh_detail_screen.dart';
import 'package:attendance/features/wfh/presentation/wfh_screen.dart';

class NotificationKind {
  const NotificationKind({required this.icon, required this.color, required this.label});

  final IconData icon;
  final Color color;
  final String label;
}

NotificationKind notificationKind(AppNotification n) {
  final t = n.type.toLowerCase();
  final title = n.title.toLowerCase();
  if (t.contains('wfh') || title.contains('wfh')) {
    return const NotificationKind(icon: Icons.home_work_outlined, color: Color(0xFF7C3AED), label: 'WFH');
  }
  if (t.contains('leave') || title.contains('leave')) {
    return const NotificationKind(icon: Icons.event_busy_outlined, color: AppColors.warning, label: 'Leave');
  }
  if (t.contains('meeting') || title.contains('meeting')) {
    return const NotificationKind(icon: Icons.groups_outlined, color: AppColors.primary, label: 'Meeting');
  }
  if (t.contains('task') || title.contains('task')) {
    return const NotificationKind(icon: Icons.task_alt_outlined, color: AppColors.info, label: 'Task');
  }
  if (t.contains('document') || title.contains('document')) {
    return const NotificationKind(icon: Icons.folder_open_outlined, color: Color(0xFFEA580C), label: 'Document');
  }
  if (t.contains('holiday') || title.contains('holiday')) {
    return const NotificationKind(icon: Icons.celebration_outlined, color: Color(0xFFEA580C), label: 'Holiday');
  }
  if (t.contains('attendance') || title.contains('attendance') || title.contains('punch')) {
    return const NotificationKind(icon: Icons.access_time_outlined, color: AppColors.success, label: 'Attendance');
  }
  if (t.contains('employee') || title.contains('employee')) {
    return const NotificationKind(icon: Icons.badge_outlined, color: AppColors.primary, label: 'Employee');
  }
  if (t.contains('balance') || title.contains('balance') || title.contains('leave pool')) {
    return const NotificationKind(icon: Icons.savings_outlined, color: Color(0xFF0F766E), label: 'Leave');
  }
  return const NotificationKind(icon: Icons.notifications_outlined, color: AppColors.primary, label: 'Notice');
}

String notificationTimeLabel(DateTime at) {
  final now = DateTime.now();
  final local = at.toLocal();
  final diff = now.difference(local);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24 && now.day == local.day) return AppDateFormat.time(local);
  final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
  if (local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day) {
    return 'Yesterday · ${AppDateFormat.time(local)}';
  }
  return AppDateFormat.dateTime(local);
}

String notificationGroupLabel(DateTime at) {
  final now = DateTime.now();
  final local = at.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  if (day == today) return 'Today';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return 'Earlier';
}

Widget? notificationTarget(AppNotification n) {
  final t = n.type.toLowerCase().trim();
  final title = n.title.toLowerCase();

  // Prefer exact / specific types before broad "leave" / "id" matches.
  if (t == 'wfh_request' || t.contains('wfh') || title.contains('wfh')) {
    final id = n.dataInt(const ['wfh_request_id', 'wfh_id', 'request_id']);
    if (id != null) return WfhDetailScreen(requestId: id);
    return const WfhScreen();
  }
  if (t.contains('leave_balance') || t.contains('leave-balance') || title.contains('leave balance')) {
    return const LeaveBalanceScreen();
  }
  if (t == 'leave_request' || t.contains('leave') || title.contains('leave')) {
    final id = n.dataInt(const ['leave_request_id', 'leave_id', 'request_id']);
    if (id != null) return LeaveRequestDetailScreen(requestId: id);
    return const LeaveRequestScreen();
  }
  if (t.contains('task') || title.contains('task')) {
    final id = n.dataInt(const ['task_id', 'id']);
    if (id != null) return TaskDetailScreen(taskId: id);
  }
  if (t.contains('meeting') || title.contains('meeting')) {
    final meetingId = n.dataInt(const ['meeting_id', 'id']);
    if (meetingId != null) {
      final now = DateTime.now();
      return MeetingDetailScreen(
        meeting: Meeting(
          id: meetingId,
          title: n.title,
          organizer: '',
          type: 'Other',
          startDateTime: now,
          endDateTime: now.add(const Duration(hours: 1)),
          agenda: '',
          createdAt: n.createdAt,
        ),
      );
    }
    return const MeetingScreen();
  }
  if (t.contains('document') || title.contains('document')) {
    final id = n.dataInt(const ['document_id', 'id']);
    if (id != null) return DocumentDetailScreen(documentId: id);
  }
  if (t.contains('holiday') || title.contains('holiday')) {
    final id = n.dataInt(const ['holiday_id', 'id']);
    if (id != null) return HolidayDetailScreen(holidayId: id);
  }
  if (t.contains('attendance') || title.contains('attendance') || title.contains('punch')) {
    final id = n.dataInt(const ['attendance_id', 'id']);
    if (id != null) return RemoteAttendanceDetailScreen(attendanceId: id);
  }
  if (t.contains('employee') || title.contains('employee')) {
    final id = n.dataInt(const ['employee_id', 'id']);
    if (id != null) return EmployeeDetailsScreen(employeeId: id);
  }
  if (t.contains('balance')) return const LeaveBalanceScreen();
  return null;
}
