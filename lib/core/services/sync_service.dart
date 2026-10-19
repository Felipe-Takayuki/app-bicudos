import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../constants/api_constants.dart';
import '../database/db_helper.dart';
import '../network/api_client.dart';
import '../../features/pest_records/domain/models/pest_record.dart';

class SyncResult {
  final bool success;
  final int syncedToServer;
  final int receivedFromServer;
  final String message;
  final DateTime syncTime;

  SyncResult({
    required this.success,
    required this.syncedToServer,
    required this.receivedFromServer,
    required this.message,
    required this.syncTime,
  });
}

class SyncService {
  final ApiClient _apiClient;
  final DBHelper _dbHelper;

  SyncService({ApiClient? apiClient, DBHelper? dbHelper})
      : _apiClient = apiClient ?? ApiClient(),
        _dbHelper = dbHelper ?? DBHelper.instance;

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(ApiConstants.lastSyncKey);
    return iso != null ? DateTime.tryParse(iso) : null;
  }

  Future<SyncResult> syncAll() async {
    final now = DateTime.now();

    // 1. Obter todos os registros locais do SQLite
    final localRecords = await _dbHelper.getAllRecords();

    int sentCount = 0;
    int receivedCount = 0;

    // 2. Se houver registros locais, enviar para o backend via sincronização em lote
    if (localRecords.isNotEmpty) {
      const uuid = Uuid();
      final payload = {
        'records': localRecords.map((r) {
          final isUuid = Uuid.isValidUUID(fromString: r.id);
          final validId = isUuid ? r.id : uuid.v4();
          final validPestName = r.pestName.trim().length >= 2 ? r.pestName.trim() : 'Bicudo';
          final validQuantity = r.quantity < 1 ? 1 : r.quantity;
          final validAccuracy = (r.accuracy != null && r.accuracy! >= 0) ? r.accuracy : null;
          final validNotes = r.notes.length > 1000 ? r.notes.substring(0, 1000) : r.notes;

          return {
            'id': validId,
            'pestName': validPestName,
            'quantity': validQuantity,
            'crop': '',
            'plot': '',
            'growthStage': '',
            'notes': validNotes,
            'latitude': r.latitude,
            'longitude': r.longitude,
            'altitude': r.altitude,
            'accuracy': validAccuracy,
            'imagePath': r.imagePath,
            'createdAt': r.createdAt.toUtc().toIso8601String(),
          };
        }).toList(),
      };

      final response = await _apiClient.post(ApiConstants.syncEndpoint, body: payload);
      sentCount = response['data']?['syncedCount'] ?? localRecords.length;
    }

    // 3. Buscar os registros mais recentes da nuvem para atualizar o SQLite local
    final remoteResponse = await _apiClient.get(
      ApiConstants.pestRecordsEndpoint,
      queryParams: {'limit': AppConfig.syncBatchSize.toString()},
    );

    if (remoteResponse != null && remoteResponse['data'] is List) {
      final List remoteList = remoteResponse['data'];

      for (final item in remoteList) {
        final pest = PestRecord(
          id: item['id'],
          pestName: item['pestName'] ?? item['pest_name'] ?? 'Não identificada',
          quantity: item['quantity'] ?? 1,
          notes: item['notes'] ?? '',
          latitude: (item['latitude'] as num).toDouble(),
          longitude: (item['longitude'] as num).toDouble(),
          altitude: item['altitude'] != null ? (item['altitude'] as num).toDouble() : null,
          accuracy: item['accuracy'] != null ? (item['accuracy'] as num).toDouble() : null,
          imagePath: item['imagePath'] ?? item['image_path'],
          createdAt: DateTime.tryParse(item['createdAt'] ?? item['created_at'] ?? '') ?? now,
          updatedAt: DateTime.tryParse(item['updatedAt'] ?? item['updated_at'] ?? '') ?? now,
        );

        // Atualiza ou insere no SQLite local
        await _dbHelper.insert(pest);
        receivedCount++;
      }
    }

    // 4. Salvar data/hora da sincronização
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.lastSyncKey, now.toIso8601String());

    return SyncResult(
      success: true,
      syncedToServer: sentCount,
      receivedFromServer: receivedCount,
      message: 'Sincronização concluída com sucesso!',
      syncTime: now,
    );
  }
}
