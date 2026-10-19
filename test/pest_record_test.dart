import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoramento/core/constants/app_colors.dart';
import 'package:monitoramento/core/services/export_service.dart';
import 'package:monitoramento/features/pest_records/domain/models/pest_record.dart';
import 'package:monitoramento/features/pest_records/domain/models/pest_statistics.dart';

void main() {
  group('PestRecord Domain Model Tests', () {
    test('should correctly convert to SQLite map and back', () {
      final record = PestRecord(
        id: 'test-123',
        pestName: 'Lagarta-do-cartucho',
        quantity: 25,
        notes: 'Foco na bordadura',
        latitude: -15.7942,
        longitude: -47.8822,
        altitude: 1050.0,
        accuracy: 3.5,
      );

      final map = record.toMap();
      final fromMap = PestRecord.fromMap(map);

      expect(fromMap.id, 'test-123');
      expect(fromMap.pestName, 'Lagarta-do-cartucho');
      expect(fromMap.quantity, 25);
      expect(fromMap.latitude, -15.7942);
      expect(fromMap.longitude, -47.8822);
      expect(fromMap.accuracy, 3.5);
      expect(fromMap.wktPoint, 'POINT(-47.8822 -15.7942)');
    });

    test('should generate valid RFC 7946 GeoJSON Feature for QGIS', () {
      final record = PestRecord(
        id: 'rec-01',
        pestName: 'Percevejo-marrom',
        quantity: 12,
        notes: '2 por metro no pano',
        latitude: -12.3456,
        longitude: -55.6789,
        altitude: 400.0,
        accuracy: 4.2,
      );

      final feature = record.toGeoJsonFeature();
      expect(feature['type'], 'Feature');
      expect(feature['id'], 'rec-01');

      final geom = feature['geometry'] as Map<String, dynamic>;
      expect(geom['type'], 'Point');
      // GeoJSON standard: [longitude, latitude, altitude]
      expect(geom['coordinates'], [-55.6789, -12.3456, 400.0]);

      final props = feature['properties'] as Map<String, dynamic>;
      expect(props['praga'], 'Percevejo-marrom');
      expect(props['quantidade'], 12);
      expect(props['latitude'], -12.3456);
      expect(props['longitude'], -55.6789);
    });

    test('should generate full GeoJSON FeatureCollection with CRS header for QGIS', () {
      final records = [
        PestRecord(
          id: '1',
          pestName: 'Lagarta',
          quantity: 10,
          latitude: -15.0,
          longitude: -47.0,
        ),
        PestRecord(
          id: '2',
          pestName: 'Percevejo',
          quantity: 20,
          latitude: -15.1,
          longitude: -47.1,
        ),
      ];

      final geoJsonStr = ExportService.instance.generateGeoJson(records);
      final decoded = jsonDecode(geoJsonStr) as Map<String, dynamic>;

      expect(decoded['type'], 'FeatureCollection');
      expect(decoded['name'], 'monitoramento_pragas');
      expect(decoded['crs'], isNotNull);
      expect(decoded['metadata']['autor'], 'felipe-takayuki');
      expect((decoded['features'] as List).length, 2);
    });

    test('should generate CSV with coordinates and WKT geometry', () {
      final records = [
        PestRecord(
          id: '1',
          pestName: 'Mosca-branca',
          quantity: 35,
          latitude: -15.1234,
          longitude: -47.5678,
        ),
      ];

      final csvStr = ExportService.instance.generateCsv(records);
      expect(csvStr.contains('id,praga,quantidade'), isTrue);
      expect(csvStr.contains('Mosca-branca'), isTrue);
      expect(csvStr.contains('35'), isTrue);
      expect(csvStr.contains('-15.1234'), isTrue);
      expect(csvStr.contains('-47.5678'), isTrue);
      expect(csvStr.contains('POINT(-47.5678 -15.1234)'), isTrue);
    });

    test('should calculate aggregated pest statistics correctly', () {
      final records = [
        PestRecord(
          id: '1',
          pestName: 'Spodoptera',
          quantity: 10,
          latitude: 0,
          longitude: 0,
        ),
        PestRecord(
          id: '2',
          pestName: 'Spodoptera',
          quantity: 30,
          latitude: 0,
          longitude: 0,
        ),
        PestRecord(
          id: '3',
          pestName: 'Percevejo',
          quantity: 20,
          latitude: 0,
          longitude: 0,
        ),
      ];

      final stats = PestStatistics.fromRecords(records);
      expect(stats.totalRecords, 3);
      expect(stats.totalInsects, 60);
      expect(stats.averagePerPoint, 20.0);
      expect(stats.maxInsectsInSinglePoint, 30);
      expect(stats.topPest?.key, 'Spodoptera');
      expect(stats.topPest?.value, 40);
    });

    test('should assign correct severity levels and colors', () {
      expect(AppColors.getSeverityLabel(3), 'Baixa');
      expect(AppColors.getSeverityLabel(10), 'Média');
      expect(AppColors.getSeverityLabel(25), 'Alta');
      expect(AppColors.getSeverityLabel(50), 'Crítica');

      expect(AppColors.getSeverityColor(3), AppColors.severityLow);
      expect(AppColors.getSeverityColor(10), AppColors.severityMedium);
      expect(AppColors.getSeverityColor(25), AppColors.severityHigh);
      expect(AppColors.getSeverityColor(50), AppColors.severityCritical);
    });
  });
}
