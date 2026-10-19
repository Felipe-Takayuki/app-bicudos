import 'pest_record.dart';

class PestStatistics {
  final int totalRecords;
  final int totalInsects;
  final double averagePerPoint;
  final int maxInsectsInSinglePoint;
  final Map<String, int> pestsCountByName;

  const PestStatistics({
    required this.totalRecords,
    required this.totalInsects,
    required this.averagePerPoint,
    required this.maxInsectsInSinglePoint,
    required this.pestsCountByName,
  });

  factory PestStatistics.fromRecords(List<PestRecord> records) {
    if (records.isEmpty) {
      return const PestStatistics(
        totalRecords: 0,
        totalInsects: 0,
        averagePerPoint: 0.0,
        maxInsectsInSinglePoint: 0,
        pestsCountByName: {},
      );
    }

    int totalInsects = 0;
    int maxInsects = 0;
    final Map<String, int> byName = {};

    for (final record in records) {
      totalInsects += record.quantity;
      if (record.quantity > maxInsects) {
        maxInsects = record.quantity;
      }

      byName[record.pestName] = (byName[record.pestName] ?? 0) + record.quantity;
    }

    final average = totalInsects / records.length;

    return PestStatistics(
      totalRecords: records.length,
      totalInsects: totalInsects,
      averagePerPoint: average,
      maxInsectsInSinglePoint: maxInsects,
      pestsCountByName: byName,
    );
  }

  /// Returns the top pest name and count
  MapEntry<String, int>? get topPest {
    if (pestsCountByName.isEmpty) return null;
    final sorted = pestsCountByName.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first;
  }
}
