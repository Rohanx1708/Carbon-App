import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Lead {
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

  Future<void> _save(List<Lead> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = list.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, raw);
  }

  Future<List<Lead>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    final list = raw
        .map((e) => Lead.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> add(Lead lead) async {
    final list = await all();
    list.insert(0, lead);
    await _save(list);
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
