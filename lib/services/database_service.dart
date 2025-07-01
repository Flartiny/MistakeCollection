import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/mistake.dart';

/// DatabaseService：负责本地错题数据库的增删查改与初始化
class DatabaseService {
  static Database? _database;

  /// 获取数据库实例，若未初始化则自动创建
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库，指定数据库文件名和表结构
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mistakes.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  /// 创建错题表，包含内容、学科、题型、知识点、图片、时间、复习等字段
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

  /// 插入一条错题记录，返回自增id
  Future<int> insertMistake(Mistake mistake) async {
    final db = await database;
    return await db.insert('mistakes', mistake.toMap());
  }

  /// 获取所有错题，返回Mistake对象列表
  Future<List<Mistake>> getAllMistakes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('mistakes');
    return List.generate(maps.length, (i) => Mistake.fromMap(maps[i]));
  }

  /// 按学科筛选错题
  Future<List<Mistake>> getMistakesBySubject(String subject) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mistakes',
      where: 'subject = ?',
      whereArgs: [subject],
    );
    return List.generate(maps.length, (i) => Mistake.fromMap(maps[i]));
  }

  /// 获取待复习的错题（未完成，按上次复习时间升序）
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

  /// 更新错题信息
  Future<int> updateMistake(Mistake mistake) async {
    final db = await database;
    return await db.update(
      'mistakes',
      mistake.toMap(),
      where: 'id = ?',
      whereArgs: [mistake.id],
    );
  }

  /// 删除指定id的错题
  Future<int> deleteMistake(int id) async {
    final db = await database;
    return await db.delete(
      'mistakes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 关闭数据库连接
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
} 