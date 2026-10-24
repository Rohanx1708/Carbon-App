import 'package:flutter/foundation.dart';

import 'package:attendance/features/lead/data/lead_service.dart';

class LeadDetailProvider extends ChangeNotifier {
  LeadDetailProvider({required this.leadId, LeadService? service}) : _service = service ?? LeadService();

  final int leadId;
  final LeadService _service;

  LeadDetail? _detail;
  LeadDetail? get detail => _detail;

  Lead? get lead => _detail?.lead;

  List<LeadComment> get comments => _detail?.comments ?? const [];
  List<LeadDocument> get documents => _detail?.documents ?? const [];
  List<LeadActionItem> get actions => _detail?.actions ?? const [];

  bool _loading = false;
  bool get loading => _loading;

  Object? _error;
  Object? get error => _error;

  bool _busy = false;
  bool get busy => _busy;

  Future<void> load() async {
    _loading = _detail == null;
    _error = null;
    notifyListeners();
    try {
      _detail = await _service.fetchDetails(leadId);
      await _refreshSidecars();
    } catch (e) {
      _error = e;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _refreshSidecars() async {
    final results = await Future.wait([
      _service.fetchComments(leadId),
      _service.fetchDocuments(leadId),
      _service.fetchActions(leadId),
    ]);
    final base = _detail;
    if (base == null) return;
    _detail = LeadDetail(
      lead: base.lead,
      comments: results[0] as List<LeadComment>,
      documents: results[1] as List<LeadDocument>,
      actions: results[2] as List<LeadActionItem>,
    );
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _detail = await _service.fetchDetails(leadId);
      await _refreshSidecars();
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> addComment(String text) => _run(() => _service.addComment(leadId: leadId, comment: text));

  Future<bool> changeStatus(String status, {String? remark}) =>
      _run(() => _service.changeStatus(leadId: leadId, leadStatus: status, remark: remark));

  Future<bool> changeStage(String stage, {String? remark}) =>
      _run(() => _service.changeStage(leadId: leadId, stage: stage, remark: remark));

  Future<bool> uploadDocument({required String filePath, required String filename, required String title}) =>
      _run(() => _service.uploadDocument(leadId: leadId, filePath: filePath, filename: filename, title: title));

  Future<bool> deleteDocument(int documentId) =>
      _run(() => _service.deleteDocument(leadId: leadId, documentId: documentId));

  Future<bool> addAction({
    required String actionType,
    required String description,
    required String actionDate,
    required String actionTime,
  }) => _run(
    () => _service.addAction(
      leadId: leadId,
      actionType: actionType,
      description: description,
      actionDate: actionDate,
      actionTime: actionTime,
    ),
  );

  Future<bool> completeAction({required int actionId, required String mom, String? remark}) =>
      _run(() => _service.completeAction(leadId: leadId, actionId: actionId, mom: mom, remark: remark));

  Future<bool> scheduleMeeting({
    required String title,
    required String date,
    required String time,
    required String endTime,
    required String location,
    required int organizerId,
  }) => _run(
    () => _service.scheduleMeeting(
      leadId: leadId,
      title: title,
      date: date,
      time: time,
      endTime: endTime,
      location: location,
      organizerId: organizerId,
    ),
  );
}
