class WorkReportPerson {
  const WorkReportPerson({
    required this.id,
    required this.name,
    this.email,
    this.department,
    this.designation,
  });

  final int id;
  final String name;
  final String? email;
  final String? department;
  final String? designation;

  factory WorkReportPerson.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const WorkReportPerson(id: 0, name: '');
    }
    return WorkReportPerson(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] as String?) ?? '',
      email: json['email'] as String?,
      department: json['department'] as String?,
      designation: json['designation'] as String?,
    );
  }
}

class DailyWorkReportProject {
  const DailyWorkReportProject({required this.id, required this.name});

  final int id;
  final String name;

  factory DailyWorkReportProject.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DailyWorkReportProject(id: 0, name: '');
    return DailyWorkReportProject(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] as String?) ?? '',
    );
  }
}

class DailyWorkReport {
  const DailyWorkReport({
    required this.id,
    required this.employeeId,
    required this.reportDate,
    required this.workDone,
    required this.projectIds,
    required this.projects,
    required this.employee,
    required this.submittedBy,
    required this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int employeeId;
  final String reportDate;
  final String workDone;
  final List<int> projectIds;
  final List<DailyWorkReportProject> projects;
  final WorkReportPerson employee;
  final WorkReportPerson submittedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory DailyWorkReport.fromJson(Map<String, dynamic> json) {
    final projectsRaw = json['projects'];
    final projects = <DailyWorkReportProject>[];
    if (projectsRaw is List) {
      for (final e in projectsRaw) {
        if (e is Map<String, dynamic>) projects.add(DailyWorkReportProject.fromJson(e));
      }
    }

    final idsRaw = json['project_ids'];
    final projectIds = <int>[];
    if (idsRaw is List) {
      for (final e in idsRaw) {
        final id = int.tryParse(e.toString());
        if (id != null) projectIds.add(id);
      }
    } else {
      projectIds.addAll(projects.map((p) => p.id));
    }

    return DailyWorkReport(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      employeeId: int.tryParse((json['employee_id'] ?? '').toString()) ?? 0,
      reportDate: (json['report_date'] as String?) ?? '',
      workDone: (json['work_done'] as String?) ?? '',
      projectIds: projectIds,
      projects: projects,
      employee: WorkReportPerson.fromJson(
        json['employee'] is Map<String, dynamic> ? json['employee'] as Map<String, dynamic> : null,
      ),
      submittedBy: WorkReportPerson.fromJson(
        json['submitted_by'] is Map<String, dynamic> ? json['submitted_by'] as Map<String, dynamic> : null,
      ),
      createdAt: _parseDt(json['created_at']),
      updatedAt: json['updated_at'] != null ? _parseDt(json['updated_at']) : null,
    );
  }

  static DateTime _parseDt(Object? raw) {
    final s = raw?.toString() ?? '';
    final parsed = DateTime.tryParse(s);
    if (parsed != null) return parsed;
    return DateTime.now();
  }

  String get plainPreview {
    return workDone
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();
  }

  /// Rough HTML → editor text for editing existing reports.
  String get editorText {
    var s = workDone;
    s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAllMapped(RegExp(r'<strong>(.*?)</strong>', caseSensitive: false, dotAll: true), (m) => '**${m[1]}**');
    s = s.replaceAllMapped(RegExp(r'<b>(.*?)</b>', caseSensitive: false, dotAll: true), (m) => '**${m[1]}**');
    s = s.replaceAllMapped(RegExp(r'<em>(.*?)</em>', caseSensitive: false, dotAll: true), (m) => '*${m[1]}*');
    s = s.replaceAllMapped(RegExp(r'<i>(.*?)</i>', caseSensitive: false, dotAll: true), (m) => '*${m[1]}*');
    s = s.replaceAllMapped(RegExp(r'<li>(.*?)</li>', caseSensitive: false, dotAll: true), (m) => '• ${m[1]}\n');
    s = s.replaceAll(RegExp(r'</?(ul|ol|p)[^>]*>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    s = s.replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>');
    return s.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }
}
