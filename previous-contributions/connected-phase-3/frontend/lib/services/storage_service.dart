import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service for persistent data
class StorageService {
  static const String _currentUserKey = 'current_user';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _languageKey = 'language';

  late SharedPreferences _prefs;

  /// Initialize storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ============ User Data ============

  /// Save current user data to local storage
  Future<void> saveCurrentUser(Map<String, dynamic> userData) async {
    await _prefs.setString(_currentUserKey, jsonEncode(userData));
  }

  /// Get current user data from local storage
  Map<String, dynamic>? getCurrentUser() {
    final data = _prefs.getString(_currentUserKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  /// Clear current user data
  Future<void> clearCurrentUser() async {
    await _prefs.remove(_currentUserKey);
  }

  // ============ FCM Token ============

  /// Save FCM token
  Future<void> saveFCMToken(String token) async {
    await _prefs.setString(_fcmTokenKey, token);
  }

  /// Get FCM token
  String? getFCMToken() {
    return _prefs.getString(_fcmTokenKey);
  }

  /// Clear FCM token
  Future<void> clearFCMToken() async {
    await _prefs.remove(_fcmTokenKey);
  }

  // ============ Language ============

  /// Save language preference
  Future<void> saveLanguage(String language) async {
    await _prefs.setString(_languageKey, language);
  }

  /// Get saved language preference
  String? getLanguage() {
    return _prefs.getString(_languageKey);
  }

  // ============ Generic Storage ============

  /// Save generic string data
  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  /// Get generic string data
  String? getString(String key) {
    return _prefs.getString(key);
  }

  /// Save generic int data
  Future<void> saveInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  /// Get generic int data
  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  /// Save generic bool data
  Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  /// Get generic bool data
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  /// Remove data
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  /// Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

/// Singleton instance of Storage Service
final storageService = StorageService();
