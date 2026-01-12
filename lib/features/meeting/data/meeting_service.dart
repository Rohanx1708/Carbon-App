import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

class MeetingService {
  static const String _key = 'meetings_v1';

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
    final list = await all();
    list.insert(0, meeting);
    await _save(list);
  }

  Future<void> deleteAt(int index) async {
    final list = await all();
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    await _save(list);
  }
}
