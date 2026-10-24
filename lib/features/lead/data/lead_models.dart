import 'package:intl/intl.dart';

class LeadUserRef {
  const LeadUserRef({required this.id, required this.name, required this.email});

  final int id;
  final String name;
  final String email;

  factory LeadUserRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LeadUserRef(id: 0, name: '', email: '');
    return LeadUserRef(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
    );
  }
}

/// List / form model. [clientCompany] and [status] are aliases for API fields.
class Lead {
  Lead({
    this.id,
    this.leadCode,
    required this.companyName,
    required this.companyEmail,
    required this.companyPhone,
    this.website,
    this.pocName,
    required this.pocDesignation,
    required this.pocPhone,
    this.pocAltPhone,
    this.pocEmail,
    required this.leadStatus,
    this.stage,
    this.source,
    this.customSource,
    required this.industry,
    required this.requirements,
    this.estimatedValue,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.notes,
    this.assignedUser,
    required this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String? leadCode;
  final String companyName;
  final String companyEmail;
  final String companyPhone;
  final String? website;
  final String? pocName;
  final String pocDesignation;
  final String pocPhone;
  final String? pocAltPhone;
  final String? pocEmail;
  final String leadStatus;
  final String? stage;
  final String? source;
  final String? customSource;
  final String industry;
  final String requirements;
  final String? estimatedValue;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? notes;
  final LeadUserRef? assignedUser;
  final DateTime createdAt;
  final DateTime? updatedAt;

  String get clientCompany => companyName;
  String get status => leadStatus;

  static DateTime parseApiDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw, true).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  factory Lead.fromApiMap(Map<String, dynamic> m) {
    final assignedRaw = m['assigned_user'];
    return Lead(
      id: int.tryParse((m['id'] ?? '').toString()),
      leadCode: m['lead_code'] as String?,
      companyName: (m['company_name'] as String?) ?? '',
      companyEmail: (m['company_email'] as String?) ?? '',
      companyPhone: (m['company_phone'] as String?) ?? '',
      website: m['website'] as String?,
      pocName: m['poc_name'] as String?,
      pocDesignation: (m['poc_designation'] as String?) ?? '',
      pocPhone: (m['poc_phone'] as String?) ?? '',
      pocAltPhone: m['poc_alt_phone'] as String?,
      pocEmail: m['poc_email'] as String?,
      leadStatus: (m['lead_status'] as String?) ?? 'cold',
      stage: m['stage'] as String?,
      source: m['source'] as String?,
      customSource: m['custom_source'] as String?,
      industry: (m['industry'] as String?) ?? '',
      requirements: (m['requirements'] as String?) ?? '',
      estimatedValue: m['estimated_value']?.toString(),
      address: m['address'] as String?,
      city: m['city'] as String?,
      state: m['state'] as String?,
      country: m['country'] as String?,
      postalCode: m['postal_code'] as String?,
      notes: m['notes'] as String?,
      assignedUser: assignedRaw is Map<String, dynamic> ? LeadUserRef.fromJson(assignedRaw) : null,
      createdAt: parseApiDateTime((m['created_at'] as String?) ?? ''),
      updatedAt: m['updated_at'] != null ? parseApiDateTime(m['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'leadCode': leadCode,
    'companyName': companyName,
    'clientCompany': companyName,
    'companyEmail': companyEmail,
    'companyPhone': companyPhone,
    'website': website,
    'pocName': pocName,
    'pocDesignation': pocDesignation,
    'pocPhone': pocPhone,
    'pocAltPhone': pocAltPhone,
    'pocEmail': pocEmail,
    'leadStatus': leadStatus,
    'status': leadStatus,
    'stage': stage,
    'source': source,
    'customSource': customSource,
    'industry': industry,
    'requirements': requirements,
    'estimatedValue': estimatedValue,
    'address': address,
    'city': city,
    'state': state,
    'country': country,
    'postalCode': postalCode,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Lead.fromJson(Map<String, dynamic> json) {
    final company = (json['companyName'] as String?) ?? (json['clientCompany'] as String?) ?? '';
    final st = (json['leadStatus'] as String?) ?? (json['status'] as String?) ?? 'cold';
    return Lead(
      id: json['id'] is int ? json['id'] as int : int.tryParse((json['id'] ?? '').toString()),
      leadCode: json['leadCode'] as String?,
      companyName: company,
      companyEmail: (json['companyEmail'] as String?) ?? '',
      companyPhone: (json['companyPhone'] as String?) ?? '',
      website: json['website'] as String?,
      pocName: json['pocName'] as String?,
      pocDesignation: (json['pocDesignation'] as String?) ?? '',
      pocPhone: (json['pocPhone'] as String?) ?? '',
      pocAltPhone: json['pocAltPhone'] as String?,
      pocEmail: json['pocEmail'] as String?,
      leadStatus: st,
      stage: json['stage'] as String?,
      source: json['source'] as String?,
      customSource: json['customSource'] as String?,
      industry: (json['industry'] as String?) ?? '',
      requirements: (json['requirements'] as String?) ?? '',
      estimatedValue: json['estimatedValue'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toCreatePayload() {
    final body = <String, dynamic>{
      'company_name': companyName.trim(),
      'lead_status': leadStatus.trim().toLowerCase(),
      'stage': (stage ?? 'new').trim().toLowerCase(),
      'source': (source ?? 'other').trim().toLowerCase(),
    };

    void put(String key, String? v) {
      final t = v?.trim();
      if (t != null && t.isNotEmpty) body[key] = t;
    }

    put('company_email', companyEmail);
    put('company_phone', companyPhone);
    put('website', website);
    put('poc_name', pocName);
    put('poc_designation', pocDesignation);
    put('poc_phone', pocPhone);
    put('poc_email', pocEmail);
    put('industry', industry);
    put('requirements', requirements);
    put('address', address);
    put('city', city);
    put('state', state);
    put('country', country);
    put('postal_code', postalCode);

    if (estimatedValue != null && estimatedValue!.trim().isNotEmpty) {
      final n = num.tryParse(estimatedValue!.trim());
      if (n != null) body['estimated_value'] = n;
    }
    return body;
  }

  /// Partial update body — only non-empty fields are sent (API accepts sparse updates).
  Map<String, dynamic> toUpdatePayload() {
    final body = <String, dynamic>{
      'company_name': companyName.trim(),
      'lead_status': leadStatus.trim().toLowerCase(),
    };

    void put(String key, String? v) {
      final t = v?.trim();
      if (t != null && t.isNotEmpty) body[key] = t;
    }

    put('company_email', companyEmail);
    put('company_phone', companyPhone);
    put('website', website);
    put('poc_name', pocName);
    put('poc_designation', pocDesignation);
    put('poc_phone', pocPhone);
    put('poc_email', pocEmail);
    put('stage', stage?.toLowerCase());
    put('source', source?.toLowerCase());
    put('industry', industry);
    put('requirements', requirements);
    put('address', address);
    put('city', city);
    put('state', state);
    put('country', country);
    put('postal_code', postalCode);

    if (estimatedValue != null && estimatedValue!.trim().isNotEmpty) {
      final n = num.tryParse(estimatedValue!.trim());
      if (n != null) body['estimated_value'] = n;
    }
    return body;
  }
}

class LeadComment {
  const LeadComment({
    required this.id,
    required this.leadId,
    required this.comment,
    required this.type,
    this.oldStatus,
    this.newStatus,
    required this.user,
    required this.createdAt,
  });

  final int id;
  final int leadId;
  final String comment;
  final String type;
  final String? oldStatus;
  final String? newStatus;
  final LeadUserRef user;
  final DateTime createdAt;

  factory LeadComment.fromJson(Map<String, dynamic> json) => LeadComment(
    id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
    leadId: int.tryParse((json['lead_id'] ?? '').toString()) ?? 0,
    comment: (json['comment'] as String?) ?? '',
    type: (json['type'] as String?) ?? 'remark',
    oldStatus: json['old_status'] as String?,
    newStatus: json['new_status'] as String?,
    user: LeadUserRef.fromJson(json['user'] is Map<String, dynamic> ? json['user'] as Map<String, dynamic> : null),
    createdAt: Lead.parseApiDateTime((json['created_at'] as String?) ?? ''),
  );
}

class LeadDocument {
  const LeadDocument({
    required this.id,
    required this.title,
    this.fileName,
    this.fileUrl,
    this.fileSize,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String? fileName;
  final String? fileUrl;
  final int? fileSize;
  final DateTime createdAt;

  factory LeadDocument.fromJson(Map<String, dynamic> json) => LeadDocument(
    id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
    title: (json['title'] as String?) ?? (json['name'] as String?) ?? 'Attachment',
    fileName: json['file_name'] as String?,
    fileUrl: json['file_url'] as String? ?? json['url'] as String? ?? json['file_path'] as String?,
    fileSize: int.tryParse((json['file_size'] ?? json['size'] ?? '').toString()),
    createdAt: Lead.parseApiDateTime((json['created_at'] as String?) ?? ''),
  );
}

class LeadActionItem {
  const LeadActionItem({
    required this.id,
    required this.actionType,
    required this.description,
    this.actionDate,
    this.actionTime,
    this.isCompleted,
  });

  final int id;
  final String actionType;
  final String description;
  final String? actionDate;
  final String? actionTime;
  final bool? isCompleted;

  factory LeadActionItem.fromJson(Map<String, dynamic> json) => LeadActionItem(
    id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
    actionType: (json['action_type'] as String?) ?? '',
    description: (json['description'] as String?) ?? '',
    actionDate: json['action_date'] as String?,
    actionTime: json['action_time'] as String?,
    isCompleted: json['is_completed'] as bool? ?? json['completed'] as bool?,
  );
}

class LeadDetail {
  LeadDetail({required this.lead, this.comments = const [], this.documents = const [], this.actions = const []});

  final Lead lead;
  final List<LeadComment> comments;
  final List<LeadDocument> documents;
  final List<LeadActionItem> actions;

  factory LeadDetail.fromApiMap(Map<String, dynamic> data) {
    final comments = <LeadComment>[];
    final rawComments = data['comments'];
    if (rawComments is List) {
      for (final c in rawComments) {
        if (c is Map<String, dynamic>) comments.add(LeadComment.fromJson(c));
      }
    }
    final documents = <LeadDocument>[];
    final rawDocs = data['documents'];
    if (rawDocs is List) {
      for (final d in rawDocs) {
        if (d is Map<String, dynamic>) documents.add(LeadDocument.fromJson(d));
      }
    }
    final actions = <LeadActionItem>[];
    final rawActions = data['actions'];
    if (rawActions is List) {
      for (final a in rawActions) {
        if (a is Map<String, dynamic>) actions.add(LeadActionItem.fromJson(a));
      }
    }
    return LeadDetail(lead: Lead.fromApiMap(data), comments: comments, documents: documents, actions: actions);
  }
}

/// Query params for GET /api/v1/leads
class LeadListQuery {
  const LeadListQuery({this.status, this.stage, this.source, this.search});

  final String? status;
  final String? stage;
  final String? source;
  final String? search;

  bool matches(LeadListQuery other) {
    return status == other.status &&
        stage == other.stage &&
        source == other.source &&
        (search ?? '') == (other.search ?? '');
  }
}

/// Canonical lead status / stage values used across form, filters, and detail.
abstract final class LeadOptions {
  static const statuses = <String>['hot', 'warm', 'cold'];

  static const stages = <String>[
    'new',
    'contacted',
    'meeting_scheduled',
    'meeting_completed',
    'proposal_sent',
    'proposal_reviewed',
    'negotiation',
    'converted',
    'lost',
    'lost_closed',
    'nurturing',
    'future_prospect',
  ];

  static String label(String value) {
    final t = value.trim();
    if (t.isEmpty) return '';
    return t
        .split('_')
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
  }

  static Map<String, String> statusFilterOptions() => {for (final s in statuses) s: label(s)};

  static Map<String, String> stageFilterOptions() => {for (final s in stages) s: label(s)};
}
