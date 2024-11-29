import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  static LocalDatabase get instance => _instance;

  Database? _database;

  LocalDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'credit_cards.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE credit_cards(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cardNumber TEXT NOT NULL,
            company TEXT NOT NULL,
            dueDate TEXT NOT NULL,
            currentDueAmount REAL NOT NULL,
            totalDueAmount REAL NOT NULL,
            synced INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<int> insertCard(Map<String, dynamic> cardData) async {
    final db = await database;
    return await db.insert(
      'credit_cards',
      cardData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> fetchUnsyncedCards() async {
    final db = await database;
    return await db.query(
      'credit_cards',
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markAsSynced(int id) async {
    final db = await database;
    await db.update(
      'credit_cards',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> fetchAllCards() async {
    final db = await database;
    return await db.query('credit_cards');
  }

  Future<void> deleteCard(int id) async {
    final db = await database;
    await db.delete(
      'credit_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('credit_cards');
  }
}
