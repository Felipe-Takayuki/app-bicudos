import '../config/app_config.dart';

class ApiConstants {
  /// Retorna a URL base padrão de acordo com a plataforma em execução e o .env
  static String get defaultBaseUrl => AppConfig.defaultApiBaseUrl;

  // Endpoints de Autenticação
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String meEndpoint = '/auth/me';
  static const String refreshTokenEndpoint = '/auth/refresh-token';
  static const String changePasswordEndpoint = '/auth/change-password';

  // Endpoints de Registros de Pragas
  static const String pestRecordsEndpoint = '/pest-records';
  static const String syncEndpoint = '/pest-records/sync';
  static const String nearbyEndpoint = '/pest-records/nearby';
  static const String exportGeoJsonEndpoint = '/pest-records/export/geojson';
  static const String exportCsvEndpoint = '/pest-records/export/csv';

  // Endpoints de Estatísticas
  static const String statsOverviewEndpoint = '/statistics/overview';

  // Chaves de armazenamento local (SharedPreferences)
  static const String tokenKey = 'agro_auth_token';
  static const String refreshTokenKey = 'agro_refresh_token';
  static const String userKey = 'agro_current_user';
  static const String customBaseUrlKey = 'agro_custom_base_url';
  static const String lastSyncKey = 'agro_last_sync_timestamp';

  // Configurações de rede
  static Duration get connectTimeout => AppConfig.apiConnectTimeout;
}
