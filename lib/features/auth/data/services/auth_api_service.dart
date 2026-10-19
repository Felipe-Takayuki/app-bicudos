import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/auth_user.dart';

class AuthApiService {
  final ApiClient _apiClient;

  AuthApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  ApiClient get apiClient => _apiClient;

  Future<AuthUser> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiConstants.loginEndpoint,
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
      includeAuth: false,
    );

    final data = response['data'];
    final userMap = data['user'] as Map<String, dynamic>;
    final tokens = data['tokens'] as Map<String, dynamic>;

    final accessToken = tokens['accessToken'] as String;
    final refreshToken = tokens['refreshToken'] as String?;

    final authUser = AuthUser.fromMap(
      userMap,
      token: accessToken,
      refreshToken: refreshToken,
    );

    await _saveSession(authUser);
    _apiClient.setToken(accessToken);

    return authUser;
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    String role = 'OPERATOR',
  }) async {
    final response = await _apiClient.post(
      ApiConstants.registerEndpoint,
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': role,
      },
      includeAuth: false,
    );

    final data = response['data'];
    final userMap = data['user'] as Map<String, dynamic>;
    final tokens = data['tokens'] as Map<String, dynamic>;

    final accessToken = tokens['accessToken'] as String;
    final refreshToken = tokens['refreshToken'] as String?;

    final authUser = AuthUser.fromMap(
      userMap,
      token: accessToken,
      refreshToken: refreshToken,
    );

    await _saveSession(authUser);
    _apiClient.setToken(accessToken);

    return authUser;
  }

  Future<AuthUser?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(ApiConstants.userKey);
    final token = prefs.getString(ApiConstants.tokenKey);

    if (userJson != null && token != null && token.isNotEmpty) {
      _apiClient.setToken(token);
      return AuthUser.fromJson(userJson);
    }
    return null;
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(ApiConstants.refreshTokenKey);
      if (refreshToken != null) {
        await _apiClient.post(
          '/auth/logout',
          body: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Ignora falhas de rede no logout
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(ApiConstants.tokenKey);
      await prefs.remove(ApiConstants.refreshTokenKey);
      await prefs.remove(ApiConstants.userKey);
      _apiClient.setToken(null);
    }
  }

  Future<void> _saveSession(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.tokenKey, user.accessToken);
    if (user.refreshToken != null) {
      await prefs.setString(ApiConstants.refreshTokenKey, user.refreshToken!);
    }
    await prefs.setString(ApiConstants.userKey, user.toJson());
  }
}
