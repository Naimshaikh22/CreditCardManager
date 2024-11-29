import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cards.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cardNumber TEXT,
        company TEXT,
        dueDate TEXT,
        currentDueAmount REAL,
        totalDueAmount REAL,
        synced INTEGER
      )
    ''');
  }

  Future<void> insertCard(Map<String, dynamic> cardData) async {
    final db = await database;
    await db.insert('cards', cardData);
  }

  Future<List<Map<String, dynamic>>> fetchUnsyncedCards() async {
    final db = await database;
    return await db.query('cards', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markAsSynced(int cardId) async {
    final db = await database;
    await db.update('cards', {'synced': 1}, where: 'id = ?', whereArgs: [cardId]);
  }

  Future<List<Map<String, dynamic>>> fetchAllCards() async {
    final db = await database;
    return await db.query('cards');
  }
}
