import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:attendance/services/app_config.dart';
import 'package:attendance/services/auth_service.dart';

class Lead {
  final int? id;
  final String clientCompany;
  final String companyEmail;
  final String companyPhone;
  final String pocDesignation;
  final String pocPhone;
  final String status; // Cold / Warm / Hot
  final String industry;
  final String requirements;
  final DateTime createdAt;

  Lead({
    this.id,
    required this.clientCompany,
    required this.companyEmail,
    required this.companyPhone,
    required this.pocDesignation,
    required this.pocPhone,
    required this.status,
    required this.industry,
    required this.requirements,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientCompany': clientCompany,
        'companyEmail': companyEmail,
        'companyPhone': companyPhone,
        'pocDesignation': pocDesignation,
        'pocPhone': pocPhone,
        'status': status,
        'industry': industry,
        'requirements': requirements,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
        id: json['id'] is int ? (json['id'] as int) : int.tryParse((json['id'] ?? '').toString()),
        clientCompany: (json['clientCompany'] as String?) ?? '',
        companyEmail: (json['companyEmail'] as String?) ?? '',
        companyPhone: (json['companyPhone'] as String?) ?? '',
        pocDesignation: (json['pocDesignation'] as String?) ?? '',
        pocPhone: (json['pocPhone'] as String?) ?? '',
        status: (json['status'] as String?) ?? 'Cold',
        industry: (json['industry'] as String?) ?? '',
        requirements: (json['requirements'] as String?) ?? '',
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
      );
}

class LeadService {
  static const String _key = 'leads_v1';

  static DateTime _parseApiDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
    return DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw, true).toLocal();
  }

  Future<void> createRemote(Lead lead) async {
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
      'company_name': lead.clientCompany,
      'company_email': lead.companyEmail,
      'company_phone': lead.companyPhone,
      'poc_designation': lead.pocDesignation,
      'poc_phone': lead.pocPhone,
      'lead_status': lead.status.toLowerCase(),
      'industry': lead.industry,
      'requirements': lead.requirements,
    };

    final uri = Uri.parse(baseUrl).resolve('/api/v1/leads');
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
          final msg = (decoded['message'] as String?) ?? 'Failed to create lead';
          throw Exception(msg);
        } catch (_) {
          throw Exception('Failed to create lead');
        }
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _save(List<Lead> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = list.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, raw);
  }

  Future<List<Lead>> _allLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    final list = raw.map((e) => Lead.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<Lead>> fetchAllRemote({String? status, String? search}) async {
    final token = await AuthService().getToken();
    final tokenType = (await AuthService().getTokenType()) ?? 'Bearer';
    if (token == null || token.trim().isEmpty) {
      throw Exception('Not authenticated');
    }

    final baseUrl = AppConfig.baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

    final baseUri = Uri.parse(baseUrl).resolve('/api/v1/leads');
    final qp = <String, String>{};
    final normalizedStatus = (status ?? '').trim().toLowerCase();
    final normalizedSearch = (search ?? '').trim();
    if (normalizedStatus.isNotEmpty) {
      qp['status'] = normalizedStatus;
    }
    if (normalizedSearch.isNotEmpty) {
      qp['search'] = normalizedSearch;
    }
    final uri = baseUri.replace(queryParameters: qp.isEmpty ? null : qp);
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
          final msg = (decoded['message'] as String?) ?? 'Failed to load leads';
          throw Exception(msg);
        } catch (_) {
          throw Exception('Failed to load leads');
        }
      }

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final data = decoded['data'];
      if (data is! List) {
        throw Exception('Invalid response');
      }

      final out = <Lead>[];
      for (final item in data) {
        if (item is! Map) continue;
        final m = item.cast<String, dynamic>();
        out.add(
          Lead(
            id: int.tryParse((m['id'] ?? '').toString()),
            clientCompany: (m['company_name'] as String?) ?? '',
            companyEmail: (m['company_email'] as String?) ?? '',
            companyPhone: (m['company_phone'] as String?) ?? '',
            pocDesignation: (m['poc_designation'] as String?) ?? '',
            pocPhone: (m['poc_phone'] as String?) ?? '',
            status: (m['lead_status'] as String?) ?? 'cold',
            industry: (m['industry'] as String?) ?? '',
            requirements: (m['requirements'] as String?) ?? '',
            createdAt: _parseApiDateTime((m['created_at'] as String?) ?? ''),
          ),
        );
      }
      out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return out;
    } finally {
      client.close(force: true);
    }
  }

  Future<Lead> fetchDetails(int leadId) async {
    final token = await AuthService().getToken();
    final tokenType = (await AuthService().getTokenType()) ?? 'Bearer';
    if (token == null || token.trim().isEmpty) {
      throw Exception('Not authenticated');
    }

    final baseUrl = AppConfig.baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

    final uri = Uri.parse(baseUrl).resolve('/api/v1/leads/$leadId');
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
          final msg = (decoded['message'] as String?) ?? 'Failed to load lead details';
          throw Exception(msg);
        } catch (_) {
          throw Exception('Failed to load lead details');
        }
      }

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Invalid response');
      }

      return Lead(
        id: int.tryParse((data['id'] ?? '').toString()) ?? leadId,
        clientCompany: (data['company_name'] as String?) ?? '',
        companyEmail: (data['company_email'] as String?) ?? '',
        companyPhone: (data['company_phone'] as String?) ?? '',
        pocDesignation: (data['poc_designation'] as String?) ?? '',
        pocPhone: (data['poc_phone'] as String?) ?? '',
        status: (data['lead_status'] as String?) ?? 'cold',
        industry: (data['industry'] as String?) ?? '',
        requirements: (data['requirements'] as String?) ?? '',
        createdAt: _parseApiDateTime((data['created_at'] as String?) ?? ''),
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<void> updateRemote({required int leadId, required Lead lead}) async {
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
      'company_name': lead.clientCompany,
      'company_email': lead.companyEmail,
      'company_phone': lead.companyPhone,
      'poc_designation': lead.pocDesignation,
      'poc_phone': lead.pocPhone,
      'lead_status': lead.status.toLowerCase(),
      'industry': lead.industry,
      'requirements': lead.requirements,
    };

    final uri = Uri.parse(baseUrl).resolve('/api/v1/leads/$leadId');
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
          final msg = (decoded['message'] as String?) ?? 'Failed to update lead';
          throw Exception(msg);
        } catch (_) {
          throw Exception('Failed to update lead');
        }
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<void> deleteRemote(int leadId) async {
    final token = await AuthService().getToken();
    final tokenType = (await AuthService().getTokenType()) ?? 'Bearer';
    if (token == null || token.trim().isEmpty) {
      throw Exception('Not authenticated');
    }

    final baseUrl = AppConfig.baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

    final uri = Uri.parse(baseUrl).resolve('/api/v1/leads/$leadId');
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
          final msg = (decoded['message'] as String?) ?? 'Failed to delete lead';
          throw Exception(msg);
        } catch (_) {
          throw Exception('Failed to delete lead');
        }
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<List<Lead>> all({String? status, String? search}) async {
    try {
      return await fetchAllRemote(status: status, search: search);
    } catch (_) {
      final list = await _allLocal();
      final normalizedStatus = (status ?? '').trim().toLowerCase();
      final normalizedSearch = (search ?? '').trim().toLowerCase();
      return list.where((l) {
        if (normalizedStatus.isNotEmpty && l.status.toLowerCase() != normalizedStatus) {
          return false;
        }
        if (normalizedSearch.isEmpty) return true;
        return l.clientCompany.toLowerCase().contains(normalizedSearch) ||
            l.companyEmail.toLowerCase().contains(normalizedSearch) ||
            l.companyPhone.toLowerCase().contains(normalizedSearch) ||
            l.industry.toLowerCase().contains(normalizedSearch) ||
            l.status.toLowerCase().contains(normalizedSearch);
      }).toList();
    }
  }

  Future<void> add(Lead lead) async {
    try {
      await createRemote(lead);
    } catch (_) {
      final list = await _allLocal();
      list.insert(0, lead);
      await _save(list);
    }
  }

  Future<void> updateAt(int index, Lead lead) async {
    final list = await all();
    if (index < 0 || index >= list.length) return;
    list[index] = lead;
    await _save(list);
  }

  Future<void> deleteAt(int index) async {
    final list = await all();
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    await _save(list);
  }
}
