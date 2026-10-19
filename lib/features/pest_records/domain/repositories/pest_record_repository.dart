import '../models/pest_record.dart';

abstract class PestRecordRepository {
  Future<List<PestRecord>> getRecords();
  Future<PestRecord?> getRecordById(String id);
  Future<void> addRecord(PestRecord record);
  Future<void> updateRecord(PestRecord record);
  Future<void> deleteRecord(String id);
  Future<void> clearAllRecords();
}
