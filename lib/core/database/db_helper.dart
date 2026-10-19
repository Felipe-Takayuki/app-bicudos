import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../config/app_config.dart';
import '../../features/pest_records/domain/models/pest_record.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConfig.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pest_records (
        id TEXT PRIMARY KEY,
        pest_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        crop TEXT NOT NULL,
        plot TEXT NOT NULL,
        growth_stage TEXT NOT NULL,
        notes TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        altitude REAL,
        accuracy REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        image_path TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_pest_records_name ON pest_records(pest_name)');
    await db.execute('CREATE INDEX idx_pest_records_created_at ON pest_records(created_at)');
    await db.execute('CREATE INDEX idx_pest_records_plot ON pest_records(plot)');
  }

  Future<int> insert(PestRecord record) async {
    final db = await instance.database;
    return await db.insert(
      'pest_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PestRecord>> getAllRecords() async {
    final db = await instance.database;
    final result = await db.query(
      'pest_records',
      orderBy: 'created_at DESC',
    );
    return result.map((json) => PestRecord.fromMap(json)).toList();
  }

  Future<PestRecord?> getRecordById(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'pest_records',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return PestRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(PestRecord record) async {
    final db = await instance.database;
    return await db.update(
      'pest_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await instance.database;
    return await db.delete(
      'pest_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAll() async {
    final db = await instance.database;
    return await db.delete('pest_records');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
