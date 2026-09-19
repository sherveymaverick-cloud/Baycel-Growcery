import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _keyUid = 'session_uid';
  static const _keyRole = 'session_role';
  static const _keyName = 'session_name';
  static const _keyEmail = 'session_email';

  Future<void> saveSession({
    required String uid,
    required String role,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUid, uid);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
  }

  Future<Map<String, String>?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_keyUid);
    final role = prefs.getString(_keyRole);
    final name = prefs.getString(_keyName);
    final email = prefs.getString(_keyEmail);
    if (uid == null || role == null) return null;
    return {
      'uid': uid,
      'role': role,
      'name': name ?? '',
      'email': email ?? '',
    };
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUid);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
  }
}
