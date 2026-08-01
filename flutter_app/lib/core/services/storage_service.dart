import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _roleKey = 'user_role';
  static const _userIdKey = 'user_id';
  static const _uuidKey = 'device_uuid';
  static const _hashKey = 'device_hash';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveRole(String role) async {
    await _storage.write(key: _roleKey, value: role);
  }

  Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> deleteAuthData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _userIdKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveDeviceIdentity(String uuid, String hash) async {
    await _storage.write(key: _uuidKey, value: uuid);
    await _storage.write(key: _hashKey, value: hash);
  }

  Future<String?> getDeviceUUID() async {
    return await _storage.read(key: _uuidKey);
  }

  Future<String?> getDeviceHash() async {
    return await _storage.read(key: _hashKey);
  }
}
