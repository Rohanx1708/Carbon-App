import 'package:intl/intl.dart';

class DocumentTypeRef {
  const DocumentTypeRef({required this.id, required this.name, this.category});

  final int id;
  final String name;
  final String? category;

  factory DocumentTypeRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DocumentTypeRef(id: 0, name: '');
    return DocumentTypeRef(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] as String?) ?? '',
      category: json['category'] as String?,
    );
  }
}

class DocumentUploader {
  const DocumentUploader({required this.id, required this.name});

  final int id;
  final String name;

  factory DocumentUploader.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DocumentUploader(id: 0, name: '');
    return DocumentUploader(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] as String?) ?? '',
    );
  }
}

class AppDocument {
  const AppDocument({
    required this.id,
    required this.title,
    this.fileName,
    this.fileUrl,
    this.fileSize,
    this.mimeType,
    this.notes,
    required this.documentTypeId,
    required this.documentType,
    required this.documentableType,
    required this.documentableId,
    this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String? fileName;
  final String? fileUrl;
  final int? fileSize;
  final String? mimeType;
  final String? notes;
  final int documentTypeId;
  final DocumentTypeRef documentType;
  final String documentableType;
  final int documentableId;
  final DocumentUploader? uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  static DateTime parseApiDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw, true).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  factory AppDocument.fromJson(Map<String, dynamic> json) => AppDocument(
    id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
    title: (json['title'] as String?) ?? 'Attachment',
    fileName: json['file_name'] as String?,
    fileUrl: json['file_url'] as String? ?? json['file_path'] as String?,
    fileSize: int.tryParse((json['file_size'] ?? '').toString()),
    mimeType: json['mime_type'] as String?,
    notes: json['notes'] as String?,
    documentTypeId: int.tryParse((json['document_type_id'] ?? '').toString()) ?? 0,
    documentType: DocumentTypeRef.fromJson(json['document_type'] as Map<String, dynamic>?),
    documentableType: (json['documentable_type'] as String?) ?? '',
    documentableId: int.tryParse((json['documentable_id'] ?? '').toString()) ?? 0,
    uploadedBy: DocumentUploader.fromJson(json['uploaded_by'] as Map<String, dynamic>?),
    createdAt: parseApiDateTime((json['created_at'] as String?) ?? ''),
    updatedAt: parseApiDateTime((json['updated_at'] as String?) ?? ''),
  );

  String get attachmentLabel {
    final type = documentableType.isEmpty ? 'record' : documentableType;
    return '$type #${documentableId > 0 ? documentableId : '?'}';
  }
}

class DocumentTypeItem {
  const DocumentTypeItem({
    required this.id,
    required this.name,
    required this.category,
    required this.isMandatory,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String category;
  final bool isMandatory;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory DocumentTypeItem.fromJson(Map<String, dynamic> json) => DocumentTypeItem(
    id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
    name: (json['name'] as String?) ?? '',
    category: (json['category'] as String?) ?? '',
    isMandatory: json['is_mandatory'] as bool? ?? false,
    description: (json['description'] as String?) ?? '',
    isActive: json['is_active'] as bool? ?? true,
    createdAt: AppDocument.parseApiDateTime((json['created_at'] as String?) ?? ''),
    updatedAt: AppDocument.parseApiDateTime((json['updated_at'] as String?) ?? ''),
  );
}

class DocumentTypeCreateInput {
  const DocumentTypeCreateInput({
    required this.name,
    required this.category,
    required this.isMandatory,
    required this.description,
  });

  final String name;
  final String category;
  final bool isMandatory;
  final String description;

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'is_mandatory': isMandatory,
    'description': description,
  };
}
