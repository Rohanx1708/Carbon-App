import 'package:flutter/foundation.dart';

import 'package:attendance/features/lead/data/lead_service.dart';

class LeadProvider extends ChangeNotifier {
  LeadProvider({LeadService? service}) : _service = service ?? LeadService();

  final LeadService _service;

  List<Lead> _leads = <Lead>[];
  List<Lead> get leads => _leads;

  bool _loading = false;
  bool get loading => _loading;

  Object? _error;
  Object? get error => _error;

  String? _lastStatus;
  String? _lastSearch;

  Future<void> load({String? status, String? search}) async {
    _lastStatus = status;
    _lastSearch = search;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _leads = await _service.all(status: status, search: search);
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> add(Lead lead) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.add(lead);
      await load(status: _lastStatus, search: _lastSearch);
      return true;
    } catch (e) {
      _error = e;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(Lead lead) async {
    final id = lead.id;
    if (id == null) {
      _error = Exception('Lead id not available');
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.updateRemote(leadId: id, lead: lead);
      await load(status: _lastStatus, search: _lastSearch);
      return true;
    } catch (e) {
      _error = e;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteById(int leadId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteRemote(leadId);
      await load(status: _lastStatus, search: _lastSearch);
      return true;
    } catch (e) {
      _error = e;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteAt(int index) async {
    await _service.deleteAt(index);
    await load(status: _lastStatus, search: _lastSearch);
  }
}
