import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/features/attendance/data/remote_attendance_models.dart';
import 'package:attendance/features/lead/data/lead_models.dart';
import 'package:attendance/features/meeting/data/meeting_service.dart';
import 'package:attendance/features/project/data/project_models.dart';

/// Personal stats returned for non-admin users (`my_*` keys).
class DashboardMyStats {
  const DashboardMyStats({
    required this.myProjects,
    required this.assignedTasks,
    required this.pendingMyTasks,
    required this.inProgressMyTasks,
    required this.overdueMyTasks,
    required this.assignedMilestones,
    required this.myMeetings,
    this.attendanceToday,
  });

  final int myProjects;
  final int assignedTasks;
  final int pendingMyTasks;
  final int inProgressMyTasks;
  final int overdueMyTasks;
  final int assignedMilestones;
  final int myMeetings;
  final RemoteAttendanceRecord? attendanceToday;

  static bool matches(Map<String, dynamic> json) => json.containsKey('my_projects');

  factory DashboardMyStats.fromJson(Map<String, dynamic> json) {
    final todayRaw = json['my_attendance_today'];
    return DashboardMyStats(
      myProjects: DashboardStats._int(json['my_projects']),
      assignedTasks: DashboardStats._int(json['assigned_tasks']),
      pendingMyTasks: DashboardStats._int(json['pending_my_tasks']),
      inProgressMyTasks: DashboardStats._int(json['in_progress_my_tasks']),
      overdueMyTasks: DashboardStats._int(json['overdue_my_tasks']),
      assignedMilestones: DashboardStats._int(json['assigned_milestones']),
      myMeetings: DashboardStats._int(json['my_meetings']),
      attendanceToday: todayRaw is Map ? RemoteAttendanceRecord.fromJson(todayRaw.cast<String, dynamic>()) : null,
    );
  }
}

/// Upcoming meeting row from the dashboard payload.
class DashboardUpcomingMeeting {
  const DashboardUpcomingMeeting({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.meetingType,
    required this.status,
    required this.agenda,
    required this.organizerName,
  });

  final int id;
  final String title;
  final String startTime;
  final String endTime;
  final String location;
  final String meetingType;
  final String status;
  final String agenda;
  final String organizerName;

  String get typeLabel {
    switch (meetingType.toLowerCase()) {
      case 'lead':
        return 'Lead';
      case 'client':
        return 'Client';
      case 'employee':
        return 'Team';
      case 'other':
        return 'Other';
      default:
        return meetingType.isEmpty ? 'Meeting' : meetingType;
    }
  }

  String get rangeLabel {
    final start = AppDateFormat.tryParse(startTime);
    final end = AppDateFormat.tryParse(endTime);
    if (start != null && end != null) {
      final sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
      if (sameDay) {
        return '${AppDateFormat.date(start)} · ${AppDateFormat.time(start)} – ${AppDateFormat.time(end)}';
      }
      return '${AppDateFormat.dateTime(start)} – ${AppDateFormat.dateTime(end)}';
    }
    if (startTime.isNotEmpty && endTime.isNotEmpty) return '$startTime – $endTime';
    return AppDateFormat.fromRaw(startTime, withTime: true, fallback: '');
  }

  Meeting toMeeting() {
    final start = AppDateFormat.tryParse(startTime) ?? DateTime.now();
    final end = AppDateFormat.tryParse(endTime) ?? start.add(const Duration(hours: 1));
    String uiType;
    switch (meetingType.toLowerCase()) {
      case 'lead':
        uiType = 'With Lead';
      case 'client':
        uiType = 'With Client';
      case 'other':
        uiType = 'Other';
      default:
        uiType = 'With Team';
    }
    return Meeting(
      id: id,
      title: title,
      organizer: organizerName,
      organizerName: organizerName,
      type: uiType,
      startDateTime: start,
      endDateTime: end,
      location: location.isEmpty ? null : location,
      agenda: agenda,
      createdAt: start,
    );
  }

  factory DashboardUpcomingMeeting.fromJson(Map<String, dynamic> json) {
    final organizer = json['organizer'];
    final organizerName = organizer is Map ? (organizer['name']?.toString() ?? '') : '';
    return DashboardUpcomingMeeting(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      title: (json['title'] as String?) ?? '',
      startTime: (json['start_time'] ?? json['scheduled_at'] ?? json['meeting_date'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
      location: (json['location'] as String?)?.trim() ?? '',
      meetingType: (json['meeting_type'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      agenda: (json['agenda'] as String?)?.trim() ?? '',
      organizerName: organizerName.trim(),
    );
  }
}

/// Generic row for `upcoming_milestones`.
class DashboardUpcomingItem {
  const DashboardUpcomingItem({required this.id, required this.title, required this.when});

  final int id;
  final String title;
  final String when;

  static String _firstNonEmpty(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  factory DashboardUpcomingItem.fromJson(Map<String, dynamic> json) => DashboardUpcomingItem(
    id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
    title: _firstNonEmpty(json, const ['title', 'name']),
    when: _firstNonEmpty(json, const ['start_time', 'scheduled_at', 'meeting_date', 'due_date', 'date', 'end_date']),
  );
}

class DashboardStats {
  const DashboardStats({
    required this.clients,
    required this.projects,
    required this.activeProjects,
    required this.completedProjects,
    required this.pendingProjects,
    required this.employees,
    required this.activeEmployees,
    required this.leads,
    required this.newLeads,
    required this.contactedLeads,
    required this.convertedLeads,
    required this.tasks,
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.meetings,
    required this.upcomingMeetings,
    required this.todayMeetings,
    required this.completedMeetings,
    required this.milestones,
    required this.pendingMilestones,
    required this.overdueMilestones,
    required this.completedMilestones,
    required this.documents,
    required this.todayAttendance,
    required this.todayPresent,
    required this.todayAbsent,
  });

  final int clients;
  final int projects;
  final int activeProjects;
  final int completedProjects;
  final int pendingProjects;
  final int employees;
  final int activeEmployees;
  final int leads;
  final int newLeads;
  final int contactedLeads;
  final int convertedLeads;
  final int tasks;
  final int pendingTasks;
  final int inProgressTasks;
  final int completedTasks;
  final int overdueTasks;
  final int meetings;
  final int upcomingMeetings;
  final int todayMeetings;
  final int completedMeetings;
  final int milestones;
  final int pendingMilestones;
  final int overdueMilestones;
  final int completedMilestones;
  final int documents;
  final int todayAttendance;
  final int todayPresent;
  final int todayAbsent;

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    clients: _int(json['clients']),
    projects: _int(json['projects']),
    activeProjects: _int(json['active_projects']),
    completedProjects: _int(json['completed_projects']),
    pendingProjects: _int(json['pending_projects']),
    employees: _int(json['employees']),
    activeEmployees: _int(json['active_employees']),
    leads: _int(json['leads']),
    newLeads: _int(json['new_leads']),
    contactedLeads: _int(json['contacted_leads']),
    convertedLeads: _int(json['converted_leads']),
    tasks: _int(json['tasks']),
    pendingTasks: _int(json['pending_tasks']),
    inProgressTasks: _int(json['in_progress_tasks']),
    completedTasks: _int(json['completed_tasks']),
    overdueTasks: _int(json['overdue_tasks']),
    meetings: _int(json['meetings']),
    upcomingMeetings: _int(json['upcoming_meetings']),
    todayMeetings: _int(json['today_meetings']),
    completedMeetings: _int(json['completed_meetings']),
    milestones: _int(json['milestones']),
    pendingMilestones: _int(json['pending_milestones']),
    overdueMilestones: _int(json['overdue_milestones']),
    completedMilestones: _int(json['completed_milestones']),
    documents: _int(json['documents']),
    todayAttendance: _int(json['today_attendance']),
    todayPresent: _int(json['today_present']),
    todayAbsent: _int(json['today_absent']),
  );

  static int _int(Object? v) => int.tryParse((v ?? '').toString()) ?? 0;
}

class DashboardData {
  const DashboardData({
    required this.stats,
    this.myStats,
    required this.recentProjects,
    required this.recentLeads,
    this.upcomingMeetings = const [],
    this.upcomingMilestones = const [],
  });

  final DashboardStats stats;
  final DashboardMyStats? myStats;
  final List<Project> recentProjects;
  final List<Lead> recentLeads;
  final List<DashboardUpcomingMeeting> upcomingMeetings;
  final List<DashboardUpcomingItem> upcomingMilestones;

  static List<Map<String, dynamic>> _maps(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) item else if (item is Map) item.cast<String, dynamic>(),
    ];
  }

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final projects = [for (final m in _maps(json['recent_projects'])) Project.fromApiMap(m)];
    final leads = [for (final m in _maps(json['recent_leads'])) Lead.fromApiMap(m)];
    final meetings = [for (final m in _maps(json['upcoming_meetings'])) DashboardUpcomingMeeting.fromJson(m)];
    final milestones = [for (final m in _maps(json['upcoming_milestones'])) DashboardUpcomingItem.fromJson(m)];
    final statsRaw = json['stats'];
    return DashboardData(
      stats: statsRaw is Map<String, dynamic>
          ? DashboardStats.fromJson(statsRaw)
          : statsRaw is Map
          ? DashboardStats.fromJson(statsRaw.cast<String, dynamic>())
          : const DashboardStats(
              clients: 0,
              projects: 0,
              activeProjects: 0,
              completedProjects: 0,
              pendingProjects: 0,
              employees: 0,
              activeEmployees: 0,
              leads: 0,
              newLeads: 0,
              contactedLeads: 0,
              convertedLeads: 0,
              tasks: 0,
              pendingTasks: 0,
              inProgressTasks: 0,
              completedTasks: 0,
              overdueTasks: 0,
              meetings: 0,
              upcomingMeetings: 0,
              todayMeetings: 0,
              completedMeetings: 0,
              milestones: 0,
              pendingMilestones: 0,
              overdueMilestones: 0,
              completedMilestones: 0,
              documents: 0,
              todayAttendance: 0,
              todayPresent: 0,
              todayAbsent: 0,
            ),
      myStats:
          statsRaw is Map &&
              DashboardMyStats.matches(statsRaw is Map<String, dynamic> ? statsRaw : statsRaw.cast<String, dynamic>())
          ? DashboardMyStats.fromJson(statsRaw is Map<String, dynamic> ? statsRaw : statsRaw.cast<String, dynamic>())
          : null,
      recentProjects: projects,
      recentLeads: leads,
      upcomingMeetings: meetings,
      upcomingMilestones: milestones,
    );
  }
}
