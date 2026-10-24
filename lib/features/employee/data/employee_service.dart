import 'dart:convert';

import 'package:intl/intl.dart';

import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/features/lead/data/lead_models.dart';
import 'package:attendance/services/api_client.dart';
import 'package:attendance/services/local_storage_service.dart';
import 'package:attendance/services/storage_keys.dart';

/// Payload for `POST /api/v1/employees`.
class EmployeeCreateInput {
  const EmployeeCreateInput({
    required this.name,
    required this.email,
    required this.phone,
    required this.designation,
    required this.department,
    required this.employmentType,
    required this.experience,
    required this.skills,
    required this.joiningDate,
    required this.status,
  });

  final String name;
  final String email;
  final String phone;
  final String designation;
  final String department;
  final String employmentType;
  final String experience;
  final List<String> skills;
  final String joiningDate;
  final String status;

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'designation': designation,
    'department': department,
    'employment_type': employmentType,
    'experience': experience,
    'skills': skills,
    'joining_date': joiningDate,
    'status': status,
  };
}

class Employee {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String designation;
  final String department;
  final String employmentType;
  final String experience;
  final List<String> skills;
  final String joiningDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.designation,
    required this.department,
    required this.employmentType,
    required this.experience,
    required this.skills,
    required this.joiningDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'designation': designation,
    'department': department,
    'employment_type': employmentType,
    'experience': experience,
    'skills': skills,
    'joining_date': joiningDate,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Employee.fromApiMap(Map<String, dynamic> m) {
    final skillsRaw = m['skills'];
    final skills = <String>[];
    if (skillsRaw is List) {
      for (final s in skillsRaw) {
        if (s != null) skills.add(s.toString());
      }
    }

    return Employee(
      id: int.tryParse((m['id'] ?? '').toString()) ?? 0,
      name: (m['name'] as String?) ?? '',
      email: (m['email'] as String?) ?? '',
      phone: (m['phone'] as String?) ?? '',
      designation: (m['designation'] as String?) ?? '',
      department: (m['department'] as String?) ?? '',
      employmentType: (m['employment_type'] as String?) ?? '',
      experience: (m['experience'] as String?) ?? '',
      skills: skills,
      joiningDate: (m['joining_date'] as String?) ?? '',
      status: (m['status'] as String?) ?? '',
      createdAt: EmployeeService.parseApiDateTime((m['created_at'] as String?) ?? ''),
      updatedAt: EmployeeService.parseApiDateTime((m['updated_at'] as String?) ?? ''),
    );
  }
}

class EmployeePersonRef {
  const EmployeePersonRef({required this.id, required this.name, required this.email});

  final int id;
  final String name;
  final String email;

  factory EmployeePersonRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EmployeePersonRef(id: 0, name: '', email: '');
    return EmployeePersonRef(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
    );
  }
}

class EmployeeHistoryItem {
  const EmployeeHistoryItem({
    required this.id,
    required this.type,
    required this.title,
    required this.effectiveDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String type;
  final String title;
  final String effectiveDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory EmployeeHistoryItem.fromJson(Map<String, dynamic> json) => EmployeeHistoryItem(
    id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
    type: (json['type'] as String?) ?? '',
    title: (json['title'] as String?) ?? '',
    effectiveDate: (json['effective_date'] as String?) ?? '',
    notes: json['notes'] as String? ?? json['description'] as String?,
    createdAt: EmployeeService.parseApiDateTime((json['created_at'] as String?) ?? ''),
    updatedAt: EmployeeService.parseApiDateTime((json['updated_at'] as String?) ?? ''),
  );
}

class EmployeeDetail {
  const EmployeeDetail({
    required this.employee,
    required this.userId,
    this.reportingManagerId,
    this.reportingManager,
    this.user,
    required this.documents,
    required this.history,
  });

  final Employee employee;
  final int userId;
  final int? reportingManagerId;
  final EmployeePersonRef? reportingManager;
  final EmployeePersonRef? user;
  final List<LeadDocument> documents;
  final List<EmployeeHistoryItem> history;

  int get id => employee.id;
  String get name => employee.name;
  String get email => employee.email;
  String get phone => employee.phone;
  String get designation => employee.designation;
  String get department => employee.department;
  String get employmentType => employee.employmentType;
  String get experience => employee.experience;
  List<String> get skills => employee.skills;
  String get joiningDate => employee.joiningDate;
  String get status => employee.status;

  factory EmployeeDetail.fromApiMap(Map<String, dynamic> m) {
    final docs = <LeadDocument>[];
    final rawDocs = m['documents'];
    if (rawDocs is List) {
      for (final d in rawDocs) {
        if (d is Map<String, dynamic>) {
          docs.add(LeadDocument.fromJson(d));
        } else if (d is Map) {
          docs.add(LeadDocument.fromJson(d.cast<String, dynamic>()));
        }
      }
    }

    final managerRaw = m['reporting_manager'];
    EmployeePersonRef? manager;
    if (managerRaw is Map<String, dynamic>) {
      manager = EmployeePersonRef.fromJson(managerRaw);
    } else if (managerRaw is Map) {
      manager = EmployeePersonRef.fromJson(managerRaw.cast<String, dynamic>());
    }

    final userRaw = m['user'];
    EmployeePersonRef? user;
    if (userRaw is Map<String, dynamic>) {
      user = EmployeePersonRef.fromJson(userRaw);
    } else if (userRaw is Map) {
      user = EmployeePersonRef.fromJson(userRaw.cast<String, dynamic>());
    }

    return EmployeeDetail(
      employee: Employee.fromApiMap(m),
      userId: int.tryParse((m['user_id'] ?? '').toString()) ?? 0,
      reportingManagerId: int.tryParse((m['reporting_manager_id'] ?? '').toString()),
      reportingManager: manager != null && manager.id > 0 ? manager : null,
      user: user != null && user.id > 0 ? user : null,
      documents: docs,
      history: EmployeeService.parseHistoryList(m['history']),
    );
  }
}

class EmployeeService {
  EmployeeService({ApiClient? apiClient, LocalStorageService? storage})
    : _api = apiClient ?? ApiClient(),
      _storage = storage ?? LocalStorageService.instance;

  final ApiClient _api;
  final LocalStorageService _storage;

  static List<EmployeeHistoryItem> parseHistoryList(Object? raw) {
    if (raw is! List) return const [];
    final out = <EmployeeHistoryItem>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        final h = EmployeeHistoryItem.fromJson(item);
        if (h.id > 0 || h.title.isNotEmpty) out.add(h);
      } else if (item is Map) {
        final h = EmployeeHistoryItem.fromJson(item.cast<String, dynamic>());
        if (h.id > 0 || h.title.isNotEmpty) out.add(h);
      }
    }
    out.sort((a, b) {
      final ad = a.effectiveDate;
      final bd = b.effectiveDate;
      if (ad != bd) return bd.compareTo(ad);
      return b.createdAt.compareTo(a.createdAt);
    });
    return out;
  }

  static DateTime parseApiDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw, true).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  Future<void> _saveLocal(List<Employee> list) async {
    final raw = list.map((e) => jsonEncode(e.toJson())).toList();
    await _storage.setStringList(StorageKeys.employees, raw);
    await _storage.setInt(StorageKeys.employeesCacheUpdatedAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<Employee>> _allLocal() async {
    final raw = await _storage.getStringList(StorageKeys.employees) ?? <String>[];
    return raw.map((e) => Employee.fromApiMap(jsonDecode(e) as Map<String, dynamic>)).where((e) => e.id > 0).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<List<Employee>> fetchAllRemote() async {
    final decoded = await _api.getJson('/api/v1/employees');
    final data = decoded['data'];
    if (data is! List) {
      throw Exception('Invalid response');
    }

    final out = <Employee>[];
    for (final item in data) {
      if (item is! Map) continue;
      final emp = Employee.fromApiMap(item.cast<String, dynamic>());
      if (emp.id > 0) out.add(emp);
    }
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    await _saveLocal(out);
    return out;
  }

  Future<EmployeeDetail> fetchDetails(int employeeId) async {
    final decoded = await _api.getJson('/api/v1/employees/$employeeId');
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response');
    }
    final detail = EmployeeDetail.fromApiMap(data);
    if (detail.employee.id <= 0) {
      throw Exception('Employee not found');
    }
    return detail;
  }

  Future<List<EmployeeHistoryItem>> fetchHistory(int employeeId) async {
    final decoded = await _api.getJson('/api/v1/employees/$employeeId/history');
    final data = decoded['data'];
    if (data is! List) {
      throw Exception('Invalid response');
    }
    return parseHistoryList(data);
  }

  Future<DateTime?> readLocalUpdatedAt() => CacheStamp.read(_storage, StorageKeys.employeesCacheUpdatedAt);

  Future<List<Employee>> readLocal() => _allLocal();

  Future<List<Employee>> all() async {
    try {
      return await fetchAllRemote();
    } catch (_) {
      return _allLocal();
    }
  }

  int? _tryExtractId(Object? decoded) {
    if (decoded is! Map) return null;
    final direct = decoded['id'] ?? decoded['employee_id'];
    final parsed = int.tryParse((direct ?? '').toString());
    if (parsed != null) return parsed;
    final data = decoded['data'];
    if (data is Map) {
      return int.tryParse((data['id'] ?? data['employee_id'] ?? '').toString());
    }
    return null;
  }

  Future<int?> createEmployee(EmployeeCreateInput input) async {
    final decoded = await _api.postJson('/api/v1/employees', body: input.toJson());
    final id = _tryExtractId(decoded);
    await fetchAllRemote();
    return id;
  }

  Future<void> updateEmployee(int employeeId, Map<String, dynamic> body) async {
    if (body.isEmpty) return;
    await _api.postJson('/api/v1/employees/$employeeId/update', body: body);
    await fetchAllRemote();
  }

  Future<void> deleteEmployee(int employeeId) async {
    await _api.postJson('/api/v1/employees/$employeeId/delete');
    final local = await _allLocal();
    local.removeWhere((e) => e.id == employeeId);
    await _saveLocal(local);
  }

  Future<List<LeadDocument>> fetchDocuments(int employeeId) async {
    final decoded = await _api.getJson('/api/v1/employees/$employeeId/documents');
    final data = decoded['data'];
    if (data is! List) {
      throw Exception('Invalid response');
    }
    return data.whereType<Map>().map((e) => LeadDocument.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<void> uploadDocument({
    required int employeeId,
    required String filePath,
    required String filename,
    required String title,
  }) async {
    await _api.postMultipartFile(
      '/api/v1/employees/$employeeId/documents',
      fileField: 'file',
      filePath: filePath,
      filename: filename,
      fields: {'title': title},
      maxFileBytes: 10 * 1024 * 1024,
    );
  }

  Future<void> deleteDocument({required int employeeId, required int documentId}) async {
    await _api.postJson('/api/v1/employees/$employeeId/documents/$documentId/delete');
  }

  Future<void> addHistory({
    required int employeeId,
    required String type,
    required String title,
    required String effectiveDate,
  }) async {
    await _api.postJson(
      '/api/v1/employees/$employeeId/history',
      body: {'type': type, 'title': title, 'effective_date': effectiveDate},
    );
  }

  Map<String, dynamic> employeeToUpdateBody(Employee employee) => {
    'name': employee.name,
    'email': employee.email,
    'phone': employee.phone,
    'designation': employee.designation,
    'department': employee.department,
    'employment_type': employee.employmentType,
    'experience': employee.experience,
    'skills': employee.skills,
    'joining_date': employee.joiningDate,
    'status': employee.status,
  };
}
