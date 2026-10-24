import 'package:flutter/foundation.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/features/document/data/document_service.dart';

class DocumentProvider extends ChangeNotifier {
  DocumentProvider({DocumentService? service}) : _service = service ?? DocumentService();

  final DocumentService _service;

  List<AppDocument> _documents = [];
  List<AppDocument> get documents => _documents;

  List<DocumentTypeItem> _documentTypes = [];
  List<DocumentTypeItem> get documentTypes => _documentTypes;

  bool _loading = false;
  bool get loading => _loading;

  bool _typesLoading = false;
  bool get typesLoading => _typesLoading;

  bool _hasLoaded = false;
  bool get hasLoaded => _hasLoaded;

  bool _typesHasLoaded = false;
  bool get typesHasLoaded => _typesHasLoaded;

  Object? _error;
  Object? get error => _error;

  Object? _typesError;
  Object? get typesError => _typesError;

  DocumentListQuery _query = const DocumentListQuery();
  DocumentListQuery get query => _query;

  DateTime? _docsLoadedAt;
  DateTime? _typesLoadedAt;
  DocumentListQuery? _docsCachedQuery;

  Future<void> loadDocumentsIfNeeded({DocumentListQuery? query}) async {
    final next = query ?? _query;
    if (_hasLoaded &&
        _docsCachedQuery == next &&
        CacheStamp.isFresh(_docsLoadedAt, CachePolicy.documentsTtl)) {
      return;
    }
    await loadDocuments(query: query, force: false);
  }

  Future<void> loadDocuments({DocumentListQuery? query, bool force = true}) async {
    if (query != null) _query = query;
    if (!force &&
        _hasLoaded &&
        _docsCachedQuery == _query &&
        CacheStamp.isFresh(_docsLoadedAt, CachePolicy.documentsTtl)) {
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _documents = await _service.listDocuments(_query);
      _docsLoadedAt = DateTime.now();
      _docsCachedQuery = _query;
    } catch (e) {
      _error = e;
      _documents = [];
    }
    _loading = false;
    _hasLoaded = true;
    notifyListeners();
  }

  Future<void> loadDocumentTypesIfNeeded() async {
    if (_typesHasLoaded && CacheStamp.isFresh(_typesLoadedAt, CachePolicy.documentsTtl)) return;
    await loadDocumentTypes(force: false);
  }

  Future<void> loadDocumentTypes({bool force = true}) async {
    if (!force && _typesHasLoaded && CacheStamp.isFresh(_typesLoadedAt, CachePolicy.documentsTtl)) {
      return;
    }
    _typesLoading = true;
    _typesError = null;
    notifyListeners();
    try {
      _documentTypes = await _service.listDocumentTypes();
      _typesLoadedAt = DateTime.now();
    } catch (e) {
      _typesError = e;
    }
    _typesLoading = false;
    _typesHasLoaded = true;
    notifyListeners();
  }

  Future<bool> deleteDocument(int id) async {
    try {
      await _service.deleteDocument(id);
      await loadDocuments();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadDocument({
    required String documentableType,
    required int documentableId,
    required String title,
    required String filePath,
    required String filename,
  }) async {
    try {
      await _service.uploadDocument(
        documentableType: documentableType,
        documentableId: documentableId,
        title: title,
        filePath: filePath,
        filename: filename,
      );
      await loadDocuments();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createDocumentType(DocumentTypeCreateInput input) async {
    try {
      await _service.createDocumentType(input);
      await loadDocumentTypes();
      return true;
    } catch (e) {
      _typesError = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDocumentType(int id, Map<String, dynamic> body) async {
    try {
      await _service.updateDocumentType(id, body);
      await loadDocumentTypes();
      return true;
    } catch (e) {
      _typesError = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDocumentType(int id) async {
    try {
      await _service.deleteDocumentType(id);
      await loadDocumentTypes();
      return true;
    } catch (e) {
      _typesError = e;
      notifyListeners();
      return false;
    }
  }

  void clearSession() {
    _documents = [];
    _documentTypes = [];
    _hasLoaded = false;
    _typesHasLoaded = false;
    _docsLoadedAt = null;
    _typesLoadedAt = null;
    _docsCachedQuery = null;
    _error = null;
    _typesError = null;
    _loading = false;
    _typesLoading = false;
    notifyListeners();
  }
}
