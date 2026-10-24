import 'package:attendance/features/document/data/document_models.dart';
import 'package:attendance/services/api_client.dart';

export 'document_models.dart';

class DocumentListQuery {
  const DocumentListQuery({this.documentableType, this.documentableId, this.search});

  final String? documentableType;
  final int? documentableId;
  final String? search;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentListQuery &&
          documentableType == other.documentableType &&
          documentableId == other.documentableId &&
          search == other.search;

  @override
  int get hashCode => Object.hash(documentableType, documentableId, search);
}

class DocumentService {
  DocumentService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<AppDocument>> listDocuments(DocumentListQuery query) async {
    final params = <String, String>{};
    final type = (query.documentableType ?? '').trim();
    if (type.isNotEmpty) params['documentable_type'] = type;
    if (query.documentableId != null && query.documentableId! > 0) {
      params['documentable_id'] = query.documentableId.toString();
    }
    final search = (query.search ?? '').trim();
    if (search.isNotEmpty) params['search'] = search;

    final decoded = await _api.getJson('/api/v1/documents', queryParameters: params.isEmpty ? null : params);
    final data = decoded['data'];
    if (data is! List) throw Exception('Invalid response');
    return data
        .whereType<Map>()
        .map((e) => AppDocument.fromJson(e.cast<String, dynamic>()))
        .where((d) => d.id > 0)
        .toList();
  }

  Future<AppDocument> fetchDocument(int documentId) async {
    final decoded = await _api.getJson('/api/v1/documents/$documentId');
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    return AppDocument.fromJson(data);
  }

  Future<void> uploadDocument({
    required String documentableType,
    required int documentableId,
    required String title,
    required String filePath,
    required String filename,
  }) async {
    await _api.postMultipartFile(
      '/api/v1/documents',
      fileField: 'file',
      filePath: filePath,
      filename: filename,
      fields: {'documentable_type': documentableType, 'documentable_id': documentableId.toString(), 'title': title},
      maxFileBytes: 10 * 1024 * 1024,
    );
  }

  Future<void> deleteDocument(int documentId) async {
    await _api.postJson('/api/v1/documents/$documentId/delete');
  }

  Future<List<DocumentTypeItem>> listDocumentTypes() async {
    final decoded = await _api.getJson('/api/v1/document-types');
    final data = decoded['data'];
    if (data is! List) throw Exception('Invalid response');
    return data
        .whereType<Map>()
        .map((e) => DocumentTypeItem.fromJson(e.cast<String, dynamic>()))
        .where((t) => t.id > 0)
        .toList();
  }

  Future<DocumentTypeItem> fetchDocumentType(int typeId) async {
    final decoded = await _api.getJson('/api/v1/document-types/$typeId');
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    return DocumentTypeItem.fromJson(data);
  }

  Future<void> createDocumentType(DocumentTypeCreateInput input) async {
    await _api.postJson('/api/v1/document-types', body: input.toJson());
  }

  Future<void> updateDocumentType(int typeId, Map<String, dynamic> body) async {
    await _api.postJson('/api/v1/document-types/$typeId/update', body: body);
  }

  Future<void> deleteDocumentType(int typeId) async {
    await _api.postJson('/api/v1/document-types/$typeId/delete');
  }
}
