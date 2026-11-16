import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecretStore {
  Future<String?> read(String id);
  Future<void> write(String id, String value);
  Future<void> delete(String id);
}

class SecureSecrets implements SecretStore {
  final FlutterSecureStorage storage;
  SecureSecrets([FlutterSecureStorage? value])
    : storage = value ?? const FlutterSecureStorage();
  @override
  Future<String?> read(String id) => storage.read(key: 'nabuclash.api.$id');
  @override
  Future<void> write(String id, String value) =>
      storage.write(key: 'nabuclash.api.$id', value: value);
  @override
  Future<void> delete(String id) => storage.delete(key: 'nabuclash.api.$id');
}

class LocalStore {
  final SharedPreferences prefs;
  LocalStore(this.prefs);
  Map<String, dynamic> load() {
    final raw = prefs.getString('nabuclash.v1');
    return raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<void> save(Map<String, dynamic> data) async {
    if (!await prefs.setString('nabuclash.v1', jsonEncode(data))) {
      throw const FormatException('storage');
    }
  }
}
