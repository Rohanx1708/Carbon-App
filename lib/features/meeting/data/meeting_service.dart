import 'dart:convert';

import 'package:intl/intl.dart';

import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/features/lead/data/lead_models.dart';
import 'package:attendance/services/api_client.dart';
import 'package:attendance/services/local_storage_service.dart';
import 'package:attendance/services/storage_keys.dart';

class MeetingAttachment {
  final String name;
  final String? path;

  const MeetingAttachment({required this.name, required this.path});

  Map<String, dynamic> toJson() => {'name': name, 'path': path};

  factory MeetingAttachment.fromJson(Map<String, dynamic> json) =>
      MeetingAttachment(name: (json['name'] as String?) ?? '', path: json['path'] as String?);
}

class Meeting {
  final int? id;
  final String title;
  final String organizer;
  final String? organizerName;
  final String type; // With Lead, With Client, With Team, Other

  final String? lead;
  final String? client;
  final List<String> team;
  final String? otherMeeting;

  final DateTime startDateTime;
  final DateTime endDateTime;

  final String? location;
  final String agenda;
  final String? notes;

  final List<MeetingAttachment> attachments;

  final DateTime createdAt;

  Meeting({
    this.id,
    required this.title,
    required this.organizer,
    String? organizerName,
    required this.type,
    required this.startDateTime,
    required this.endDateTime,
    required this.agenda,
    required this.createdAt,
    this.lead,
    this.client,
    this.team = const <String>[],
    this.otherMeeting,
    this.location,
    this.notes,
    this.attachments = const <MeetingAttachment>[],
  }) : organizerName = organizerName;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'organizer': organizer,
    'organizerName': organizerName,
    'type': type,
    'lead': lead,
    'client': client,
    'team': team,
    'otherMeeting': otherMeeting,
    'startDateTime': startDateTime.toIso8601String(),
    'endDateTime': endDateTime.toIso8601String(),
    'location': location,
    'agenda': agenda,
    'notes': notes,
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Meeting.fromJson(Map<String, dynamic> json) => Meeting(
    id: json['id'] is int ? (json['id'] as int) : int.tryParse((json['id'] ?? '').toString()),
    title: (json['title'] as String?) ?? '',
    organizer: (json['organizer'] as String?) ?? '',
    organizerName: (json['organizerName'] as String?) ?? '',
    type: (json['type'] as String?) ?? 'With Team',
    lead: json['lead'] as String?,
    client: json['client'] as String?,
    team: (json['team'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[],
    otherMeeting: json['otherMeeting'] as String?,
    startDateTime: DateTime.tryParse((json['startDateTime'] as String?) ?? '') ?? DateTime.now(),
    endDateTime: DateTime.tryParse((json['endDateTime'] as String?) ?? '') ?? DateTime.now(),
    location: json['location'] as String?,
    agenda: (json['agenda'] as String?) ?? '',
    notes: json['notes'] as String?,
    attachments:
        (json['attachments'] as List?)?.map((e) => MeetingAttachment.fromJson(e as Map<String, dynamic>)).toList() ??
        const <MeetingAttachment>[],
    createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
  );
}

class RemoteMeetingDetails {
  final int id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String meetingType; // lead/client/employee/other
  final String? customType;
  final String agenda;
  final String? notes;
  final String? description;
  final String status;
  final String? mom;
  final String? remark;

  final int organizerId;
  final String organizerName;

  final int? leadId;
  final String? leadName;

  final int? clientId;
  final String? clientName;

  final List<int> employeeIds;
  final List<String> employeeNames;

  final DateTime createdAt;
  final DateTime updatedAt;

  const RemoteMeetingDetails({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.meetingType,
    required this.customType,
    required this.agenda,
    required this.notes,
    required this.description,
    required this.status,
    required this.mom,
    required this.remark,
    required this.organizerId,
    required this.organizerName,
    required this.leadId,
    required this.leadName,
    required this.clientId,
    required this.clientName,
    required this.employeeIds,
    required this.employeeNames,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _parseApiDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
    return DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw, true).toLocal();
  }

  factory RemoteMeetingDetails.fromApi(Map<String, dynamic> data) {
    final organizer = (data['organizer'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final organizerId = (organizer['id'] is int)
        ? organizer['id'] as int
        : int.tryParse((organizer['id'] ?? '').toString()) ?? 0;
    final organizerName = (organizer['name'] as String?) ?? organizerId.toString();

    final lead = data['lead'] as Map<String, dynamic>?;
    final client = data['client'] as Map<String, dynamic>?;

    final leadId = lead == null ? null : int.tryParse((lead['id'] ?? '').toString());
    final leadName = lead == null ? null : MeetingService._relatedDisplayName(lead);

    final clientId = client == null ? null : int.tryParse((client['id'] ?? '').toString());
    final clientName = client == null ? null : MeetingService._clientDisplayName(client);

    final employees = (data['employees'] as List?)?.whereType<Map>().toList() ?? const <Map>[];
    final employeeIds = <int>[];
    final employeeNames = <String>[];
    for (final e in employees) {
      final id = int.tryParse((e['id'] ?? '').toString());
      if (id != null) employeeIds.add(id);
      employeeNames.add((e['name'] as String?) ?? (id?.toString() ?? ''));
    }

    return RemoteMeetingDetails(
      id: int.tryParse((data['id'] ?? '').toString()) ?? 0,
      title: (data['title'] as String?) ?? '',
      startTime: _parseApiDateTime((data['start_time'] as String?) ?? ''),
      endTime: _parseApiDateTime((data['end_time'] as String?) ?? ''),
      location: data['location'] as String?,
      meetingType: (data['meeting_type'] as String?) ?? 'employee',
      customType: data['custom_type'] as String?,
      agenda: (data['agenda'] as String?) ?? '',
      notes: data['notes'] as String?,
      description: data['description'] as String?,
      status: (data['status'] as String?) ?? 'scheduled',
      mom: data['mom'] as String?,
      remark: data['remark'] as String?,
      organizerId: organizerId,
      organizerName: organizerName,
      leadId: leadId,
      leadName: leadName,
      clientId: clientId,
      clientName: clientName,
      employeeIds: employeeIds,
      employeeNames: employeeNames,
      createdAt: _parseApiDateTime((data['created_at'] as String?) ?? ''),
      updatedAt: _parseApiDateTime((data['updated_at'] as String?) ?? ''),
    );
  }

  String get uiMeetingType {
    switch (meetingType) {
      case 'lead':
        return 'With Lead';
      case 'client':
        return 'With Client';
      case 'employee':
        return 'With Team';
      case 'other':
        return 'Other';
      default:
        return 'With Team';
    }
  }

  Meeting toMeetingForEdit() {
    return Meeting(
      id: id,
      title: title,
      organizer: organizerId.toString(),
      organizerName: organizerName,
      type: uiMeetingType,
      lead: meetingType == 'lead' ? leadId?.toString() : null,
      client: meetingType == 'client' ? clientId?.toString() : null,
      team: meetingType == 'employee' ? employeeIds.map((e) => e.toString()).toList() : const <String>[],
      otherMeeting: meetingType == 'other' ? customType : null,
      startDateTime: startTime,
      endDateTime: endTime,
      location: location,
      agenda: agenda,
      notes: notes,
      attachments: const <MeetingAttachment>[],
      createdAt: createdAt,
    );
  }
}

class RemoteMeetingLog {
  final int id;
  final String comment;
  final String type;
  final DateTime createdAt;

  const RemoteMeetingLog({required this.id, required this.comment, required this.type, required this.createdAt});

  factory RemoteMeetingLog.fromApi(Map<String, dynamic> data) {
    final created = (data['created_at'] as String?) ?? '';
    return RemoteMeetingLog(
      id: int.tryParse((data['id'] ?? '').toString()) ?? 0,
      comment: (data['comment'] as String?) ?? '',
      type: (data['type'] as String?) ?? 'log',
      createdAt: MeetingService._parseApiDateTime(created),
    );
  }
}

class MeetingConflictCheck {
  const MeetingConflictCheck({required this.conflicts, required this.employeeConflicts});

  final List<Map<String, dynamic>> conflicts;
  final List<Map<String, dynamic>> employeeConflicts;

  bool get hasAny => conflicts.isNotEmpty || employeeConflicts.isNotEmpty;

  factory MeetingConflictCheck.fromApi(Map<String, dynamic>? data) {
    if (data == null) {
      return const MeetingConflictCheck(conflicts: [], employeeConflicts: []);
    }
    List<Map<String, dynamic>> readList(Object? raw) {
      if (raw is! List) return const [];
      return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }

    return MeetingConflictCheck(
      conflicts: readList(data['conflicts']),
      employeeConflicts: readList(data['employee_conflicts']),
    );
  }
}

class MeetingService {
  MeetingService({ApiClient? apiClient, LocalStorageService? storage})
    : _api = apiClient ?? ApiClient(),
      _storage = storage ?? LocalStorageService.instance;

  final ApiClient _api;
  final LocalStorageService _storage;

  static String? _clientDisplayName(Map<String, dynamic> client) {
    final company = (client['company_name'] as String?)?.trim();
    if (company != null && company.isNotEmpty) return company;
    final name = (client['client_name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    return (client['name'] as String?)?.trim();
  }

  static String? _relatedDisplayName(Map<String, dynamic> obj) {
    final name = (obj['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    final company = (obj['company_name'] as String?)?.trim();
    if (company != null && company.isNotEmpty) return company;
    return (obj['client_name'] as String?)?.trim();
  }

  static String _uiMeetingType(String meetingType) {
    switch (meetingType) {
      case 'lead':
        return 'With Lead';
      case 'client':
        return 'With Client';
      case 'other':
        return 'Other';
      case 'employee':
      default:
        return 'With Team';
    }
  }

  Meeting _meetingFromApiMap(Map<String, dynamic> map) {
    final meetingType = (map['meeting_type'] as String?) ?? 'employee';
    final uiType = _uiMeetingType(meetingType);

    final organizer = map['organizer'] as Map<String, dynamic>?;
    final organizerId = organizer == null ? null : int.tryParse((organizer['id'] ?? '').toString());
    final organizerName = organizer == null ? null : (organizer['name'] as String?) ?? (organizerId?.toString() ?? '');

    final lead = map['lead'] as Map<String, dynamic>?;
    final leadId = lead == null ? null : int.tryParse((lead['id'] ?? '').toString());

    final clientObj = map['client'] as Map<String, dynamic>?;
    final clientId = clientObj == null ? null : int.tryParse((clientObj['id'] ?? '').toString());

    final employees = (map['employees'] as List?)?.whereType<Map>().toList() ?? const <Map>[];
    final employeeIds = <String>[];
    for (final e in employees) {
      final id = int.tryParse((e['id'] ?? '').toString());
      if (id != null) employeeIds.add(id.toString());
    }

    return Meeting(
      id: int.tryParse((map['id'] ?? '').toString()),
      title: (map['title'] as String?) ?? '',
      organizer: (organizerId ?? '').toString(),
      organizerName: (organizerName ?? '').toString(),
      type: uiType,
      lead: meetingType == 'lead' ? leadId?.toString() : null,
      client: meetingType == 'client' ? clientId?.toString() : null,
      team: meetingType == 'employee' ? employeeIds : const <String>[],
      otherMeeting: meetingType == 'other' ? (map['custom_type'] as String?) : null,
      startDateTime: _parseApiDateTime((map['start_time'] as String?) ?? ''),
      endDateTime: _parseApiDateTime((map['end_time'] as String?) ?? ''),
      location: map['location'] as String?,
      agenda: (map['agenda'] as String?) ?? '',
      notes: map['notes'] as String?,
      attachments: const <MeetingAttachment>[],
      createdAt: _parseApiDateTime((map['created_at'] as String?) ?? ''),
    );
  }

  List<Meeting> _meetingsFromApiData(Object? data) {
    if (data is! List) {
      throw Exception('Invalid response');
    }
    final out = <Meeting>[];
    for (final item in data) {
      if (item is! Map) continue;
      out.add(_meetingFromApiMap(item.cast<String, dynamic>()));
    }
    out.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return out;
  }

  Future<List<Meeting>> _mergeAndSave(List<Meeting> incoming) async {
    final existing = await all();
    final byId = <int, Meeting>{
      for (final m in existing)
        if (m.id != null) m.id!: m,
    };
    for (final m in incoming) {
      if (m.id != null) {
        byId[m.id!] = m;
      }
    }
    final merged = byId.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _save(merged);
    return incoming;
  }

  static DateTime _parseApiDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
    return DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw, true).toLocal();
  }

  int _parseRequiredInt(String value, String fieldName) {
    final v = value.trim();
    final parsed = int.tryParse(v);
    if (parsed == null) {
      throw Exception('$fieldName must be a number');
    }
    return parsed;
  }

  Future<RemoteMeetingDetails> fetchDetails(int meetingId) async {
    final decoded = await _api.getJson('/api/v1/meetings/$meetingId');
    final data = decoded['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Invalid response');
    }
    return RemoteMeetingDetails.fromApi(data);
  }

  Future<void> postponeMeeting({
    required int meetingId,
    required DateTime newStartDateTime,
    required DateTime newEndDateTime,
    required String reason,
  }) async {
    await _api.postJson(
      '/api/v1/meetings/$meetingId/postpone',
      body: {
        'new_start_date_time': _formatApiDateTime(newStartDateTime),
        'new_end_date_time': _formatApiDateTime(newEndDateTime),
        'reason': reason,
      },
    );
  }

  Future<List<Meeting>> fetchAllRemote() async {
    final decoded = await _api.getJson('/api/v1/meetings');
    final out = _meetingsFromApiData(decoded['data']);
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _save(out);
    return out;
  }

  Future<List<Meeting>> fetchByDate(DateTime day) async {
    final date = DateFormat('yyyy-MM-dd').format(day);
    final decoded = await _api.getJson('/api/v1/meetings/date', queryParameters: {'date': date});
    final list = _meetingsFromApiData(decoded['data']);
    await _mergeAndSave(list);
    return list;
  }

  Future<List<Meeting>> fetchByDateRange({required DateTime start, required DateTime end}) async {
    final decoded = await _api.getJson(
      '/api/v1/meetings/date-range',
      queryParameters: {
        'start_date': DateFormat('yyyy-MM-dd').format(start),
        'end_date': DateFormat('yyyy-MM-dd').format(end),
      },
    );
    final list = _meetingsFromApiData(decoded['data']);
    await _mergeAndSave(list);
    return list;
  }

  Future<MeetingConflictCheck> checkConflicts({
    required int employeeId,
    required DateTime startDateTime,
    required DateTime endDateTime,
  }) async {
    final decoded = await _api.getJson(
      '/api/v1/meetings/conflicts',
      queryParameters: {
        'employee_id': employeeId.toString(),
        'start_date_time': _formatApiDateTime(startDateTime),
        'end_date_time': _formatApiDateTime(endDateTime),
      },
    );
    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return MeetingConflictCheck.fromApi(data);
    }
    if (data is Map) {
      return MeetingConflictCheck.fromApi(data.cast<String, dynamic>());
    }
    return const MeetingConflictCheck(conflicts: [], employeeConflicts: []);
  }

  Future<void> completeMeeting({required int meetingId, required String mom, String? remark}) async {
    await _api.postJson(
      '/api/v1/meetings/$meetingId/complete',
      body: {'mom': mom, if (remark != null && remark.trim().isNotEmpty) 'remark': remark.trim()},
    );
  }

  Future<List<LeadDocument>> fetchDocuments(int meetingId) async {
    final decoded = await _api.getJson('/api/v1/meetings/$meetingId/documents');
    final data = decoded['data'];
    if (data is! List) {
      throw Exception('Invalid response');
    }
    return data.whereType<Map>().map((e) => LeadDocument.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<void> uploadDocument({
    required int meetingId,
    required String filePath,
    required String filename,
    required String title,
  }) async {
    await _api.postMultipartFile(
      '/api/v1/meetings/$meetingId/documents',
      fileField: 'file',
      filePath: filePath,
      filename: filename,
      fields: {'title': title},
      maxFileBytes: 10 * 1024 * 1024,
    );
  }

  Future<void> deleteDocument({required int meetingId, required int documentId}) async {
    await _api.postJson('/api/v1/meetings/$meetingId/documents/$documentId/delete');
  }

  Future<List<RemoteMeetingLog>> fetchLogs(int meetingId) async {
    final decoded = await _api.getJson('/api/v1/meetings/$meetingId/logs');
    final data = decoded['data'];
    if (data is! List) {
      throw Exception('Invalid response');
    }
    return data.whereType<Map>().map((e) => RemoteMeetingLog.fromApi(e.cast<String, dynamic>())).toList();
  }

  Future<void> createLog({required int meetingId, required String comment}) async {
    await _api.postJson('/api/v1/meetings/$meetingId/logs', body: {'comment': comment, 'type': 'log'});
  }

  Future<void> _deleteRemote(int meetingId) async {
    await _api.postJson('/api/v1/meetings/$meetingId/delete');
  }

  int? _parseOptionalInt(String? value, String fieldName) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final parsed = int.tryParse(v);
    if (parsed == null) {
      throw Exception('$fieldName must be a number');
    }
    return parsed;
  }

  List<int> _parseIdList(List<String> values, String fieldName) {
    final out = <int>[];
    for (final raw in values) {
      final v = raw.trim();
      if (v.isEmpty) continue;
      final parsed = int.tryParse(v);
      if (parsed == null) {
        throw Exception('$fieldName must contain only numbers');
      }
      out.add(parsed);
    }
    return out;
  }

  String _apiMeetingType(String type) {
    switch (type) {
      case 'With Lead':
        return 'lead';
      case 'With Client':
        return 'client';
      case 'With Team':
        return 'employee';
      case 'Other':
        return 'other';
      default:
        return 'employee';
    }
  }

  String _formatApiDateTime(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
  }

  int? _tryExtractMeetingId(Object? decoded) {
    if (decoded is Map) {
      final direct = decoded['id'] ?? decoded['meeting_id'] ?? decoded['meetingId'];
      final parsedDirect = int.tryParse((direct ?? '').toString());
      if (parsedDirect != null) return parsedDirect;

      final data = decoded['data'];
      if (data is Map) {
        final dataId = data['id'] ?? data['meeting_id'] ?? data['meetingId'];
        final parsedDataId = int.tryParse((dataId ?? '').toString());
        if (parsedDataId != null) return parsedDataId;
      }
    }
    return null;
  }

  Future<int?> _createRemote(Meeting meeting) async {
    final meetingType = _apiMeetingType(meeting.type);

    final organizerId = _parseRequiredInt(meeting.organizer, 'organizer_id');

    final employeeIds = _parseIdList(meeting.team, 'employee_ids');
    if (employeeIds.isEmpty) {
      employeeIds.add(organizerId);
    }

    final payload = <String, dynamic>{
      'title': meeting.title,
      'organizer_id': organizerId,
      'meeting_type': meetingType,
      'start_date_time': _formatApiDateTime(meeting.startDateTime),
      'end_date_time': _formatApiDateTime(meeting.endDateTime),
      'location': meeting.location,
      'agenda': meeting.agenda,
      'notes': meeting.notes,
      'employee_ids': employeeIds,
    };

    final notes = (meeting.notes ?? '').trim();
    if (notes.isNotEmpty) {
      payload['description'] = notes;
    }

    if (meetingType == 'lead') {
      final leadId = _parseOptionalInt(meeting.lead, 'lead_id');
      if (leadId == null) {
        throw Exception('lead_id is required');
      }
      payload['lead_id'] = leadId;
    }

    if (meetingType == 'client') {
      final clientId = _parseOptionalInt(meeting.client, 'client_id');
      if (clientId == null) {
        throw Exception('client_id is required');
      }
      payload['client_id'] = clientId;
    }

    if (meetingType == 'other') {
      final custom = (meeting.otherMeeting ?? '').trim();
      if (custom.isEmpty) {
        throw Exception('Custom type is required');
      }
      payload['custom_type'] = custom;
    }

    final decoded = await _api.postJson('/api/v1/meetings', body: payload);
    return _tryExtractMeetingId(decoded);
  }

  Future<void> _updateRemote(int meetingId, Meeting meeting) async {
    final meetingType = _apiMeetingType(meeting.type);
    final organizerId = _parseRequiredInt(meeting.organizer, 'organizer_id');

    final employeeIds = _parseIdList(meeting.team, 'employee_ids');
    if (employeeIds.isEmpty) {
      employeeIds.add(organizerId);
    }

    final payload = <String, dynamic>{
      'title': meeting.title,
      'organizer_id': organizerId,
      'meeting_type': meetingType,
      'start_date_time': _formatApiDateTime(meeting.startDateTime),
      'end_date_time': _formatApiDateTime(meeting.endDateTime),
      'location': meeting.location,
      'agenda': meeting.agenda,
      'notes': meeting.notes,
      'status': 'scheduled',
      'employee_ids': employeeIds,
    };

    final notes = (meeting.notes ?? '').trim();
    if (notes.isNotEmpty) {
      payload['description'] = notes;
    }

    if (meetingType == 'lead') {
      final leadId = _parseOptionalInt(meeting.lead, 'lead_id');
      if (leadId == null) {
        throw Exception('lead_id is required');
      }
      payload['lead_id'] = leadId;
    }

    if (meetingType == 'client') {
      final clientId = _parseOptionalInt(meeting.client, 'client_id');
      if (clientId == null) {
        throw Exception('client_id is required');
      }
      payload['client_id'] = clientId;
    }

    if (meetingType == 'other') {
      final custom = (meeting.otherMeeting ?? '').trim();
      if (custom.isEmpty) {
        throw Exception('Custom type is required');
      }
      payload['custom_type'] = custom;
    }

    await _api.postJson('/api/v1/meetings/$meetingId/update', body: payload);
  }

  Future<void> _save(List<Meeting> list) async {
    final raw = list.map((e) => jsonEncode(e.toJson())).toList();
    await _storage.setStringList(StorageKeys.meetings, raw);
    await _storage.setInt(StorageKeys.meetingsCacheUpdatedAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> readLocalUpdatedAt() => CacheStamp.read(_storage, StorageKeys.meetingsCacheUpdatedAt);

  Future<List<Meeting>> readLocal() => all();

  Future<List<Meeting>> all() async {
    final raw = await _storage.getStringList(StorageKeys.meetings) ?? <String>[];
    final list = raw.map((e) => Meeting.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<int?> add(Meeting meeting) async {
    final id = await _createRemote(meeting);
    final list = await all();
    list.insert(
      0,
      Meeting(
        id: id,
        title: meeting.title,
        organizer: meeting.organizer,
        type: meeting.type,
        startDateTime: meeting.startDateTime,
        endDateTime: meeting.endDateTime,
        agenda: meeting.agenda,
        createdAt: meeting.createdAt,
        lead: meeting.lead,
        client: meeting.client,
        team: meeting.team,
        otherMeeting: meeting.otherMeeting,
        location: meeting.location,
        notes: meeting.notes,
        attachments: meeting.attachments,
      ),
    );
    await _save(list);
    return id;
  }

  Future<void> update(Meeting meeting) async {
    final id = meeting.id;
    if (id == null) {
      throw Exception('Meeting id is missing');
    }

    await _updateRemote(id, meeting);

    final list = await all();
    final idx = list.indexWhere((m) => m.id == id);
    if (idx >= 0) {
      list[idx] = meeting;
      await _save(list);
    }
  }

  Future<void> deleteById(int meetingId) async {
    await _deleteRemote(meetingId);
    final list = await all();
    list.removeWhere((m) => m.id == meetingId);
    await _save(list);
  }

  Future<void> deleteAt(int index) async {
    final list = await all();
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    await _save(list);
  }
}
