import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _keyAccessToken = "moneyease_access_token";
  static const String _keyRefreshToken = "moneyease_refresh_token";
  static const String _keyUserRole = "moneyease_user_role";
  static const String _keyUserId = "moneyease_user_id";
  static const String _keyUserName = "moneyease_user_name";

  // In-memory fallback for environments where secure storage is mocked/unsupported
  static final Map<String, String> _memoryFallback = {};

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String role,
    required int userId,
    required String name,
  }) async {
    try {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
      await _storage.write(key: _keyUserRole, value: role);
      await _storage.write(key: _keyUserId, value: userId.toString());
      await _storage.write(key: _keyUserName, value: name);
    } catch (_) {
      _memoryFallback[_keyAccessToken] = accessToken;
      _memoryFallback[_keyRefreshToken] = refreshToken;
      _memoryFallback[_keyUserRole] = role;
      _memoryFallback[_keyUserId] = userId.toString();
      _memoryFallback[_keyUserName] = name;
    }
  }

  static Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _keyAccessToken) ?? _memoryFallback[_keyAccessToken];
    } catch (_) {
      return _memoryFallback[_keyAccessToken];
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken) ?? _memoryFallback[_keyRefreshToken];
    } catch (_) {
      return _memoryFallback[_keyRefreshToken];
    }
  }

  static Future<String?> getUserRole() async {
    try {
      return await _storage.read(key: _keyUserRole) ?? _memoryFallback[_keyUserRole];
    } catch (_) {
      return _memoryFallback[_keyUserRole];
    }
  }

  static Future<int?> getUserId() async {
    try {
      final val = await _storage.read(key: _keyUserId) ?? _memoryFallback[_keyUserId];
      return val != null ? int.tryParse(val) : null;
    } catch (_) {
      final val = _memoryFallback[_keyUserId];
      return val != null ? int.tryParse(val) : null;
    }
  }

  static Future<String?> getUserName() async {
    try {
      return await _storage.read(key: _keyUserName) ?? _memoryFallback[_keyUserName];
    } catch (_) {
      return _memoryFallback[_keyUserName];
    }
  }

  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
    _memoryFallback.clear();
  }
}

class TokenStorage {
  Future<String?> getAccessToken() => SecureStorageService.getAccessToken();
  Future<String?> getRefreshToken() => SecureStorageService.getRefreshToken();
  Future<String?> getUserRole() => SecureStorageService.getUserRole();
  Future<int?> getUserId() => SecureStorageService.getUserId();
  Future<String?> getUserName() => SecureStorageService.getUserName();
  Future<void> clearAll() => SecureStorageService.clearAll();
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
