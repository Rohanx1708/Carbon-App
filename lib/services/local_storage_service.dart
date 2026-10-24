import 'package:shared_preferences/shared_preferences.dart';

/// Reuses a single [SharedPreferences] instance for the process.
class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sharedPreferences async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String?> getString(String key) async {
    return (await _sharedPreferences).getString(key);
  }

  Future<bool> setString(String key, String value) async {
    return (await _sharedPreferences).setString(key, value);
  }

  Future<bool> remove(String key) async {
    return (await _sharedPreferences).remove(key);
  }

  Future<List<String>?> getStringList(String key) async {
    return (await _sharedPreferences).getStringList(key);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    return (await _sharedPreferences).setStringList(key, value);
  }

  Future<int?> getInt(String key) async {
    return (await _sharedPreferences).getInt(key);
  }

  Future<bool> setInt(String key, int value) async {
    return (await _sharedPreferences).setInt(key, value);
  }
}
