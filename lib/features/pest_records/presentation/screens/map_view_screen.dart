import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/pest_record.dart';
import '../providers/pest_records_provider.dart';
import 'add_edit_record_screen.dart';
import 'record_detail_screen.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  final PestRecord? initialSelectedRecord;

  const MapViewScreen({super.key, this.initialSelectedRecord});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  final MapController _mapController = MapController();
  PestRecord? _selectedRecord;
  bool _showProportionalCircles = true;

  @override
  void initState() {
    super.initState();
    _selectedRecord = widget.initialSelectedRecord;
  }

  void _fitAllMarkers(List<PestRecord> records) {
    if (records.isEmpty) return;
    if (records.length == 1) {
      _mapController.move(
        LatLng(records.first.latitude, records.first.longitude),
        16.0,
      );
      return;
    }

    double minLat = records.first.latitude;
    double maxLat = records.first.latitude;
    double minLng = records.first.longitude;
    double maxLng = records.first.longitude;

    for (final r in records) {
      if (r.latitude < minLat) minLat = r.latitude;
      if (r.latitude > maxLat) maxLat = r.latitude;
      if (r.longitude < minLng) minLng = r.longitude;
      if (r.longitude > maxLng) maxLng = r.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(filteredPestRecordsProvider);
    final pointNumbers = ref.watch(recordPointNumbersProvider);

    LatLng initialCenter = LatLng(AppConfig.mapDefaultLat, AppConfig.mapDefaultLng);
    if (_selectedRecord != null) {
      initialCenter = LatLng(_selectedRecord!.latitude, _selectedRecord!.longitude);
    } else if (records.isNotEmpty) {
      initialCenter = LatLng(records.first.latitude, records.first.longitude);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Infestação'),
        actions: [
          IconButton(
            tooltip: 'Ajustar zoom para todos os pontos',
            icon: const Icon(Icons.crop_free),
            onPressed: () => _fitAllMarkers(records),
          ),
          IconButton(
            tooltip: _showProportionalCircles
                ? 'Ocultar círculos proporcionais'
                : 'Mostrar círculos proporcionais',
            icon: Icon(
              _showProportionalCircles
                  ? Icons.blur_circular
                  : Icons.radio_button_unchecked,
            ),
            onPressed: () {
              setState(() {
                _showProportionalCircles = !_showProportionalCircles;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: records.isNotEmpty ? AppConfig.mapDefaultZoom : (AppConfig.mapDefaultZoom - 5.0).clamp(1.0, 18.0),
              maxZoom: AppConfig.mapMaxZoom,
              onTap: (tapPosition, point) {
                if (_selectedRecord != null) {
                  setState(() => _selectedRecord = null);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: AppConfig.mapTileUrl,
                userAgentPackageName: AppConfig.mapUserAgent,
                maxZoom: AppConfig.mapMaxZoom,
              ),

              // Proportional Circles Layer (scaled by pest quantity)
              if (_showProportionalCircles)
                CircleLayer(
                  circles: records.map((r) {
                    final color = AppColors.getSeverityColor(r.quantity);
                    final radius = (10.0 + (r.quantity * 0.8)).clamp(12.0, 45.0);

                    return CircleMarker(
                      point: LatLng(r.latitude, r.longitude),
                      color: color.withValues(alpha: 0.35),
                      borderColor: color,
                      borderStrokeWidth: 2,
                      radius: radius,
                      useRadiusInMeter: false,
                    );
                  }).toList(),
                ),

              // Marker Layer with point number and insect count badge
              MarkerLayer(
                markers: records.map((r) {
                  final isSelected = _selectedRecord?.id == r.id;
                  final severityColor = AppColors.getSeverityColor(r.quantity);
                  final pointNum = pointNumbers[r.id];

                  return Marker(
                    point: LatLng(r.latitude, r.longitude),
                    width: isSelected ? 50 : 38,
                    height: isSelected ? 50 : 38,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRecord = r;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: severityColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: isSelected ? 8 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (pointNum != null)
                                Text(
                                  'P$pointNum',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontSize: isSelected ? 11 : 9,
                                    fontWeight: FontWeight.w600,
                                    height: 1.0,
                                  ),
                                ),
                              Text(
                                '${r.quantity}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSelected ? 13 : 11,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Map Legend Overlay
          PositionTileLegend(
            totalPoints: records.length,
            showCircles: _showProportionalCircles,
          ),

          // Selected Point Floating Card
          if (_selectedRecord != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _buildSelectedRecordCard(
                _selectedRecord!,
                pointNumbers[_selectedRecord!.id],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'map_add_btn',
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditRecordScreen(),
            ),
          );
          if (result == true) {
            ref.read(pestRecordsProvider.notifier).loadRecords();
          }
        },
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Novo Ponto'),
      ),
    );
  }

  Widget _buildSelectedRecordCard(PestRecord record, int? pointNumber) {
    final severityColor = AppColors.getSeverityColor(record.quantity);

    final titleText = pointNumber != null ? 'Ponto $pointNumber' : record.pestName;
    final subtitleText = pointNumber != null
        ? '${record.pestName} • ${record.formattedDate}'
        : record.formattedDate;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.bug_report, color: severityColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitleText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${record.quantity} un',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _selectedRecord = null),
                ),
              ],
            ),
            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Obs: ${record.notes}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Ver Detalhes'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecordDetailScreen(
                          record: record,
                          pointNumber: pointNumber,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PositionTileLegend extends StatelessWidget {
  final int totalPoints;
  final bool showCircles;

  const PositionTileLegend({
    super.key,
    required this.totalPoints,
    required this.showCircles,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Legenda ($totalPoints pontos)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            _buildLegendItem(AppColors.severityLow, '1 - 5 (Baixa)'),
            _buildLegendItem(AppColors.severityMedium, '6 - 15 (Média)'),
            _buildLegendItem(AppColors.severityHigh, '16 - 30 (Alta)'),
            _buildLegendItem(AppColors.severityCritical, '> 30 (Crítica)'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
