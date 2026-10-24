import 'package:flutter/foundation.dart';

import 'package:attendance/features/project/data/project_service.dart';

class ProjectDetailProvider extends ChangeNotifier {
  ProjectDetailProvider({required this.projectId, ProjectService? service}) : _service = service ?? ProjectService();

  final int projectId;
  final ProjectService _service;

  ProjectDetail? _detail;
  ProjectDetail? get detail => _detail;

  Project? get project => _detail?.project;

  List<ProjectDocument> get documents => _detail?.documents ?? const [];

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
      _detail = await _service.fetchDetails(projectId);
      final docs = await _service.fetchDocuments(projectId);
      final base = _detail;
      if (base != null) {
        _detail = ProjectDetail(project: base.project, team: base.team, milestones: base.milestones, documents: docs);
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

  Future<bool> updateFields(Map<String, dynamic> body) => _run(() => _service.update(projectId: projectId, body: body));

  Future<bool> uploadDocument({required String filePath, required String filename, required String title}) =>
      _run(() => _service.uploadDocument(projectId: projectId, filePath: filePath, filename: filename, title: title));

  Future<bool> deleteDocument(int documentId) =>
      _run(() => _service.deleteDocument(projectId: projectId, documentId: documentId));
}
