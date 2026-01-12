import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LeaveRequest {
  final String employeeName;
  final String status; // pending, approved, rejected
  final DateTime startDate;
  final DateTime endDate;
  final String type; // casual, sick, other
  final String reason;
  final String? attachmentName;
  final String? attachmentPath;

  LeaveRequest({
    required this.employeeName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.reason,
    this.attachmentName,
    this.attachmentPath,
  });

  Map<String, dynamic> toJson() => {
        'employeeName': employeeName,
        'status': status,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'type': type,
        'reason': reason,
        'attachmentName': attachmentName,
        'attachmentPath': attachmentPath,
      };

  factory LeaveRequest.fromJson(Map<String, dynamic> json) => LeaveRequest(
        employeeName: (json['employeeName'] as String?) ?? '',
        status: (json['status'] as String?) ?? 'pending',
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        type: json['type'] as String,
        reason: json['reason'] as String,
        attachmentName: json['attachmentName'] as String?,
        attachmentPath: json['attachmentPath'] as String?,
      );
}

class LeaveService {
  static const String _key = 'leave_requests_v1';

  Future<void> _save(List<LeaveRequest> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = list.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, raw);
  }

  Future<List<LeaveRequest>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    final list = raw
        .map((e) => LeaveRequest.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    // Migrate old entries missing status to 'pending'
    bool mutated = false;
    final normalized = <LeaveRequest>[];
    for (final item in list) {
      final dyn = item as dynamic;
      final String? st = dyn.status as String?;
      if (st == null) {
        normalized.add(LeaveRequest(
          employeeName: item.employeeName,
          status: 'pending',
          startDate: item.startDate,
          endDate: item.endDate,
          type: item.type,
          reason: item.reason,
          attachmentName: item.attachmentName,
          attachmentPath: item.attachmentPath,
        ));
        mutated = true;
      } else {
        normalized.add(item);
      }
    }
    if (mutated) {
      await _save(normalized);
    }
    normalized.sort((a, b) => b.startDate.compareTo(a.startDate));
    return normalized;
  }

  Future<void> add(LeaveRequest req) async {
    final list = await all();
    list.insert(0, req);
    await _save(list);
  }

  Future<void> updateAt(int index, LeaveRequest req) async {
    final list = await all();
    if (index < 0 || index >= list.length) return;
    list[index] = req;
    await _save(list);
  }

  Future<void> deleteAt(int index) async {
    final list = await all();
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    await _save(list);
  }
}


