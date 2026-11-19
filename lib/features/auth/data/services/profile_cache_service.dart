import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/user.dart';

/// Layanan cache profil non-sensitif menggunakan `shared_preferences`.
///
/// Hanya diperuntukkan bagi tampilan offline UI profil secara cepat.
/// Format penyimpanan berupa string JSON dengan atribut:
/// `user_id`, `display_name`, `email`, dan `updated_at`.
class ProfileCacheService {
  ProfileCacheService({this.preferences});

  SharedPreferences? preferences;

  static const String keyProfileCache = 'cached_user_profile';

  Future<SharedPreferences> _getPrefs() async {
    return preferences ??= await SharedPreferences.getInstance();
  }

  /// Menyimpan cache profil non-sensitif dalam bentuk JSON string.
  Future<void> saveProfile(User user) async {
    final prefs = await _getPrefs();
    final data = {
      'user_id': user.userId,
      'display_name': user.displayName,
      'email': user.email,
      'updated_at': (user.updatedAt ?? DateTime.now()).toIso8601String(),
    };
    await prefs.setString(keyProfileCache, jsonEncode(data));
  }

  /// Mengambil cache profil dari SharedPreferences.
  Future<User?> getProfile() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(keyProfileCache);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return User(
        userId: decoded['user_id'] as String? ?? '',
        displayName: decoded['display_name'] as String? ?? '',
        email: decoded['email'] as String? ?? '',
        updatedAt: decoded['updated_at'] != null
            ? DateTime.tryParse(decoded['updated_at'] as String)
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Menghapus cache profil saat logout.
  Future<void> clearProfile() async {
    final prefs = await _getPrefs();
    await prefs.remove(keyProfileCache);
  }
}
