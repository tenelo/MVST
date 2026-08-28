import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage sécurisé du token d'authentification Laravel.
/// N'est pour l'instant appelé nulle part : préparation pour le
/// branchement futur de [ApiClient] sur les écrans existants.
class TokenStorage {
  TokenStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _key = 'auth_token';

  static Future<void> saveToken(String token) {
    return _storage.write(key: _key, value: token);
  }

  static Future<String?> getToken() {
    return _storage.read(key: _key);
  }

  static Future<void> deleteToken() {
    return _storage.delete(key: _key);
  }
}
