import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/app/main_nav_screen.dart';
import 'package:attendance/features/holiday/data/holiday_service.dart';
import 'package:attendance/features/settings/data/office_settings_service.dart';
import 'package:attendance/services/directory_cache_service.dart';
import 'package:attendance/services/local_storage_service.dart';
import 'package:attendance/services/storage_keys.dart';
import 'package:attendance/state/attendance_provider.dart';
import 'package:attendance/state/client_provider.dart';
import 'package:attendance/state/dashboard_provider.dart';
import 'package:attendance/state/document_provider.dart';
import 'package:attendance/state/employee_provider.dart';
import 'package:attendance/state/lead_provider.dart';
import 'package:attendance/state/leave_provider.dart';
import 'package:attendance/state/leave_request_provider.dart';
import 'package:attendance/state/main_nav_provider.dart';
import 'package:attendance/state/meeting_provider.dart';
import 'package:attendance/state/notification_provider.dart';
import 'package:attendance/state/project_provider.dart';
import 'package:attendance/state/remote_attendance_provider.dart';
import 'package:attendance/state/task_provider.dart';
import 'package:attendance/state/wfh_provider.dart';

/// Clears disk + in-memory caches and resets list providers after logout.
abstract final class AppSession {
  static const _cacheKeys = <String>[
    StorageKeys.attendanceRecords,
    StorageKeys.remoteAttendanceRecords,
    StorageKeys.remoteAttendanceRecordsCacheUpdatedAt,
    StorageKeys.geofenceTargetCache,
    StorageKeys.leaveRequests,
    StorageKeys.leads,
    StorageKeys.leadsCacheUpdatedAt,
    StorageKeys.meetings,
    StorageKeys.meetingsCacheUpdatedAt,
    StorageKeys.employees,
    StorageKeys.employeesCacheUpdatedAt,
    StorageKeys.projects,
    StorageKeys.projectsCacheUpdatedAt,
    StorageKeys.clients,
    StorageKeys.clientsCacheUpdatedAt,
    StorageKeys.wfhRequests,
    StorageKeys.wfhRequestsCacheUpdatedAt,
    StorageKeys.leaveApprovalRequests,
    StorageKeys.leaveApprovalRequestsCacheUpdatedAt,
    StorageKeys.tasks,
    StorageKeys.tasksCacheUpdatedAt,
    StorageKeys.directoryLeadsCache,
    StorageKeys.directoryClientsCache,
    StorageKeys.directoryEmployeesCache,
    StorageKeys.directoryCacheUpdatedAt,
  ];

  static Future<void> clearPersistedCaches() async {
    final storage = LocalStorageService.instance;
    for (final key in _cacheKeys) {
      await storage.remove(key);
    }
  }

  static void clearMemoryCaches() {
    DirectoryCacheService.instance.invalidate();
    HolidayService.invalidateCache();
    OfficeSettingsService.cached = null;
    OfficeSettingsService.cachedAt = null;
  }

  static void resetProviders(BuildContext context) {
    context.read<MainNavProvider>().setIndex(MainNavPages.home);
    context.read<DashboardProvider>().reset();
    context.read<ClientProvider>().clearSession();
    context.read<ProjectProvider>().clearSession();
    context.read<TaskProvider>().clearSession();
    context.read<LeadProvider>().clearSession();
    context.read<EmployeeProvider>().clearSession();
    context.read<MeetingProvider>().clearSession();
    context.read<WfhProvider>().clearSession();
    context.read<LeaveRequestProvider>().clearSession();
    context.read<RemoteAttendanceProvider>().clearSession();
    context.read<DocumentProvider>().clearSession();
    context.read<NotificationProvider>().clearSession();
    context.read<LeaveProvider>().clearSession();
    context.read<AttendanceProvider>().clearSession();
  }

  static Future<void> clearAll(BuildContext context) async {
    await clearPersistedCaches();
    clearMemoryCaches();
    if (context.mounted) resetProviders(context);
  }
}
