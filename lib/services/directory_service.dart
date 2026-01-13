import 'dart:convert';
import 'dart:io';

import 'package:attendance/services/app_config.dart';
import 'package:attendance/services/auth_service.dart';

class DirectoryItem {
  final int id;
  final String name;

  const DirectoryItem({required this.id, required this.name});
}

class DirectoryService {
  Future<List<DirectoryItem>> leads() async {
    return _getItems(
      path: '/api/v1/leads',
      idKey: 'id',
      nameKey: 'company_name',
    );
  }

  Future<List<DirectoryItem>> clients() async {
    return _getItems(
      path: '/api/v1/clients',
      idKey: 'id',
      nameKey: 'client_name',
    );
  }

  Future<List<DirectoryItem>> employees() async {
    return _getItems(
      path: '/api/v1/employees',
      idKey: 'id',
      nameKey: 'name',
    );
  }

  Future<List<DirectoryItem>> _getItems({
    required String path,
    required String idKey,
    required String nameKey,
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

    final uri = Uri.parse(baseUrl).resolve(path);
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
          final msg = (decoded['message'] as String?) ?? 'Request failed';
          throw Exception(msg);
        } catch (_) {
          throw Exception('Request failed');
        }
      }

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final data = decoded['data'] as List?;
      if (data == null) return <DirectoryItem>[];

      final items = <DirectoryItem>[];
      for (final e in data) {
        if (e is! Map) continue;
        final map = e.cast<String, dynamic>();
        final id = map[idKey];
        final name = map[nameKey];
        if (id is int && name != null) {
          items.add(DirectoryItem(id: id, name: name.toString()));
        } else if (id is String) {
          final parsed = int.tryParse(id);
          if (parsed != null && name != null) {
            items.add(DirectoryItem(id: parsed, name: name.toString()));
          }
        }
      }

      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return items;
    } on SocketException {
      throw Exception('Network error');
    } finally {
      client.close(force: true);
    }
  }
}
