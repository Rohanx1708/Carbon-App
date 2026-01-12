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

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _leads = await _service.all();
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
      await load();
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
    await load();
  }
}
