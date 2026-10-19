import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  final dynamic details;

  ApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.details,
  });
  @override
  String toString() {
    if (details != null && details is List && (details as List).isNotEmpty) {
      final issues = (details as List).map((d) {
        if (d is Map && d.containsKey('message')) {
          final path = d['path'] != null && d['path'].toString().isNotEmpty ? '[${d['path']}]: ' : '';
          return '$path${d['message']}';
        }
        return d.toString();
      }).join('; ');
      return '$message ($issues)';
    }
    return message;
  }
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _httpClient;
  String? _cachedToken;
  String? _cachedBaseUrl;

  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  Future<String> get baseUrl async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    final prefs = await SharedPreferences.getInstance();
    _cachedBaseUrl = prefs.getString(ApiConstants.customBaseUrlKey) ?? ApiConstants.defaultBaseUrl;
    return _cachedBaseUrl!;
  }

  Future<void> setCustomBaseUrl(String newUrl) async {
    _cachedBaseUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.customBaseUrlKey, newUrl);
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(ApiConstants.tokenKey);
    return _cachedToken;
  }

  void setToken(String? token) {
    _cachedToken = token;
  }

  Future<Map<String, String>> _buildHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams, bool includeAuth = true}) async {
    try {
      final base = await baseUrl;
      var uri = Uri.parse('$base$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = await _buildHeaders(includeAuth: includeAuth);
      final response = await _httpClient.get(uri, headers: headers).timeout(ApiConstants.connectTimeout);

      return _processResponse(response);
    } on SocketException {
      throw NetworkException('Não foi possível conectar ao servidor. Verifique sua conexão ou se o servidor está ativo.');
    } on TimeoutException {
      throw NetworkException('Tempo de conexão esgotado ao contatar o servidor.');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw NetworkException('Erro de comunicação: $e');
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body, bool includeAuth = true}) async {
    try {
      final base = await baseUrl;
      final uri = Uri.parse('$base$endpoint');
      final headers = await _buildHeaders(includeAuth: includeAuth);

      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.connectTimeout);

      return _processResponse(response);
    } on SocketException {
      throw NetworkException('Não foi possível conectar ao servidor. Verifique sua conexão ou se o servidor está ativo.');
    } on TimeoutException {
      throw NetworkException('Tempo de conexão esgotado ao contatar o servidor.');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw NetworkException('Erro de comunicação: $e');
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body, bool includeAuth = true}) async {
    try {
      final base = await baseUrl;
      final uri = Uri.parse('$base$endpoint');
      final headers = await _buildHeaders(includeAuth: includeAuth);

      final response = await _httpClient
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.connectTimeout);

      return _processResponse(response);
    } on SocketException {
      throw NetworkException('Não foi possível conectar ao servidor. Verifique sua conexão ou se o servidor está ativo.');
    } on TimeoutException {
      throw NetworkException('Tempo de conexão esgotado.');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw NetworkException('Erro de comunicação: $e');
    }
  }

  Future<dynamic> delete(String endpoint, {bool includeAuth = true}) async {
    try {
      final base = await baseUrl;
      final uri = Uri.parse('$base$endpoint');
      final headers = await _buildHeaders(includeAuth: includeAuth);

      final response = await _httpClient.delete(uri, headers: headers).timeout(ApiConstants.connectTimeout);
      return _processResponse(response);
    } on SocketException {
      throw NetworkException('Não foi possível conectar ao servidor.');
    } on TimeoutException {
      throw NetworkException('Tempo de conexão esgotado.');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw NetworkException('Erro de comunicação: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic decoded;
    try {
      if (response.body.isNotEmpty) {
        decoded = jsonDecode(response.body);
      }
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    String message = 'Ocorreu um erro na requisição (${response.statusCode})';
    String? code;
    dynamic details;

    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('error') && decoded['error'] is Map<String, dynamic>) {
        final err = decoded['error'] as Map<String, dynamic>;
        message = err['message'] ?? message;
        code = err['code'];
        details = err['details'];
      } else if (decoded.containsKey('message')) {
        message = decoded['message'];
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      code: code,
      details: details,
    );
  }
}
