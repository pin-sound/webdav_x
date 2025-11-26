import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _usernameKey = 'webdav_username';
  static const String _passwordKey = 'webdav_password';
  static const String _encryptionPasswordKey = 'webdav_encryption_password';
  static const String _isConfiguredKey = 'is_configured';

  /// Save WebDAV credentials
  Future<void> saveCredentials(
    String username,
    String password,
    String encryptionPassword,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_passwordKey, password);
    await prefs.setString(_encryptionPasswordKey, encryptionPassword);
  }

  /// Get saved username
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  /// Get saved password
  Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey);
  }

  /// Get saved encryption password
  Future<String?> getEncryptionPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_encryptionPasswordKey);
  }

  /// Check if credentials are saved
  Future<bool> hasCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_usernameKey) && prefs.containsKey(_passwordKey);
  }

  /// Clear all saved credentials
  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_passwordKey);
    await prefs.remove(_encryptionPasswordKey);
    await prefs.remove(_isConfiguredKey);
  }

  /// Set configured status
  Future<void> setConfigured(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isConfiguredKey, value);
  }

  /// Check if configured
  Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isConfiguredKey) ?? false;
  }

  static const String _pathsKey = 'webdav_paths';

  /// Get saved paths
  Future<List<String>> getPaths() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_pathsKey) ?? [];
  }

  /// Add a new path
  Future<void> addPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final paths = prefs.getStringList(_pathsKey) ?? [];
    if (!paths.contains(path)) {
      paths.add(path);
      await prefs.setStringList(_pathsKey, paths);
    }
  }

  /// Remove a path
  Future<void> removePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final paths = prefs.getStringList(_pathsKey) ?? [];
    paths.remove(path);
    await prefs.setStringList(_pathsKey, paths);
  }

  /// Clear all data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static const String _dontAskNotificationKey =
      'dont_ask_notification_permission';

  /// Get don't ask notification permission preference
  Future<bool?> getDontAskNotificationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dontAskNotificationKey);
  }

  /// Set don't ask notification permission preference
  Future<void> setDontAskNotificationPermission(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dontAskNotificationKey, value);
  }
}
