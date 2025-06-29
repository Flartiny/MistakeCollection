import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/mistake.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mistakes.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE mistakes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        subject TEXT NOT NULL,
        questionType TEXT NOT NULL,
        knowledgePoint TEXT NOT NULL,
        imagePath TEXT,
        createdAt INTEGER NOT NULL,
        lastReviewed INTEGER NOT NULL,
        reviewCount INTEGER DEFAULT 0,
        difficulty REAL DEFAULT 0.5,
        isCompleted INTEGER DEFAULT 0
      )
    ''');
  }

  Future<int> insertMistake(Mistake mistake) async {
    final db = await database;
    return await db.insert('mistakes', mistake.toMap());
  }

  Future<List<Mistake>> getAllMistakes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('mistakes');
    return List.generate(maps.length, (i) => Mistake.fromMap(maps[i]));
  }

  Future<List<Mistake>> getMistakesBySubject(String subject) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mistakes',
      where: 'subject = ?',
      whereArgs: [subject],
    );
    return List.generate(maps.length, (i) => Mistake.fromMap(maps[i]));
  }

  Future<List<Mistake>> getMistakesForReview() async {
    final db = await database;
    final now = DateTime.now();
    final List<Map<String, dynamic>> maps = await db.query(
      'mistakes',
      where: 'isCompleted = 0',
      orderBy: 'lastReviewed ASC',
    );
    return List.generate(maps.length, (i) => Mistake.fromMap(maps[i]));
  }

  Future<int> updateMistake(Mistake mistake) async {
    final db = await database;
    return await db.update(
      'mistakes',
      mistake.toMap(),
      where: 'id = ?',
      whereArgs: [mistake.id],
    );
  }

  Future<int> deleteMistake(int id) async {
    final db = await database;
    return await db.delete(
      'mistakes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
} 