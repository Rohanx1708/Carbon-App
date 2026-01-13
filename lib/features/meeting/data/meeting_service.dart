import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:attendance/services/app_config.dart';
import 'package:attendance/services/auth_service.dart';

class MeetingAttachment {
  final String name;
  final String? path;

  const MeetingAttachment({required this.name, required this.path});

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
      };

  factory MeetingAttachment.fromJson(Map<String, dynamic> json) => MeetingAttachment(
        name: (json['name'] as String?) ?? '',
        path: json['path'] as String?,
      );
}

class Meeting {
  final int? id;
  final String title;
  final String organizer;
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
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'organizer': organizer,
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
        attachments: (json['attachments'] as List?)
                ?.map((e) => MeetingAttachment.fromJson(e as Map<String, dynamic>))
                .toList() ??
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
  final String status;

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
    required this.status,
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
    final leadName = lead == null ? null : (lead['name'] as String?);

    final clientId = client == null ? null : int.tryParse((client['id'] ?? '').toString());
    final clientName = client == null ? null : (client['name'] as String?);

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
      status: (data['status'] as String?) ?? 'scheduled',
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

  const RemoteMeetingLog({
    required this.id,
    required this.comment,
    required this.type,
    required this.createdAt,
  });

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

class MeetingService {
  static const String _key = 'meetings_v1';

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
    final token = await AuthService().getToken();
    final tokenType = (await AuthService().getTokenType()) ?? 'Bearer';
    if (token == null || token.trim().isEmpty) {
      throw Exception('Not authenticated');
    }

    final baseUrl = AppConfig.baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

    final uri = Uri.parse(baseUrl).resolve('/api/v1/meetings/$meetingId');
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set(HttpHeaders.authorizationHeader, '$tokenType $token');

      final res = await req.close();
      final raw = await res.transform(utf8.decoder).join();

      if (res.statusCode < 200 || res.statusCode >= 300) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final msg = (decoded['message'] as String?) ?? 'Failed to load meeting details';
          throw Exception(msg);
        } catch (_) {
          throw Exception('Failed to load meeting details');
        }
      }

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Invalid response');
      }
      return RemoteMeetingDetails.fromApi(data);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> postponeMeeting({
    required int meetingId,
    required DateTime newStartDateTime,
    required DateTime newEndDateTime,
    required String reason,
  }) async {
    final token = await AuthService().getToken();
    final tokenType = (await AuthService().getTokenType()) ?? 'Bearer';
    if (token == null || token.trim().isEmpty) {
      throw Exception('Not authenticated');
    }

    final baseUrl = AppConfig.baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

    final payload = <String, dynamic>{
      'new_start_date_time': _formatApiDateTime(newStartDateTime),
      'new_end_date_time': _formatApiDateTime(newEndDateTime),
      'reason': reason,
    };

    final uri = Uri.parse(baseUrl).resolve('/api/v1/meetings/$meetingId/postpone');
    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set(HttpHeaders.authorizationHeader, '$tokenType $token');
      req.add(utf8.encode(jsonEncode(payload)));

      final res = await req.close();
      final raw = await res.transform(utf8.decoder).join();

      if (res.statusCode < 200 || res.statusCode >= 300) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final msg = (decoded['message'] as String?) ?? 'Failed to postpone meeting';
          throw Exception(msg);
        } catch (_) {
          throw Exception('Failed to postpone meeting');
        }
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<List<Meeting>> fetchAllRemote() async {
    final token = await AuthService().getToken();
    final tokenType = (await AuthService().getTokenType()) ?? 'Bearer';
    if (token == null || token.trim().isEmpty) {
      throw Exception('Not authenticated');
    }

    final baseUrl = AppConfig.baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

    final uri = Uri.parse(baseUrl).resolve('/api/v1/meetings');
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set(HttpHeaders.authorizationHeader, '$tokenType $token');

      final res = await req.close();
      final raw = await res.transform(utf8.decoder).join();

      if (res.statusCode < 200 || res.statusCode >= 300) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final msg = (decoded['message'] as String?) ?? 'Failed to load meetings';
          throw Exception(msg);
        } catch (_) {
          throw Exception('Failed to load meetings');
        }
      }

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final data = decoded['data'];
      if (data is! List) {
        throw Exception('Invalid response');
      }

      final out = <Meeting>[];
      for (final item in data) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();

        final meetingType = (map['meeting_type'] as String?) ?? 'employee';
        String uiType;
        switch (meetingType) {
          case 'lead':
            uiType = 'With Lead';
            break;
          case 'client':
            uiType = 'With Client';
            break;
          case 'other':
            uiType = 'Other';
            break;
          case 'employee':
          default:
            uiType = 'With Team';
            break;
        }

        final organizer = map['organizer'] as Map<String, dynamic>?;
        final organizerId = organizer == null ? null : int.tryParse((organizer['id'] ?? '').toString());

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

        out.add(
          Meeting(
            id: int.tryParse((map['id'] ?? '').toString()),
            title: (map['title'] as String?) ?? '',
            organizer: (organizerId ?? '').toString(),
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
          ),
        );
      }

      out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return out;
    } finally {
      client.close(force: true);
    }
  }

  Future<List<RemoteMeetingLog>> fetchLogs(int meetingId) async {
    final token = await AuthService().getToken();
    final tokenType = (await AuthService().getTokenType()) ?? 'Bearer';
    if (token == null || token.trim().isEmpty) {
      throw Exception('Not authenticated');
    }

    final baseUrl = AppConfig.baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

    final uri = Uri.parse(baseUrl).resolve('/api/v1/meetings/$meetingId/logs');
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set(HttpHeaders.authorizationHeader, '$tokenType $token');

      final res = await req.close();
      final raw = await res.transform(utf8.decoder).join();

      if (res.statusCode < 200 || res.statusCode >= 300) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final msg = (decoded['message'] as String?) ?? 'Failed to load logs';
          throw Exception(msg);
        } catch (_) {
          throw Exception('Failed to load logs');
        }
      }

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final data = decoded['data'];
      if (data is! List) {
        throw Exception('Invalid response');
      }
      return data.whereType<Map>().map((e) => RemoteMeetingLog.fromApi(e.cast<String, dynamic>())).toList();
    } finally {
      client.close(force: true);
    }
  }

  Future<void> createLog({required int meetingId, required String comment}) async {
    final token = await AuthService().getToken();
    final tokenType = (await AuthService().getTokenType()) ?? 'Bearer';
    if (token == null || token.trim().isEmpty) {
      throw Exception('Not authenticated');
    }

    final baseUrl = AppConfig.baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

    final uri = Uri.parse(baseUrl).resolve('/api/v1/meetings/$meetingId/logs');
    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set(HttpHeaders.authorizationHeader, '$tokenType $token');

      req.add(utf8.encode(jsonEncode({'comment': comment, 'type': 'log'})));

      final res = await req.close();
      final raw = await res.transform(utf8.decoder).join();

      if (res.statusCode < 200 || res.statusCode >= 300) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final msg = (decoded['message'] as String?) ?? 'Failed to create log';
          throw Exception(msg);
        } catch (_) {
          throw Exception('Failed to create log');
        }
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _deleteRemote(int meetingId) async {
    final token = await AuthService().getToken();
    final tokenType = (await AuthService().getTokenType()) ?? 'Bearer';
    if (token == null || token.trim().isEmpty) {
      throw Exception('Not authenticated');
    }

    final baseUrl = AppConfig.baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

    final uri = Uri.parse(baseUrl).resolve('/api/v1/meetings/$meetingId');
    final client = HttpClient();
    try {
      final req = await client.deleteUrl(uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set(HttpHeaders.authorizationHeader, '$tokenType $token');

      final res = await req.close();
      final raw = await res.transform(utf8.decoder).join();

      if (res.statusCode < 200 || res.statusCode >= 300) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final msg = (decoded['message'] as String?) ?? 'Failed to delete meeting';
          throw Exception(msg);
        } catch (_) {
          throw Exception('Failed to delete meeting');
        }
      }
    } finally {
      client.close(force: true);
    }
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
    final token = await AuthService().getToken();
    final tokenType = (await AuthService().getTokenType()) ?? 'Bearer';
    if (token == null || token.trim().isEmpty) {
      throw Exception('Not authenticated');
    }

    final baseUrl = AppConfig.baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

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

    final uri = Uri.parse(baseUrl).resolve('/api/v1/meetings');
    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set(HttpHeaders.authorizationHeader, '$tokenType $token');
      req.add(utf8.encode(jsonEncode(payload)));

      final res = await req.close();
      final raw = await res.transform(utf8.decoder).join();

      if (res.statusCode < 200 || res.statusCode >= 300) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final msg = (decoded['message'] as String?) ?? 'Failed to create meeting';
          throw Exception(msg);
        } catch (_) {
          throw Exception('Failed to create meeting');
        }
      }

      try {
        final decoded = jsonDecode(raw);
        return _tryExtractMeetingId(decoded);
      } catch (_) {
        return null;
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _updateRemote(int meetingId, Meeting meeting) async {
    final token = await AuthService().getToken();
    final tokenType = (await AuthService().getTokenType()) ?? 'Bearer';
    if (token == null || token.trim().isEmpty) {
      throw Exception('Not authenticated');
    }

    final baseUrl = AppConfig.baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

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

    final uri = Uri.parse(baseUrl).resolve('/api/v1/meetings/$meetingId');
    final client = HttpClient();
    try {
      final req = await client.putUrl(uri);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set(HttpHeaders.authorizationHeader, '$tokenType $token');
      req.add(utf8.encode(jsonEncode(payload)));

      final res = await req.close();
      final raw = await res.transform(utf8.decoder).join();

      if (res.statusCode < 200 || res.statusCode >= 300) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final msg = (decoded['message'] as String?) ?? 'Failed to update meeting';
          throw Exception(msg);
        } catch (_) {
          throw Exception('Failed to update meeting');
        }
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _save(List<Meeting> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = list.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, raw);
  }

  Future<List<Meeting>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    final list = raw.map((e) => Meeting.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> add(Meeting meeting) async {
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
