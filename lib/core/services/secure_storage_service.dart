import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserRole = 'user_role';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> saveUserData({
    required String userId,
    required String userName,
    required String role,
  }) async {
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyUserName, value: userName);
    await _storage.write(key: _keyUserRole, value: role);
  }

  Future<Map<String, String?>> getUserData() async {
    final userId = await _storage.read(key: _keyUserId);
    final userName = await _storage.read(key: _keyUserName);
    final role = await _storage.read(key: _keyUserRole);
    return {
      'userId': userId,
      'userName': userName,
      'role': role,
    };
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
