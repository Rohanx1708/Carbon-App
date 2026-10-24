import 'package:intl/intl.dart';

import 'package:attendance/features/lead/data/lead_models.dart';

class TaskProjectRef {
  const TaskProjectRef({required this.id, required this.name});

  final int id;
  final String name;

  factory TaskProjectRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TaskProjectRef(id: 0, name: '');
    return TaskProjectRef(id: int.tryParse((json['id'] ?? '').toString()) ?? 0, name: (json['name'] as String?) ?? '');
  }
}

class TaskPerson {
  const TaskPerson({required this.id, required this.name, this.email});

  final int id;
  final String name;
  final String? email;

  factory TaskPerson.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TaskPerson(id: 0, name: '');
    return TaskPerson(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] as String?) ?? '',
      email: json['email'] as String?,
    );
  }
}

class TaskComment {
  const TaskComment({required this.id, required this.comment, this.userName, required this.createdAt});

  final int id;
  final String comment;
  final String? userName;
  final DateTime createdAt;

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    String? name;
    if (user is Map) {
      name = user['name'] as String?;
    }
    return TaskComment(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      comment: (json['comment'] as String?) ?? '',
      userName: name,
      createdAt: TaskItem.parseApiDateTime((json['created_at'] as String?) ?? ''),
    );
  }
}

class TaskItem {
  TaskItem({
    required this.id,
    required this.projectId,
    this.parentTaskId,
    required this.taskCode,
    required this.series,
    required this.title,
    required this.description,
    required this.taskType,
    required this.assignedTo,
    this.approverId,
    required this.status,
    required this.priority,
    required this.dueDate,
    this.completedAt,
    required this.project,
    this.assignee,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int projectId;
  final int? parentTaskId;
  final String taskCode;
  final int series;
  final String title;
  final String description;
  final String taskType;
  final int assignedTo;
  final int? approverId;
  final String status;
  final String priority;
  final String dueDate;
  final DateTime? completedAt;
  final TaskProjectRef project;
  final TaskPerson? assignee;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get assigneeName => assignee?.name.trim().isNotEmpty == true ? assignee!.name : 'Employee #$assignedTo';

  static DateTime parseApiDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw, true).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final completedRaw = json['completed_at'] as String?;
    return TaskItem(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      projectId: int.tryParse((json['project_id'] ?? '').toString()) ?? 0,
      parentTaskId: int.tryParse((json['parent_task_id'] ?? '').toString()),
      taskCode: (json['task_code'] as String?) ?? '',
      series: int.tryParse((json['series'] ?? '').toString()) ?? 0,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      taskType: (json['task_type'] as String?) ?? 'task',
      assignedTo: int.tryParse((json['assigned_to'] ?? '').toString()) ?? 0,
      approverId: int.tryParse((json['approver_id'] ?? '').toString()),
      status: (json['status'] as String?) ?? 'todo',
      priority: (json['priority'] as String?) ?? 'medium',
      dueDate: (json['due_date'] as String?) ?? '',
      completedAt: completedRaw != null && completedRaw.isNotEmpty ? parseApiDateTime(completedRaw) : null,
      project: TaskProjectRef.fromJson(json['project'] as Map<String, dynamic>?),
      assignee: json['assignee'] is Map<String, dynamic>
          ? TaskPerson.fromJson(json['assignee'] as Map<String, dynamic>)
          : null,
      createdBy: int.tryParse((json['created_by'] ?? '').toString()) ?? 0,
      createdAt: parseApiDateTime((json['created_at'] as String?) ?? ''),
      updatedAt: parseApiDateTime((json['updated_at'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'parent_task_id': parentTaskId,
    'task_code': taskCode,
    'series': series,
    'title': title,
    'description': description,
    'task_type': taskType,
    'assigned_to': assignedTo,
    'approver_id': approverId,
    'status': status,
    'priority': priority,
    'due_date': dueDate,
    'completed_at': completedAt?.toIso8601String(),
    'project': {'id': project.id, 'name': project.name},
    'assignee': assignee == null ? null : {'id': assignee!.id, 'name': assignee!.name, 'email': assignee!.email},
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class TaskDetail extends TaskItem {
  TaskDetail({
    required super.id,
    required super.projectId,
    super.parentTaskId,
    required super.taskCode,
    required super.series,
    required super.title,
    required super.description,
    required super.taskType,
    required super.assignedTo,
    super.approverId,
    required super.status,
    required super.priority,
    required super.dueDate,
    super.completedAt,
    required super.project,
    super.assignee,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    this.approver,
    this.documents = const [],
    this.comments = const [],
  });

  final TaskPerson? approver;
  final List<LeadDocument> documents;
  final List<TaskComment> comments;

  factory TaskDetail.fromJson(Map<String, dynamic> json) {
    final base = TaskItem.fromJson(json);
    final docs = <LeadDocument>[];
    final rawDocs = json['documents'];
    if (rawDocs is List) {
      for (final d in rawDocs) {
        if (d is Map<String, dynamic>) docs.add(LeadDocument.fromJson(d));
      }
    }
    final comments = <TaskComment>[];
    final rawComments = json['comments'];
    if (rawComments is List) {
      for (final c in rawComments) {
        if (c is Map<String, dynamic>) comments.add(TaskComment.fromJson(c));
      }
    }
    return TaskDetail(
      id: base.id,
      projectId: base.projectId,
      parentTaskId: base.parentTaskId,
      taskCode: base.taskCode,
      series: base.series,
      title: base.title,
      description: base.description,
      taskType: base.taskType,
      assignedTo: base.assignedTo,
      approverId: base.approverId,
      status: base.status,
      priority: base.priority,
      dueDate: base.dueDate,
      completedAt: base.completedAt,
      project: base.project,
      assignee: base.assignee,
      createdBy: base.createdBy,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      approver: json['approver'] is Map<String, dynamic>
          ? TaskPerson.fromJson(json['approver'] as Map<String, dynamic>)
          : null,
      documents: docs,
      comments: comments,
    );
  }
}

class TaskCreateInput {
  const TaskCreateInput({
    required this.projectId,
    required this.title,
    required this.description,
    required this.taskType,
    required this.assignedTo,
    required this.status,
    required this.priority,
    required this.dueDate,
    this.approverId,
    this.parentTaskId,
  });

  final int projectId;
  final String title;
  final String description;
  final String taskType;
  final int assignedTo;
  final String status;
  final String priority;
  final String dueDate;
  final int? approverId;
  final int? parentTaskId;

  Map<String, dynamic> toJson() => {
    'project_id': projectId,
    'title': title,
    'description': description,
    'task_type': taskType,
    'assigned_to': assignedTo,
    'status': status,
    'priority': priority,
    'due_date': dueDate,
    if (approverId != null) 'approver_id': approverId,
    if (parentTaskId != null) 'parent_task_id': parentTaskId,
  };
}
