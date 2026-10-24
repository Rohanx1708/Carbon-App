import 'package:attendance/services/api_client.dart';

class DirectoryItem {
  final int id;
  final String name;

  const DirectoryItem({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory DirectoryItem.fromJson(Map<String, dynamic> json) =>
      DirectoryItem(id: int.tryParse((json['id'] ?? '').toString()) ?? 0, name: (json['name'] as String?) ?? '');
}

class DirectoryService {
  DirectoryService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<DirectoryItem>> leads() async {
    return _getItems(path: '/api/v1/leads', idKey: 'id', nameKey: 'company_name');
  }

  Future<List<DirectoryItem>> clients() async {
    return _getItems(path: '/api/v1/clients', idKey: 'id', nameKey: 'client_name');
  }

  Future<List<DirectoryItem>> employees() async {
    return _getItems(path: '/api/v1/employees', idKey: 'id', nameKey: 'name');
  }

  Future<List<DirectoryItem>> _getItems({required String path, required String idKey, required String nameKey}) async {
    final decoded = await _api.getJson(path);
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
  }
}
