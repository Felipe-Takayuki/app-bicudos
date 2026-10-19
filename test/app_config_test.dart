import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:monitoramento/core/config/app_config.dart';
import 'package:monitoramento/core/constants/api_constants.dart';

void main() {
  group('AppConfig Tests', () {
    test('should provide robust default fallback values before initialization', () {
      expect(AppConfig.appName, isNotEmpty);
      expect(AppConfig.apiBaseUrl, isNotEmpty);
      expect(AppConfig.apiBaseUrlAndroid, isNotEmpty);
      expect(AppConfig.defaultApiBaseUrl, isNotEmpty);
      expect(AppConfig.apiTimeoutSeconds, greaterThan(0));
      expect(AppConfig.apiConnectTimeout, equals(const Duration(seconds: 15)));
      expect(AppConfig.syncBatchSize, equals(200));

      expect(AppConfig.mapTileUrl, contains('{z}/{x}/{y}'));
      expect(AppConfig.mapUserAgent, isNotEmpty);
      expect(AppConfig.mapDefaultLat, closeTo(-15.7942, 0.001));
      expect(AppConfig.mapDefaultLng, closeTo(-47.8822, 0.001));
      expect(AppConfig.mapDefaultZoom, equals(15.0));
      expect(AppConfig.mapMaxZoom, equals(19.0));

      expect(AppConfig.gpsTimeoutSeconds, equals(12));
      expect(AppConfig.gpsTimeoutDuration, equals(const Duration(seconds: 12)));
      expect(AppConfig.gpsAccuracy, equals(LocationAccuracy.high));

      expect(AppConfig.databaseName, equals('monitoramento_pragas.db'));
      expect(AppConfig.autoSyncEnabled, isFalse);
      expect(AppConfig.environment, equals('development'));
      expect(AppConfig.isDevelopment, isTrue);
      expect(AppConfig.isProduction, isFalse);
    });

    test('ApiConstants should reflect AppConfig defaults', () {
      expect(ApiConstants.defaultBaseUrl, equals(AppConfig.defaultApiBaseUrl));
      expect(ApiConstants.connectTimeout, equals(AppConfig.apiConnectTimeout));
    });

    test('should correctly parse loaded environment variables via AppConfig', () {
      AppConfig.initializeFromString('''
APP_ENV=production
APP_NAME=AgroGeo Monitor Pro
ENABLE_LOGGING=false
API_BASE_URL=https://api.fazenda.com.br/v1
API_BASE_URL_ANDROID=https://api.fazenda.com.br/v1
API_TIMEOUT_SECONDS=30
API_SYNC_BATCH_SIZE=500
MAP_TILE_URL=https://tile.opentopomap.org/{z}/{x}/{y}.png
MAP_USER_AGENT=com.fazenda.monitor
MAP_DEFAULT_LAT=-22.1234
MAP_DEFAULT_LNG=-51.5678
MAP_DEFAULT_ZOOM=14.0
MAP_MAX_ZOOM=18.0
GPS_TIMEOUT_SECONDS=20
GPS_DESIRED_ACCURACY=best
DATABASE_NAME=fazenda_pragas.db
SYNC_AUTO_ENABLED=true
''');

      // Now AppConfig getters should reflect the loaded values
      expect(AppConfig.environment, equals('production'));
      expect(AppConfig.isProduction, isTrue);
      expect(AppConfig.isDevelopment, isFalse);
      expect(AppConfig.appName, equals('AgroGeo Monitor Pro'));
      expect(AppConfig.enableLogging, isFalse);
      expect(AppConfig.apiBaseUrl, equals('https://api.fazenda.com.br/v1'));
      expect(AppConfig.apiTimeoutSeconds, equals(30));
      expect(AppConfig.apiConnectTimeout, equals(const Duration(seconds: 30)));
      expect(AppConfig.syncBatchSize, equals(500));
      expect(AppConfig.mapTileUrl, equals('https://tile.opentopomap.org/{z}/{x}/{y}.png'));
      expect(AppConfig.mapUserAgent, equals('com.fazenda.monitor'));
      expect(AppConfig.mapDefaultLat, closeTo(-22.1234, 0.001));
      expect(AppConfig.mapDefaultLng, closeTo(-51.5678, 0.001));
      expect(AppConfig.mapDefaultZoom, equals(14.0));
      expect(AppConfig.mapMaxZoom, equals(18.0));
      expect(AppConfig.gpsTimeoutSeconds, equals(20));
      expect(AppConfig.gpsTimeoutDuration, equals(const Duration(seconds: 20)));
      expect(AppConfig.gpsAccuracy, equals(LocationAccuracy.best));
      expect(AppConfig.databaseName, equals('fazenda_pragas.db'));
      expect(AppConfig.autoSyncEnabled, isTrue);
    });
  });
}
