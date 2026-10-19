import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

/// Gerenciador centralizado de configurações e variáveis de ambiente da aplicação.
///
/// Lê as configurações do arquivo `.env` carregado via `flutter_dotenv` e
/// disponibiliza getters tipados com fallbacks seguros para todos os módulos
/// (API backend, mapas/QGIS, GPS, SQLite offline-first e ambiente).
class AppConfig {
  static bool _isLoaded = false;

  /// Inicializa o carregamento das variáveis do arquivo .env.
  /// Se o arquivo não existir ou falhar ao carregar (ex.: em testes unitários),
  /// o sistema continuará operando normalmente com os valores padrão de fallback.
  static Future<void> initialize({String fileName = '.env'}) async {
    try {
      await dotenv.load(fileName: fileName, isOptional: true);
      _isLoaded = true;
      if (kDebugMode && enableLogging) {
        debugPrint('[AppConfig] Configurações de ambiente ($environment) carregadas via $fileName.');
      }
    } catch (e) {
      _isLoaded = false;
      if (kDebugMode) {
        debugPrint('[AppConfig] Aviso: Não foi possível carregar "$fileName". Usando valores padrão ($e).');
      }
    }
  }

  /// Carrega as variáveis diretamente de uma String (útil para testes unitários ou injeção dinâmica)
  @visibleForTesting
  static void initializeFromString(String envString) {
    dotenv.loadFromString(envString: envString);
    _isLoaded = true;
  }

  // ---------------------------------------------------------------------------
  // HELPERS INTERNOS PARA PARSING COM FALLBACK SEGURO
  // ---------------------------------------------------------------------------
  static String _getString(String key, String fallback) {
    if (_isLoaded && dotenv.isInitialized) {
      final value = dotenv.maybeGet(key);
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  static int _getInt(String key, int fallback) {
    final str = _getString(key, '');
    if (str.isNotEmpty) {
      return int.tryParse(str) ?? fallback;
    }
    return fallback;
  }

  static double _getDouble(String key, double fallback) {
    final str = _getString(key, '');
    if (str.isNotEmpty) {
      return double.tryParse(str) ?? fallback;
    }
    return fallback;
  }

  static bool _getBool(String key, bool fallback) {
    final str = _getString(key, '').toLowerCase();
    if (str == 'true' || str == '1' || str == 'yes' || str == 'sim') return true;
    if (str == 'false' || str == '0' || str == 'no' || str == 'nao' || str == 'não') return false;
    return fallback;
  }

  // ---------------------------------------------------------------------------
  // 1. APLICAÇÃO E AMBIENTE
  // ---------------------------------------------------------------------------
  /// Ambiente atual de execução (development, staging, production)
  static String get environment => _getString('APP_ENV', 'development');

  /// Indica se está em ambiente de produção
  static bool get isProduction => environment.toLowerCase() == 'production';

  /// Indica se está em ambiente de desenvolvimento
  static bool get isDevelopment => environment.toLowerCase() == 'development';

  /// Nome de exibição da aplicação
  static String get appName => _getString('APP_NAME', 'Monitoramento de Pragas & QGIS');

  /// Se logs detalhados de rede/serviços devem ser impressos no console
  static bool get enableLogging => _getBool('ENABLE_LOGGING', true);

  // ---------------------------------------------------------------------------
  // 2. API BACKEND & SINCRONIZAÇÃO
  // ---------------------------------------------------------------------------
  /// URL base configurada para iOS, Web, macOS, Linux, Windows e Produção
  static String get apiBaseUrl => _getString('API_BASE_URL', 'https://bicudos.fdevs.io/api/v1');

  /// URL base configurada para o Android
  static String get apiBaseUrlAndroid => _getString('API_BASE_URL_ANDROID', 'https://bicudos.fdevs.io/api/v1');

  /// Retorna a URL base padrão adequada para a plataforma em execução
  static String get defaultApiBaseUrl {
    if (kIsWeb) {
      return apiBaseUrl;
    } else if (Platform.isAndroid) {
      return apiBaseUrlAndroid;
    } else {
      return apiBaseUrl;
    }
  }

  /// Timeout em segundos para conexões e requisições HTTP
  static int get apiTimeoutSeconds => _getInt('API_TIMEOUT_SECONDS', 15);

  /// Duração do timeout da API
  static Duration get apiConnectTimeout => Duration(seconds: apiTimeoutSeconds);

  /// Quantidade máxima de registros sincronizados por lote (batch sync)
  static int get syncBatchSize => _getInt('API_SYNC_BATCH_SIZE', 200);

  // ---------------------------------------------------------------------------
  // 3. CARTOGRAFIA, MAPA & QGIS
  // ---------------------------------------------------------------------------
  /// Template de URL dos tiles do mapa (ex: OpenStreetMap ou tiles customizados)
  static String get mapTileUrl => _getString(
        'MAP_TILE_URL',
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );

  /// Identificador User-Agent para requisições de tiles
  static String get mapUserAgent => _getString('MAP_USER_AGENT', 'com.agro.monitoramento');

  /// Latitude padrão para o centro da fazenda/talhão quando não houver GPS
  static double get mapDefaultLat => _getDouble('MAP_DEFAULT_LAT', -15.7942);

  /// Longitude padrão para o centro da fazenda/talhão quando não houver GPS
  static double get mapDefaultLng => _getDouble('MAP_DEFAULT_LNG', -47.8822);

  /// Nível inicial de zoom do mapa
  static double get mapDefaultZoom => _getDouble('MAP_DEFAULT_ZOOM', 15.0);

  /// Nível máximo de zoom permitido no mapa
  static double get mapMaxZoom => _getDouble('MAP_MAX_ZOOM', 19.0);

  // ---------------------------------------------------------------------------
  // 4. GPS & GEOLOCALIZAÇÃO
  // ---------------------------------------------------------------------------
  /// Tempo limite para fixação de sinal GPS de alta precisão em segundos
  static int get gpsTimeoutSeconds => _getInt('GPS_TIMEOUT_SECONDS', 12);

  /// Duração do timeout do GPS
  static Duration get gpsTimeoutDuration => Duration(seconds: gpsTimeoutSeconds);

  /// String descritiva da precisão do GPS configurada
  static String get gpsDesiredAccuracy => _getString('GPS_DESIRED_ACCURACY', 'high');

  /// Objeto LocationAccuracy correspondente à configuração
  static LocationAccuracy get gpsAccuracy {
    switch (gpsDesiredAccuracy.toLowerCase()) {
      case 'lowest':
        return LocationAccuracy.lowest;
      case 'low':
        return LocationAccuracy.low;
      case 'medium':
        return LocationAccuracy.medium;
      case 'best':
        return LocationAccuracy.best;
      case 'bestfornavigation':
        return LocationAccuracy.bestForNavigation;
      case 'high':
      default:
        return LocationAccuracy.high;
    }
  }

  // ---------------------------------------------------------------------------
  // 5. BANCO DE DADOS LOCAL (SQLITE) & OFFLINE-FIRST
  // ---------------------------------------------------------------------------
  /// Nome do arquivo de banco de dados SQLite local
  static String get databaseName => _getString('DATABASE_NAME', 'monitoramento_pragas.db');

  /// Se a sincronização automática ao iniciar está ativa
  static bool get autoSyncEnabled => _getBool('SYNC_AUTO_ENABLED', false);
}
