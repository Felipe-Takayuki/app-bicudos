import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/pest_records/domain/models/pest_record.dart';

enum ExportFormat {
  geoJson,
  csv,
  kml,
  qgisPackage, // GeoJSON + QML style bundled together
}

class ExportResult {
  final bool isSuccess;
  final String? filePath;
  final String? message;

  ExportResult.success(this.filePath, [this.message]) : isSuccess = true;
  ExportResult.failure(this.message)
      : isSuccess = false,
        filePath = null;
}

class ExportService {
  static final ExportService _instance = ExportService._internal();
  static ExportService get instance => _instance;
  ExportService._internal();

  /// Converts pest records into a standard RFC 7946 GeoJSON string
  String generateGeoJson(List<PestRecord> records) {
    final features = records.map((r) => r.toGeoJsonFeature()).toList();

    final geoJsonMap = {
      'type': 'FeatureCollection',
      'name': 'monitoramento_pragas',
      'crs': {
        'type': 'name',
        'properties': {
          'name': 'urn:ogc:def:crs:OGC:1.3:CRS84',
        },
      },
      'metadata': {
        'autor': 'felipe-takayuki',
        'sistema': 'Monitoramento de Pragas',
        'gerado_em': DateTime.now().toIso8601String(),
        'total_registros': records.length,
      },
      'features': features,
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(geoJsonMap);
  }

  /// Converts pest records into CSV format with WKT geometry column
  String generateCsv(List<PestRecord> records) {
    final List<List<dynamic>> rows = [
      PestRecord.csvHeaders,
      ...records.map((r) => r.toCsvRow()),
    ];

    const encoder = CsvEncoder(
      fieldDelimiter: ',',
      lineDelimiter: '\n',
    );
    return encoder.convert(rows);
  }

  /// Generates a KML file with styled placemarks for Google Earth & QGIS
  String generateKml(List<PestRecord> records) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('  <Document>');
    buffer.writeln('    <name>Monitoramento de Pragas</name>');
    buffer.writeln('    <description>Pontos de coleta de monitoramento de pragas no campo</description>');
    buffer.writeln('    <author><name>felipe-takayuki</name></author>');

    // Styles by severity
    buffer.writeln('''
    <Style id="pest_low">
      <IconStyle>
        <scale>1.1</scale>
        <Icon><href>http://maps.google.com/mapfiles/ms/icons/green-dot.png</href></Icon>
      </IconStyle>
    </Style>
    <Style id="pest_medium">
      <IconStyle>
        <scale>1.3</scale>
        <Icon><href>http://maps.google.com/mapfiles/ms/icons/yellow-dot.png</href></Icon>
      </IconStyle>
    </Style>
    <Style id="pest_high">
      <IconStyle>
        <scale>1.5</scale>
        <Icon><href>http://maps.google.com/mapfiles/ms/icons/orange-dot.png</href></Icon>
      </IconStyle>
    </Style>
    <Style id="pest_critical">
      <IconStyle>
        <scale>1.8</scale>
        <Icon><href>http://maps.google.com/mapfiles/ms/icons/red-dot.png</href></Icon>
      </IconStyle>
    </Style>
''');

    for (final r in records) {
      String styleId = 'pest_low';
      if (r.quantity > 30) {
        styleId = 'pest_critical';
      } else if (r.quantity > 15) {
        styleId = 'pest_high';
      } else if (r.quantity > 5) {
        styleId = 'pest_medium';
      }

      buffer.writeln('    <Placemark>');
      buffer.writeln('      <name>${r.pestName} (Qtd: ${r.quantity})</name>');
      buffer.writeln('      <styleUrl>#$styleId</styleUrl>');
      buffer.writeln('      <description><![CDATA[');
      buffer.writeln('        <h3>${r.pestName}</h3>');
      buffer.writeln('        <p><b>Quantidade:</b> ${r.quantity} insetos</p>');
      buffer.writeln('        <p><b>Data:</b> ${r.formattedDate}</p>');
      if (r.notes.isNotEmpty) {
        buffer.writeln('        <p><b>Observações:</b> ${r.notes}</p>');
      }
      buffer.writeln('        <p><b>Coordenadas:</b> Lat ${r.latitude.toStringAsFixed(6)}, Lng ${r.longitude.toStringAsFixed(6)}</p>');
      buffer.writeln('      ]]></description>');
      buffer.writeln('      <Point>');
      buffer.writeln('        <coordinates>${r.longitude},${r.latitude},${r.altitude ?? 0.0}</coordinates>');
      buffer.writeln('      </Point>');
      buffer.writeln('    </Placemark>');
    }

    buffer.writeln('  </Document>');
    buffer.writeln('</kml>');

    return buffer.toString();
  }

  /// Generates a QGIS Layer Style (.qml) XML for graduated circle symbology
  String generateQmlStyle() {
    return '''<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="3.28.0" styleCategories="AllStyleCategories" minScale="1e+08" maxScale="0">
  <renderer-v2 attr="quantidade" type="graduatedSymbol" symbollevels="0" graduatedMethod="GraduatedSize">
    <ranges>
      <range render="true" symbol="0" lower="0" upper="5" label="Baixa (1 a 5)"/>
      <range render="true" symbol="1" lower="6" upper="15" label="Média (6 a 15)"/>
      <range render="true" symbol="2" lower="16" upper="30" label="Alta (16 a 30)"/>
      <range render="true" symbol="3" lower="31" upper="9999" label="Crítica (&gt; 30)"/>
    </ranges>
    <symbols>
      <symbol clip_to_extent="1" force_rhr="0" type="marker" name="0" alpha="1">
        <layer class="SimpleMarker" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option name="color" type="QString" value="76,175,80,210"/>
            <Option name="outline_color" type="QString" value="27,94,32,255"/>
            <Option name="outline_width" type="QString" value="0.4"/>
            <Option name="size" type="QString" value="3.5"/>
            <Option name="size_unit" type="QString" value="MM"/>
          </Option>
        </layer>
      </symbol>
      <symbol clip_to_extent="1" force_rhr="0" type="marker" name="1" alpha="1">
        <layer class="SimpleMarker" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option name="color" type="QString" value="255,179,0,220"/>
            <Option name="outline_color" type="QString" value="191,135,0,255"/>
            <Option name="outline_width" type="QString" value="0.4"/>
            <Option name="size" type="QString" value="5.5"/>
            <Option name="size_unit" type="QString" value="MM"/>
          </Option>
        </layer>
      </symbol>
      <symbol clip_to_extent="1" force_rhr="0" type="marker" name="2" alpha="1">
        <layer class="SimpleMarker" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option name="color" type="QString" value="255,87,34,220"/>
            <Option name="outline_color" type="QString" value="191,54,12,255"/>
            <Option name="outline_width" type="QString" value="0.4"/>
            <Option name="size" type="QString" value="7.5"/>
            <Option name="size_unit" type="QString" value="MM"/>
          </Option>
        </layer>
      </symbol>
      <symbol clip_to_extent="1" force_rhr="0" type="marker" name="3" alpha="1">
        <layer class="SimpleMarker" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option name="color" type="QString" value="211,47,47,230"/>
            <Option name="outline_color" type="QString" value="183,28,28,255"/>
            <Option name="outline_width" type="QString" value="0.4"/>
            <Option name="size" type="QString" value="9.5"/>
            <Option name="size_unit" type="QString" value="MM"/>
          </Option>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
  <labeling type="simple">
    <settings calloutType="simple">
      <text-style fontLetterSpacing="0" textColor="0,0,0,255" fontSize="9" fontWeight="75" fontFamily="Arial">
        <text-buffer bufferSize="1.2" bufferColor="255,255,255,255" bufferDraw="1"/>
      </text-style>
      <rule-description description=""/>
      <text-format addDirectionSymbol="0" multilineAlign="3"/>
      <placement placement="1" dist="2.0"/>
      <data-defined field="quantidade" expression="&quot;praga&quot; + '\n(' + &quot;quantidade&quot; + ')'"/>
    </settings>
  </labeling>
</qgis>
''';
  }

  /// Get plain text content for the selected format
  String getContentForFormat(List<PestRecord> records, ExportFormat format) {
    switch (format) {
      case ExportFormat.geoJson:
      case ExportFormat.qgisPackage:
        return generateGeoJson(records);
      case ExportFormat.csv:
        return generateCsv(records);
      case ExportFormat.kml:
        return generateKml(records);
    }
  }

  /// Export records to device temporary storage and share via standard OS share dialog
  Future<ExportResult> exportAndShare({
    required List<PestRecord> records,
    required ExportFormat format,
    String? customPrefix,
  }) async {
    if (records.isEmpty) {
      return ExportResult.failure('Nenhum registro disponível para exportação.');
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final prefix = customPrefix ?? 'monitoramento_pragas';

      List<XFile> filesToShare = [];

      switch (format) {
        case ExportFormat.geoJson:
          final content = generateGeoJson(records);
          final filePath = '${tempDir.path}/${prefix}_$timestamp.geojson';
          final file = File(filePath);
          await file.writeAsString(content);
          filesToShare.add(XFile(
            filePath,
            mimeType: 'application/json',
            name: '${prefix}_$timestamp.geojson',
          ));
          break;

        case ExportFormat.csv:
          final content = generateCsv(records);
          final filePath = '${tempDir.path}/${prefix}_$timestamp.csv';
          final file = File(filePath);
          await file.writeAsString(content);
          filesToShare.add(XFile(
            filePath,
            mimeType: 'text/csv',
            name: '${prefix}_$timestamp.csv',
          ));
          break;

        case ExportFormat.kml:
          final content = generateKml(records);
          final filePath = '${tempDir.path}/${prefix}_$timestamp.kml';
          final file = File(filePath);
          await file.writeAsString(content);
          filesToShare.add(XFile(
            filePath,
            mimeType: 'application/vnd.google-earth.kml+xml',
            name: '${prefix}_$timestamp.kml',
          ));
          break;

        case ExportFormat.qgisPackage:
          // Generate GeoJSON + QML style together!
          final geoJsonContent = generateGeoJson(records);
          final geoJsonPath = '${tempDir.path}/${prefix}_$timestamp.geojson';
          await File(geoJsonPath).writeAsString(geoJsonContent);
          filesToShare.add(XFile(
            geoJsonPath,
            mimeType: 'application/json',
            name: '${prefix}_$timestamp.geojson',
          ));

          final qmlContent = generateQmlStyle();
          final qmlPath = '${tempDir.path}/${prefix}_$timestamp.qml';
          await File(qmlPath).writeAsString(qmlContent);
          filesToShare.add(XFile(
            qmlPath,
            mimeType: 'application/xml',
            name: '${prefix}_$timestamp.qml',
          ));
          break;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: filesToShare,
          text: 'Exportação de ${records.length} registros de monitoramento para QGIS.',
          subject: 'Dados Monitoramento de Pragas (QGIS)',
        ),
      );

      return ExportResult.success(
        filesToShare.first.path,
        'Exportação pronta para envio (${records.length} pontos)!',
      );
    } catch (e) {
      return ExportResult.failure('Erro ao exportar: $e');
    }
  }

  /// Save records locally to app documents directory
  Future<ExportResult> saveToDevice({
    required List<PestRecord> records,
    required ExportFormat format,
    String? customPrefix,
  }) async {
    if (records.isEmpty) {
      return ExportResult.failure('Nenhum registro disponível para salvar.');
    }

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final prefix = customPrefix ?? 'monitoramento_pragas';
      String savedPath = '';

      switch (format) {
        case ExportFormat.geoJson:
          final content = generateGeoJson(records);
          savedPath = '${docDir.path}/${prefix}_$timestamp.geojson';
          await File(savedPath).writeAsString(content);
          break;

        case ExportFormat.csv:
          final content = generateCsv(records);
          savedPath = '${docDir.path}/${prefix}_$timestamp.csv';
          await File(savedPath).writeAsString(content);
          break;

        case ExportFormat.kml:
          final content = generateKml(records);
          savedPath = '${docDir.path}/${prefix}_$timestamp.kml';
          await File(savedPath).writeAsString(content);
          break;

        case ExportFormat.qgisPackage:
          final geoJsonContent = generateGeoJson(records);
          savedPath = '${docDir.path}/${prefix}_$timestamp.geojson';
          await File(savedPath).writeAsString(geoJsonContent);

          final qmlContent = generateQmlStyle();
          final qmlPath = '${docDir.path}/${prefix}_$timestamp.qml';
          await File(qmlPath).writeAsString(qmlContent);
          break;
      }

      return ExportResult.success(
        savedPath,
        'Salvo em: $savedPath',
      );
    } catch (e) {
      return ExportResult.failure('Erro ao salvar no dispositivo: $e');
    }
  }
}
