import 'package:flutter/foundation.dart';

import 'package:attendance/features/client/data/client_service.dart';

class ClientDetailProvider extends ChangeNotifier {
  ClientDetailProvider({required this.clientId, ClientService? service}) : _service = service ?? ClientService();

  final int clientId;
  final ClientService _service;

  ClientDetail? _detail;
  ClientDetail? get detail => _detail;

  Client? get client => _detail?.client;

  List<ClientDocument> get documents => _detail?.documents ?? const [];

  bool _loading = false;
  bool get loading => _loading;

  bool _busy = false;
  bool get busy => _busy;

  Object? _error;
  Object? get error => _error;

  Future<void> load() async {
    _loading = _detail == null;
    _error = null;
    notifyListeners();
    try {
      _detail = await _service.fetchDetails(clientId);
      final docs = await _service.fetchDocuments(clientId);
      final base = _detail;
      if (base != null) {
        _detail = ClientDetail(
          client: base.client,
          projectsCount: base.projectsCount,
          projects: base.projects,
          documents: docs,
        );
      }
    } catch (e) {
      _error = e;
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      await action();
      await load();
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> update(Client client) => _run(() => _service.update(clientId: clientId, client: client));

  Future<bool> uploadDocument({required String filePath, required String filename, required String title}) =>
      _run(() => _service.uploadDocument(clientId: clientId, filePath: filePath, filename: filename, title: title));

  Future<bool> deleteDocument(int documentId) =>
      _run(() => _service.deleteDocument(clientId: clientId, documentId: documentId));
}
