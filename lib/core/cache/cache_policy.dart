/// Shared TTL defaults for in-memory and on-disk caches.
abstract final class CachePolicy {
  /// Meeting form directory picklists.
  static const Duration directoryTtl = Duration(minutes: 10);

  /// CRM / ops entity lists (clients, projects, tasks, leads, employees, meetings, WFH, leave requests).
  static const Duration listTtl = Duration(minutes: 30);

  /// Soft ceiling for disk retention before treating cache as expired even if still shown offline.
  static const Duration listDiskFreshness = Duration(hours: 24);

  /// Dashboard snapshot.
  static const Duration dashboardTtl = Duration(minutes: 2);

  /// Notifications inbox.
  static const Duration notificationsTtl = Duration(minutes: 2);

  /// Office hours / geofence / week-off settings.
  static const Duration settingsTtl = Duration(minutes: 15);

  /// Holiday calendar.
  static const Duration holidaysTtl = Duration(hours: 12);

  /// Leave balance / leave pool.
  static const Duration leaveBalanceTtl = Duration(minutes: 10);

  /// Team hub, today attendance, live leave status.
  static const Duration teamTtl = Duration(minutes: 3);

  /// Attendance reports keyed by day/month.
  static const Duration reportTtl = Duration(minutes: 5);

  /// Documents library.
  static const Duration documentsTtl = Duration(minutes: 15);

  /// Profile / session-adjacent remote profile.
  static const Duration profileTtl = Duration(minutes: 15);
}
