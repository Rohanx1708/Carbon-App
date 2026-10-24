import 'package:intl/intl.dart';

class ProjectClientRef {
  const ProjectClientRef({required this.id, required this.clientName, required this.companyName});

  final int id;
  final String clientName;
  final String companyName;

  factory ProjectClientRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProjectClientRef(id: 0, clientName: '', companyName: '');
    return ProjectClientRef(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      clientName: (json['client_name'] as String?) ?? '',
      companyName: (json['company_name'] as String?) ?? '',
    );
  }

  String get displayName {
    if (companyName.trim().isNotEmpty) return companyName.trim();
    return clientName.trim();
  }
}

class ProjectUserRef {
  const ProjectUserRef({required this.id, required this.name, required this.email});

  final int id;
  final String name;
  final String email;

  factory ProjectUserRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProjectUserRef(id: 0, name: '', email: '');
    return ProjectUserRef(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
    );
  }
}

class ProjectTeamMember {
  const ProjectTeamMember({
    required this.id,
    required this.employeeId,
    required this.role,
    required this.isActive,
    this.employeeName,
    this.employeeEmail,
    this.designation,
  });

  final int id;
  final int employeeId;
  final String role;
  final bool isActive;
  final String? employeeName;
  final String? employeeEmail;
  final String? designation;

  factory ProjectTeamMember.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'];
    Map<String, dynamic>? empMap;
    if (emp is Map<String, dynamic>) empMap = emp;
    return ProjectTeamMember(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      employeeId: int.tryParse((json['employee_id'] ?? '').toString()) ?? 0,
      role: (json['role'] as String?) ?? '',
      isActive: json['is_active'] as bool? ?? true,
      employeeName: empMap?['name'] as String?,
      employeeEmail: empMap?['email'] as String?,
      designation: empMap?['designation'] as String?,
    );
  }
}

class ProjectMilestone {
  const ProjectMilestone({required this.id, required this.name, this.dueDate, this.amount, this.order});

  final int id;
  final String name;
  final String? dueDate;
  final String? amount;
  final int? order;

  factory ProjectMilestone.fromJson(Map<String, dynamic> json) => ProjectMilestone(
    id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
    name: (json['name'] as String?) ?? '',
    dueDate: json['due_date'] as String?,
    amount: json['amount']?.toString(),
    order: int.tryParse((json['order'] ?? '').toString()),
  );
}

class ProjectDocument {
  const ProjectDocument({
    required this.id,
    required this.title,
    this.fileName,
    this.fileUrl,
    this.mimeType,
    this.fileSize,
    this.documentTypeName,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String? fileName;
  final String? fileUrl;
  final String? mimeType;
  final int? fileSize;
  final String? documentTypeName;
  final DateTime createdAt;

  factory ProjectDocument.fromJson(Map<String, dynamic> json) {
    final docType = json['document_type'];
    String? typeName;
    if (docType is Map<String, dynamic>) {
      typeName = docType['name'] as String?;
    }
    return ProjectDocument(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      title: (json['title'] as String?) ?? 'Attachment',
      fileName: json['file_name'] as String?,
      fileUrl: json['file_url'] as String? ?? json['file_path'] as String?,
      mimeType: json['mime_type'] as String?,
      fileSize: int.tryParse((json['file_size'] ?? '').toString()),
      documentTypeName: typeName,
      createdAt: Project.parseApiDateTime((json['created_at'] as String?) ?? ''),
    );
  }
}

class Project {
  Project({
    required this.id,
    required this.name,
    required this.clientId,
    required this.projectType,
    required this.projectTypeLabel,
    this.startDate,
    this.estimatedEndDate,
    required this.status,
    required this.priority,
    required this.description,
    required this.techStack,
    required this.paymentFrequency,
    this.budget,
    required this.client,
    required this.projectManager,
    required this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final int clientId;
  final String projectType;
  final String projectTypeLabel;
  final String? startDate;
  final String? estimatedEndDate;
  final String status;
  final String priority;
  final String description;
  final List<String> techStack;
  final String paymentFrequency;
  final String? budget;
  final ProjectClientRef client;
  final ProjectUserRef projectManager;
  final DateTime createdAt;
  final DateTime? updatedAt;

  static DateTime parseApiDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw, true).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  factory Project.fromApiMap(Map<String, dynamic> json) {
    final stackRaw = json['tech_stack'];
    final stack = <String>[];
    if (stackRaw is List) {
      for (final item in stackRaw) {
        if (item != null) stack.add(item.toString());
      }
    }
    return Project(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] as String?) ?? '',
      clientId: int.tryParse((json['client_id'] ?? '').toString()) ?? 0,
      projectType: (json['project_type'] as String?) ?? '',
      projectTypeLabel: (json['project_type_label'] as String?) ?? '',
      startDate: json['start_date'] as String?,
      estimatedEndDate: json['estimated_end_date'] as String?,
      status: (json['status'] as String?) ?? '',
      priority: (json['priority'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      techStack: stack,
      paymentFrequency: (json['payment_frequency'] as String?) ?? '',
      budget: json['budget']?.toString(),
      client: ProjectClientRef.fromJson(
        json['client'] is Map<String, dynamic> ? json['client'] as Map<String, dynamic> : null,
      ),
      projectManager: ProjectUserRef.fromJson(
        json['project_manager'] is Map<String, dynamic> ? json['project_manager'] as Map<String, dynamic> : null,
      ),
      createdAt: parseApiDateTime((json['created_at'] as String?) ?? ''),
      updatedAt: json['updated_at'] != null ? parseApiDateTime(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'clientId': clientId,
    'projectType': projectType,
    'projectTypeLabel': projectTypeLabel,
    'startDate': startDate,
    'estimatedEndDate': estimatedEndDate,
    'status': status,
    'priority': priority,
    'description': description,
    'techStack': techStack,
    'paymentFrequency': paymentFrequency,
    'budget': budget,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Project.fromJson(Map<String, dynamic> json) {
    final stackRaw = json['techStack'];
    final stack = <String>[];
    if (stackRaw is List) {
      for (final item in stackRaw) {
        if (item != null) stack.add(item.toString());
      }
    }
    return Project(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] as String?) ?? '',
      clientId: int.tryParse((json['clientId'] ?? '').toString()) ?? 0,
      projectType: (json['projectType'] as String?) ?? '',
      projectTypeLabel: (json['projectTypeLabel'] as String?) ?? '',
      startDate: json['startDate'] as String?,
      estimatedEndDate: json['estimatedEndDate'] as String?,
      status: (json['status'] as String?) ?? '',
      priority: (json['priority'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      techStack: stack,
      paymentFrequency: (json['paymentFrequency'] as String?) ?? '',
      budget: json['budget'] as String?,
      client: const ProjectClientRef(id: 0, clientName: '', companyName: ''),
      projectManager: const ProjectUserRef(id: 0, name: '', email: ''),
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }
}

class ProjectDetail {
  ProjectDetail({required this.project, this.team = const [], this.milestones = const [], this.documents = const []});

  final Project project;
  final List<ProjectTeamMember> team;
  final List<ProjectMilestone> milestones;
  final List<ProjectDocument> documents;

  factory ProjectDetail.fromApiMap(Map<String, dynamic> data) {
    final team = <ProjectTeamMember>[];
    if (data['team'] is List) {
      for (final t in data['team'] as List) {
        if (t is Map<String, dynamic>) team.add(ProjectTeamMember.fromJson(t));
      }
    }
    final milestones = <ProjectMilestone>[];
    if (data['milestones'] is List) {
      for (final m in data['milestones'] as List) {
        if (m is Map<String, dynamic>) milestones.add(ProjectMilestone.fromJson(m));
      }
    }
    final documents = <ProjectDocument>[];
    if (data['documents'] is List) {
      for (final d in data['documents'] as List) {
        if (d is Map<String, dynamic>) documents.add(ProjectDocument.fromJson(d));
      }
    }
    return ProjectDetail(project: Project.fromApiMap(data), team: team, milestones: milestones, documents: documents);
  }
}

class ProjectTeamInput {
  const ProjectTeamInput({required this.employeeId, required this.role});

  final int employeeId;
  final String role;

  Map<String, dynamic> toJson() => {'employee_id': employeeId, 'role': role};
}

class ProjectMilestoneInput {
  const ProjectMilestoneInput({required this.name, required this.dueDate, required this.amount, required this.order});

  final String name;
  final String dueDate;
  final num amount;
  final int order;

  Map<String, dynamic> toJson() => {'name': name, 'due_date': dueDate, 'amount': amount, 'order': order};
}

class ProjectCreateRequest {
  const ProjectCreateRequest({
    required this.name,
    required this.clientId,
    required this.projectType,
    required this.startDate,
    this.estimatedEndDate,
    required this.status,
    required this.priority,
    required this.description,
    required this.paymentFrequency,
    this.budget,
    required this.projectManagerId,
    this.team = const [],
    this.milestones = const [],
  });

  final String name;
  final int clientId;
  final String projectType;
  final String startDate;
  final String? estimatedEndDate;
  final String status;
  final String priority;
  final String description;
  final String paymentFrequency;
  final num? budget;
  final int projectManagerId;
  final List<ProjectTeamInput> team;
  final List<ProjectMilestoneInput> milestones;

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'name': name,
      'client_id': clientId,
      'project_type': projectType,
      'start_date': startDate,
      'status': status,
      'priority': priority,
      'description': description,
      'payment_frequency': paymentFrequency,
      'project_manager_id': projectManagerId,
    };
    if (estimatedEndDate != null && estimatedEndDate!.trim().isNotEmpty) {
      body['estimated_end_date'] = estimatedEndDate;
    }
    if (budget != null) body['budget'] = budget;
    if (team.isNotEmpty) body['team'] = team.map((e) => e.toJson()).toList();
    if (milestones.isNotEmpty) {
      body['milestones'] = milestones.map((e) => e.toJson()).toList();
    }
    return body;
  }
}
