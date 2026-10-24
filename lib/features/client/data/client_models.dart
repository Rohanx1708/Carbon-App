import 'package:attendance/features/project/data/project_models.dart';

class Client {
  Client({
    required this.id,
    required this.clientName,
    required this.companyName,
    required this.email,
    required this.phone,
    required this.industry,
    required this.address,
    required this.notes,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String clientName;
  final String companyName;
  final String email;
  final String phone;
  final String industry;
  final String address;
  final String notes;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  String get displayName {
    if (companyName.trim().isNotEmpty) return companyName.trim();
    return clientName.trim();
  }

  factory Client.fromApiMap(Map<String, dynamic> json) => Client(
    id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
    clientName: (json['client_name'] as String?) ?? '',
    companyName: (json['company_name'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
    phone: (json['phone'] as String?) ?? '',
    industry: (json['industry'] as String?) ?? '',
    address: (json['address'] as String?) ?? '',
    notes: (json['notes'] as String?) ?? '',
    status: (json['status'] as String?) ?? 'active',
    createdAt: Project.parseApiDateTime((json['created_at'] as String?) ?? ''),
    updatedAt: json['updated_at'] != null ? Project.parseApiDateTime(json['updated_at'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientName': clientName,
    'companyName': companyName,
    'email': email,
    'phone': phone,
    'industry': industry,
    'address': address,
    'notes': notes,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
    id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
    clientName: (json['clientName'] as String?) ?? '',
    companyName: (json['companyName'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
    phone: (json['phone'] as String?) ?? '',
    industry: (json['industry'] as String?) ?? '',
    address: (json['address'] as String?) ?? '',
    notes: (json['notes'] as String?) ?? '',
    status: (json['status'] as String?) ?? 'active',
    createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
    updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
  );

  Map<String, dynamic> toCreatePayload() => {
    'client_name': clientName,
    'company_name': companyName,
    'email': email,
    'phone': phone,
    'industry': industry,
    'address': address,
    'status': status.toLowerCase(),
  };

  Map<String, dynamic> toUpdatePayload() => {
    'client_name': clientName,
    'company_name': companyName,
    'email': email,
    'phone': phone,
    'industry': industry,
    'address': address,
    'notes': notes,
    'status': status.toLowerCase(),
  };
}

class ClientDocument {
  const ClientDocument({
    required this.id,
    required this.title,
    this.fileName,
    this.fileUrl,
    this.documentTypeName,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String? fileName;
  final String? fileUrl;
  final String? documentTypeName;
  final DateTime createdAt;

  factory ClientDocument.fromJson(Map<String, dynamic> json) {
    final docType = json['document_type'];
    String? typeName;
    if (docType is Map<String, dynamic>) typeName = docType['name'] as String?;
    return ClientDocument(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      title: (json['title'] as String?) ?? 'Attachment',
      fileName: json['file_name'] as String?,
      fileUrl: json['file_url'] as String? ?? json['file_path'] as String?,
      documentTypeName: typeName,
      createdAt: Project.parseApiDateTime((json['created_at'] as String?) ?? ''),
    );
  }
}

class ClientDetail {
  ClientDetail({required this.client, this.projectsCount = 0, this.projects = const [], this.documents = const []});

  final Client client;
  final int projectsCount;
  final List<Project> projects;
  final List<ClientDocument> documents;

  factory ClientDetail.fromApiMap(Map<String, dynamic> data) {
    final projects = <Project>[];
    if (data['projects'] is List) {
      for (final p in data['projects'] as List) {
        if (p is Map<String, dynamic>) projects.add(Project.fromApiMap(p));
      }
    }
    final documents = <ClientDocument>[];
    if (data['documents'] is List) {
      for (final d in data['documents'] as List) {
        if (d is Map<String, dynamic>) documents.add(ClientDocument.fromJson(d));
      }
    }
    return ClientDetail(
      client: Client.fromApiMap(data),
      projectsCount: int.tryParse((data['projects_count'] ?? '').toString()) ?? projects.length,
      projects: projects,
      documents: documents,
    );
  }
}
