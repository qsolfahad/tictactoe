import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  static const _userIdKey = 'user_id';
  static const _displayNameKey = 'display_name';

  static Future<String> getUserId() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    final uid = auth.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      return uid;
    }
    // Fallback: keep a local id if auth fails.
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_userIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    const fallback = 'local_user';
    await prefs.setString(_userIdKey, fallback);
    return fallback;
  }

  static Future<String> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_displayNameKey) ?? '';
  }

  static Future<void> setDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayNameKey, trimmed);
  }

}
