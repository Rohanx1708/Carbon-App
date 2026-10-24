/// Centralized SharedPreferences keys for the app.
abstract final class StorageKeys {
  static const authToken = 'auth_token_v1';
  static const authTokenType = 'auth_token_type_v1';
  static const authUser = 'auth_user_v1';

  static const attendanceRecords = 'attendance_records_v1';
  static const remoteAttendanceRecords = 'remote_attendance_records_v1';
  static const remoteAttendanceRecordsCacheUpdatedAt = 'remote_attendance_records_cache_updated_at_v1';
  static const geofenceTargetCache = 'geofence_target_cache_v1';

  static const leaveRequests = 'leave_requests_v1';
  static const leads = 'leads_v1';
  static const leadsCacheUpdatedAt = 'leads_cache_updated_at_v1';

  static const meetings = 'meetings_v1';
  static const meetingsCacheUpdatedAt = 'meetings_cache_updated_at_v1';

  static const employees = 'employees_v1';
  static const employeesCacheUpdatedAt = 'employees_cache_updated_at_v1';

  static const projects = 'projects_v1';
  static const projectsCacheUpdatedAt = 'projects_cache_updated_at_v1';

  static const clients = 'clients_v1';
  static const clientsCacheUpdatedAt = 'clients_cache_updated_at_v1';

  static const wfhRequests = 'wfh_requests_v1';
  static const wfhRequestsCacheUpdatedAt = 'wfh_requests_cache_updated_at_v1';

  static const leaveApprovalRequests = 'leave_approval_requests_v1';
  static const leaveApprovalRequestsCacheUpdatedAt = 'leave_approval_requests_cache_updated_at_v1';

  static const tasks = 'tasks_v1';
  static const tasksCacheUpdatedAt = 'tasks_cache_updated_at_v1';

  static const directoryLeadsCache = 'directory_leads_cache_v1';
  static const directoryClientsCache = 'directory_clients_cache_v1';
  static const directoryEmployeesCache = 'directory_employees_cache_v1';
  static const directoryCacheUpdatedAt = 'directory_cache_updated_at_v1';
}
