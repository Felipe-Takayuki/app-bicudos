import '../../../../core/database/db_helper.dart';
import '../../domain/models/pest_record.dart';
import '../../domain/repositories/pest_record_repository.dart';

class SqlitePestRecordRepository implements PestRecordRepository {
  final DBHelper _dbHelper;

  SqlitePestRecordRepository({DBHelper? dbHelper})
      : _dbHelper = dbHelper ?? DBHelper.instance;

  @override
  Future<List<PestRecord>> getRecords() async {
    return await _dbHelper.getAllRecords();
  }

  @override
  Future<PestRecord?> getRecordById(String id) async {
    return await _dbHelper.getRecordById(id);
  }

  @override
  Future<void> addRecord(PestRecord record) async {
    await _dbHelper.insert(record);
  }

  @override
  Future<void> updateRecord(PestRecord record) async {
    await _dbHelper.update(record);
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _dbHelper.delete(id);
  }

  @override
  Future<void> clearAllRecords() async {
    await _dbHelper.deleteAll();
  }
}
