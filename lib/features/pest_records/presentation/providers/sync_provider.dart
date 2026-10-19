import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/sync_service.dart';
import 'pest_records_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncTime;
  final SyncResult? lastResult;
  final String? errorMessage;

  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncTime,
    this.lastResult,
    this.errorMessage,
  });

  bool get isSyncing => status == SyncStatus.syncing;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? Function()? lastSyncTime,
    SyncResult? Function()? lastResult,
    String? Function()? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncTime: lastSyncTime != null ? lastSyncTime() : this.lastSyncTime,
      lastResult: lastResult != null ? lastResult() : this.lastResult,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;
  final Ref _ref;

  SyncNotifier(this._syncService, this._ref) : super(const SyncState()) {
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final time = await _syncService.getLastSyncTime();
    if (time != null) {
      state = state.copyWith(lastSyncTime: () => time);
    }
  }

  Future<SyncResult?> sync() async {
    if (state.isSyncing) return null;

    state = state.copyWith(
      status: SyncStatus.syncing,
      errorMessage: () => null,
    );

    try {
      final result = await _syncService.syncAll();

      // Recarrega os registros locais para atualizar a tela principal com dados novos
      await _ref.read(pestRecordsProvider.notifier).loadRecords();

      state = state.copyWith(
        status: SyncStatus.success,
        lastSyncTime: () => result.syncTime,
        lastResult: () => result,
      );

      return result;
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: () => e.toString(),
      );
      return null;
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return SyncNotifier(syncService, ref);
});
