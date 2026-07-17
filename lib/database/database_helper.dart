import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = await getDatabasesPath();
    String dbPath = join(path, AppConstants.dbName);

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        dueDate INTEGER NOT NULL,
        priority INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL
      )
    ''');
  }

  static Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert(AppConstants.tableName, task.toMap());
  }

  static Future<void> restoreTask(Task task) async {
    await insertTask(task);
  }

  static Future<List<Task>> getTasks() async {
    final db = await database;
    final maps = await db.query(AppConstants.tableName);
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  static Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      AppConstants.tableName,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  static Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
