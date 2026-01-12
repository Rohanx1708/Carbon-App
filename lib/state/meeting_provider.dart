import 'package:flutter/foundation.dart';

import 'package:attendance/features/meeting/data/meeting_service.dart';

class MeetingProvider extends ChangeNotifier {
  MeetingProvider({MeetingService? service}) : _service = service ?? MeetingService();

  final MeetingService _service;

  List<Meeting> _meetings = <Meeting>[];
  List<Meeting> get meetings => _meetings;

  bool _loading = false;
  bool get loading => _loading;

  Object? _error;
  Object? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _meetings = await _service.all();
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> add(Meeting meeting) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.add(meeting);
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
