import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const _tokenKey = 'auth_token';
  static const _backupTokenKey = 'auth_token_backup';
  static const _userKey = 'auth_user';

  static String? _cachedToken;
  static Map<String, dynamic>? _cachedUser;
  static bool _loaded = false;
  static Future<void>? _loading;

  Future<void> saveSession(String token, {Map<String, dynamic>? user}) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      throw ArgumentError.value(token, 'token', 'Token must not be empty');
    }

    await _ensureLoaded();
    final prefs = await SharedPreferences.getInstance();

    // Keep a second copy so an interrupted preference write cannot silently
    // sign the user out on the next app launch.
    final backupSaved = await prefs.setString(_backupTokenKey, normalizedToken);
    final primarySaved = await prefs.setString(_tokenKey, normalizedToken);
    if (!backupSaved || !primarySaved) {
      throw StateError('Unable to persist the login session');
    }

    _cachedToken = normalizedToken;
    if (user != null) {
      await saveUser(user);
    }

    final persistedPrimary = prefs.getString(_tokenKey)?.trim();
    final persistedBackup = prefs.getString(_backupTokenKey)?.trim();
    if (persistedPrimary != normalizedToken ||
        persistedBackup != normalizedToken) {
      throw StateError('Login session verification failed');
    }
  }

  Future<void> saveToken(String token) async {
    await saveSession(token);
  }

  Future<String?> getToken() async {
    await _ensureLoaded();
    return _cachedToken;
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    final snapshot = Map<String, dynamic>.from(user);
    final saved = await prefs.setString(_userKey, jsonEncode(snapshot));
    if (!saved) {
      throw StateError('Unable to persist the user profile');
    }
    _cachedUser = snapshot;
  }

  Future<Map<String, dynamic>?> getUser() async {
    await _ensureLoaded();
    final value = _cachedUser;
    return value == null ? null : Map<String, dynamic>.from(value);
  }

  Future<void> clearToken() async {
    await clearSession();
  }

  Future<void> clearSession() async {
    await _ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_tokenKey),
      prefs.remove(_backupTokenKey),
      prefs.remove(_userKey),
    ]);
    _cachedToken = null;
    _cachedUser = null;
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final activeLoad = _loading;
    if (activeLoad != null) {
      await activeLoad;
      return;
    }

    final operation = _loadFromDisk();
    _loading = operation;
    try {
      await operation;
    } finally {
      _loading = null;
    }
  }

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final primary = _validToken(prefs.getString(_tokenKey));
    final backup = _validToken(prefs.getString(_backupTokenKey));
    // The backup is written immediately before the primary. If the two ever
    // differ after an interrupted write, the backup is the newer value.
    final restoredToken = backup ?? primary;

    if (restoredToken != null) {
      if (primary != restoredToken) {
        await prefs.setString(_tokenKey, restoredToken);
      }
      if (backup != restoredToken) {
        await prefs.setString(_backupTokenKey, restoredToken);
      }
    }

    _cachedToken = restoredToken;
    _cachedUser = _decodeUser(prefs.getString(_userKey));
    _loaded = true;
  }

  String? _validToken(String? value) {
    final token = value?.trim();
    return token == null || token.isEmpty ? null : token;
  }

  Map<String, dynamic>? _decodeUser(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }
}
