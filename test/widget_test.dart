import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoramento/core/services/export_service.dart';
import 'package:monitoramento/features/pest_records/domain/models/pest_record.dart';
import 'package:monitoramento/features/pest_records/presentation/widgets/pest_card.dart';

void main() {
  test('QGIS QML Style Generator creates valid style XML', () {
    final qml = ExportService.instance.generateQmlStyle();
    expect(qml.contains('<qgis'), isTrue);
    expect(qml.contains('attr="quantidade"'), isTrue);
    expect(qml.contains('graduatedSymbol'), isTrue);
    expect(qml.contains('label="Baixa (1 a 5)"'), isTrue);
  });

  test('KML export creates valid KML with points and styles', () {
    final records = [
      PestRecord(
        id: 'kml-1',
        pestName: 'Lagarta-do-cartucho',
        quantity: 15,
        latitude: -15.79,
        longitude: -47.88,
      ),
    ];
    final kml = ExportService.instance.generateKml(records);
    expect(kml.contains('<kml xmlns="http://www.opengis.net/kml/2.2">'), isTrue);
    expect(kml.contains('<Placemark>'), isTrue);
    expect(kml.contains('<coordinates>-47.88,-15.79,0.0</coordinates>'), isTrue);
  });

  testWidgets('PestCard renders Ponto X as title and pestName as subtitle when pointNumber is provided', (tester) async {
    final record = PestRecord(
      id: 'p-1',
      pestName: 'Bicudo',
      quantity: 5,
      latitude: -22.109,
      longitude: -50.195,
      createdAt: DateTime(2026, 9, 8, 17, 20),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PestCard(
            record: record,
            pointNumber: 1,
          ),
        ),
      ),
    );

    expect(find.text('Ponto 1'), findsOneWidget);
    expect(find.textContaining('Bicudo'), findsOneWidget);
  });

  testWidgets('PestCard renders pestName as title when pointNumber is null', (tester) async {
    final record = PestRecord(
      id: 'p-2',
      pestName: 'Lagarta',
      quantity: 2,
      latitude: -22.109,
      longitude: -50.195,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PestCard(
            record: record,
          ),
        ),
      ),
    );

    expect(find.text('Lagarta'), findsOneWidget);
  });
}
