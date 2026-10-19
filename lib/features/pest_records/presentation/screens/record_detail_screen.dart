import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/pest_record.dart';
import '../providers/pest_records_provider.dart';
import 'add_edit_record_screen.dart';

class RecordDetailScreen extends ConsumerWidget {
  final PestRecord record;
  final int? pointNumber;

  const RecordDetailScreen({
    super.key,
    required this.record,
    this.pointNumber,
  });

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Registro'),
        content: Text('Tem certeza que deseja excluir o registro de "${record.pestName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(pestRecordsProvider.notifier).deleteRecord(record.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registro excluído com sucesso.')),
                );
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final severityColor = AppColors.getSeverityColor(record.quantity);
    final severityLabel = AppColors.getSeverityLabel(record.quantity);

    final titleText = pointNumber != null ? 'Ponto $pointNumber' : record.pestName;
    final subtitleText = pointNumber != null
        ? 'Praga: ${record.pestName} • Severidade $severityLabel'
        : 'Severidade $severityLabel';

    return Scaffold(
      appBar: AppBar(
        title: Text(pointNumber != null ? 'Detalhes do Ponto $pointNumber' : 'Detalhes do Ponto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Registro',
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditRecordScreen(recordToEdit: record),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir Registro',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card with Pest & Quantity
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [severityColor.withValues(alpha: 0.9), severityColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: severityColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bug_report, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitleText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${record.quantity}',
                        style: TextStyle(
                          color: severityColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'insetos',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mini Map Preview
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(record.latitude, record.longitude),
                initialZoom: 16,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConfig.mapTileUrl,
                  userAgentPackageName: AppConfig.mapUserAgent,
                  maxZoom: AppConfig.mapMaxZoom,
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(record.latitude, record.longitude),
                      color: severityColor.withValues(alpha: 0.4),
                      borderColor: severityColor,
                      borderStrokeWidth: 2,
                      radius: (10.0 + (record.quantity * 0.8)).clamp(15.0, 40.0),
                      useRadiusInMeter: false,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(record.latitude, record.longitude),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Point Information Attributes
          _buildInfoCard(
            title: 'Informações do Registro',
            icon: Icons.event_note,
            rows: [
              if (pointNumber != null)
                _buildInfoRow('Identificação', 'Ponto $pointNumber'),
              _buildInfoRow('Praga Monitorada', record.pestName),
              _buildInfoRow('Data e Hora da Coleta', record.formattedDate),
            ],
          ),
          const SizedBox(height: 16),

          // Spatial & GPS Attributes
          _buildInfoCard(
            title: 'Dados Geoespaciais (QGIS / SIG)',
            icon: Icons.map,
            rows: [
              _buildInfoRow('Latitude', '${record.latitude.toStringAsFixed(6)}°'),
              _buildInfoRow('Longitude', '${record.longitude.toStringAsFixed(6)}°'),
              if (record.altitude != null)
                _buildInfoRow('Altitude', '${record.altitude!.toStringAsFixed(1)} m'),
              if (record.accuracy != null)
                _buildInfoRow('Precisão GPS', '±${record.accuracy!.toStringAsFixed(1)} m'),
              _buildInfoRow(
                'WKT Geom',
                record.wktPoint,
                onCopy: () => _copyToClipboard(
                  context,
                  record.wktPoint,
                  'WKT copiado para a área de transferência!',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notes
          if (record.notes.isNotEmpty)
            _buildInfoCard(
              title: 'Observações de Campo',
              icon: Icons.notes,
              rows: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    record.notes,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {VoidCallback? onCopy}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onCopy != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Icon(Icons.copy, size: 16, color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
