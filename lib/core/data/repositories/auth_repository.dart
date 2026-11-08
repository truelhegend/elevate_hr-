import '../datasources/api_service.dart';
import '../datasources/local_storage.dart';
import '../models/user.dart';

class AuthRepository {
  final ApiService api;
  final LocalStorage storage;

  AuthRepository({required this.api, required this.storage});

  User? _currentUser;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  Future<User> login(String email, String password) async {
    final response = await api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final data = response.data['data'];
    if (data == null) throw Exception('Login failed');

    await api.setTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );

    final user = User.fromJson(data['user']);
    await storage.saveUser(user);
    final biometricSecret = data['biometricSecret'];
    if (biometricSecret is String && biometricSecret.isNotEmpty) {
      await storage.saveBiometricSecret(biometricSecret);
    }
    _currentUser = user;
    _isAuthenticated = true;
    return user;
  }

  Future<void> logout() async {
    try {
      await api.post('/auth/logout');
    } catch (_) {}
    await api.clearTokens();
    await storage.clearUser();
    _currentUser = null;
    _isAuthenticated = false;
  }

  Future<User> biometricLogin() async {
    final storedUser = storage.currentUser;
    if (storedUser == null) throw Exception('No stored user for biometric login');

    final secret = await storage.biometricSecret;
    if (secret == null || secret.isEmpty) {
      throw Exception('Biometric login is not set up. Sign in with your password first.');
    }

    final response = await api.post('/auth/biometric-login', data: {
      'userId': storedUser.id,
      'biometricSecret': secret,
    });

    final data = response.data['data'];
    if (data == null) throw Exception('Biometric login failed');

    await api.setTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );

    final user = User.fromJson(data['user']);
    await storage.saveUser(user);
    _currentUser = user;
    _isAuthenticated = true;
    return user;
  }

  Future<bool> checkAuthStatus() async {
    final hasToken = await api.hasToken;
    if (!hasToken) {
      _isAuthenticated = false;
      return false;
    }

    try {
      final response = await api.get('/employees/me');
      final userData = response.data['data'];
      if (userData != null) {
        _currentUser = User.fromJson(userData);
        await storage.saveUser(_currentUser!);
        _isAuthenticated = true;
        return true;
      }
    } catch (_) {
      await api.clearTokens();
      await storage.clearUser();
    }

    _isAuthenticated = false;
    return false;
  }

  Future<void> forgotPassword(String email) async {
    await api.post('/auth/forgot-password', data: {'email': email});
  }

  Future<User> googleLogin(String idToken) async {
    final response = await api.post('/auth/google', data: {
      'idToken': idToken,
    });

    final data = response.data['data'];
    if (data == null) throw Exception('Google login failed');

    await api.setTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );

    final user = User.fromJson(data['user']);
    await storage.saveUser(user);
    _currentUser = user;
    _isAuthenticated = true;
    return user;
  }

}
