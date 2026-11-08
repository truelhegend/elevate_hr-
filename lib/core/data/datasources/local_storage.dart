import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class LocalStorage {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  static const String _onboardingKey = 'onboarding_complete';
  static const String _userKey = 'current_user';
  static const String _biometricSecretKey = 'biometric_secret';

  LocalStorage(this._prefs, this._secureStorage);

  // Onboarding
  bool get isOnboardingComplete => _prefs.getBool(_onboardingKey) ?? false;
  Future<void> setOnboardingComplete() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  // User
  User? get currentUser {
    final userData = _prefs.getString(_userKey);
    if (userData == null) return null;
    try {
      return User.fromJson(jsonDecode(userData));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(User user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> clearUser() async {
    await _prefs.remove(_userKey);
    await _secureStorage.delete(key: _biometricSecretKey);
  }

  // Biometric enrollment secret, issued by the server at password login.
  Future<void> saveBiometricSecret(String secret) =>
      _secureStorage.write(key: _biometricSecretKey, value: secret);

  Future<String?> get biometricSecret => _secureStorage.read(key: _biometricSecretKey);

  // Clear all
  Future<void> clearAll() async {
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }
}
