import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/sqlite_pest_record_repository.dart';
import '../../domain/models/pest_record.dart';
import '../../domain/models/pest_statistics.dart';
import '../../domain/repositories/pest_record_repository.dart';

/// Repository Provider
final pestRepositoryProvider = Provider<PestRecordRepository>((ref) {
  return SqlitePestRecordRepository();
});

/// Filter State
class PestFilterState {
  final String searchQuery;
  final String? selectedPest;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? minQuantity;

  const PestFilterState({
    this.searchQuery = '',
    this.selectedPest,
    this.startDate,
    this.endDate,
    this.minQuantity,
  });

  PestFilterState copyWith({
    String? searchQuery,
    String? Function()? selectedPest,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    int? Function()? minQuantity,
  }) {
    return PestFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedPest: selectedPest != null ? selectedPest() : this.selectedPest,
      startDate: startDate != null ? startDate() : this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      minQuantity: minQuantity != null ? minQuantity() : this.minQuantity,
    );
  }

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedPest != null ||
      startDate != null ||
      endDate != null ||
      minQuantity != null;
}

class PestFilterNotifier extends StateNotifier<PestFilterState> {
  PestFilterNotifier() : super(const PestFilterState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setPest(String? pest) {
    state = state.copyWith(selectedPest: () => pest);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDate: () => start,
      endDate: () => end,
    );
  }

  void setMinQuantity(int? min) {
    state = state.copyWith(minQuantity: () => min);
  }

  void resetFilters() {
    state = const PestFilterState();
  }
}

final pestFilterProvider =
    StateNotifierProvider<PestFilterNotifier, PestFilterState>((ref) {
  return PestFilterNotifier();
});

/// Records State Notifier
class PestRecordsNotifier extends StateNotifier<AsyncValue<List<PestRecord>>> {
  final PestRecordRepository _repository;

  PestRecordsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadRecords();
  }

  Future<void> loadRecords() async {
    state = const AsyncValue.loading();
    try {
      final records = await _repository.getRecords();
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRecord(PestRecord record) async {
    try {
      await _repository.addRecord(record);
      await loadRecords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateRecord(PestRecord record) async {
    try {
      await _repository.updateRecord(record);
      await loadRecords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      await _repository.deleteRecord(id);
      await loadRecords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearAll() async {
    try {
      await _repository.clearAllRecords();
      await loadRecords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Renomeia todos os registros existentes para "Ponto 1", "Ponto 2", "Ponto 3"... em ordem cronológica de coleta
  Future<int> renumberAllRecordsAsPoints() async {
    final currentList = state.value;
    if (currentList == null || currentList.isEmpty) return 0;

    try {
      final sorted = List<PestRecord>.from(currentList)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      int count = 0;
      for (int i = 0; i < sorted.length; i++) {
        final updated = sorted[i].copyWith(
          pestName: 'Ponto ${i + 1}',
          updatedAt: DateTime.now(),
        );
        await _repository.updateRecord(updated);
        count++;
      }
      await loadRecords();
      return count;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return 0;
    }
  }
}

final pestRecordsProvider =
    StateNotifierProvider<PestRecordsNotifier, AsyncValue<List<PestRecord>>>((ref) {
  final repo = ref.watch(pestRepositoryProvider);
  return PestRecordsNotifier(repo);
});

/// Provedor que mapeia cada ID de registro para o número sequencial do ponto (Ponto 1, Ponto 2, ...)
/// ordenado cronologicamente pela data de coleta (createdAt ASC).
final recordPointNumbersProvider = Provider<Map<String, int>>((ref) {
  final recordsAsync = ref.watch(pestRecordsProvider);
  final records = recordsAsync.value ?? [];
  if (records.isEmpty) return const {};

  final sorted = List<PestRecord>.from(records)
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  final map = <String, int>{};
  for (int i = 0; i < sorted.length; i++) {
    map[sorted[i].id] = i + 1;
  }
  return map;
});

/// Filtered Records Provider
final filteredPestRecordsProvider = Provider<List<PestRecord>>((ref) {
  final recordsAsync = ref.watch(pestRecordsProvider);
  final filter = ref.watch(pestFilterProvider);
  final pointNumbers = ref.watch(recordPointNumbersProvider);

  return recordsAsync.when(
    data: (records) {
      return records.where((r) {
        // Search query filter (matches point number, pest name, notes)
        if (filter.searchQuery.isNotEmpty) {
          final query = filter.searchQuery.toLowerCase().trim();
          final pointNum = pointNumbers[r.id];
          final matchPoint = pointNum != null &&
              ('ponto $pointNum'.contains(query) ||
               'p$pointNum' == query ||
               pointNum.toString() == query);
          final matchName = r.pestName.toLowerCase().contains(query);
          final matchNotes = r.notes.toLowerCase().contains(query);
          if (!matchName && !matchNotes && !matchPoint) {
            return false;
          }
        }

        // Pest name filter
        if (filter.selectedPest != null && r.pestName != filter.selectedPest) {
          return false;
        }

        // Min quantity filter
        if (filter.minQuantity != null && r.quantity < filter.minQuantity!) {
          return false;
        }

        // Date range filter
        if (filter.startDate != null) {
          final start = DateTime(
            filter.startDate!.year,
            filter.startDate!.month,
            filter.startDate!.day,
          );
          if (r.createdAt.isBefore(start)) return false;
        }

        if (filter.endDate != null) {
          final end = DateTime(
            filter.endDate!.year,
            filter.endDate!.month,
            filter.endDate!.day,
            23,
            59,
            59,
          );
          if (r.createdAt.isAfter(end)) return false;
        }

        return true;
      }).toList();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Aggregated Statistics Provider
final pestStatisticsProvider = Provider<PestStatistics>((ref) {
  final records = ref.watch(filteredPestRecordsProvider);
  return PestStatistics.fromRecords(records);
});
