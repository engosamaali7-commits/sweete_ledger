import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'sweets_ledger.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        business_date TEXT NOT NULL UNIQUE,
        status TEXT DEFAULT 'open',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        closed_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        daily_record_id INTEGER NOT NULL,
        wallet_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (daily_record_id) REFERENCES daily_records(id),
        FOREIGN KEY (wallet_id) REFERENCES wallets(id)
      )
    ''');

    await db.insert('wallets', {'name': 'محفظة ١'});
    await db.insert('wallets', {'name': 'محفظة ٢'});
    await db.insert('wallets', {'name': 'محفظة ٣'});
  }

  Future<int> createDailyRecordIfNotExists(String date) async {
    final db = await database;
    final existing = await db.query('daily_records', where: 'business_date = ?', whereArgs: [date]);
    if (existing.isEmpty) {
      return await db.insert('daily_records', {'business_date': date, 'status': 'open'});
    }
    return existing.first['id'] as int;
  }

  Future<List<Map<String, dynamic>>> getActiveWallets() async {
    final db = await database;
    return await db.query('wallets', where: 'is_active = ?', whereArgs: [1], orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getAllWallets() async {
    final db = await database;
    return await db.query('wallets', orderBy: 'name ASC');
  }

  Future<int> addWallet(String name) async {
    final db = await database;
    return await db.insert('wallets', {'name': name});
  }

  Future<int> updateWallet(int id, String name) async {
    final db = await database;
    return await db.update('wallets', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleWalletStatus(int id, bool isActive) async {
    final db = await database;
    return await db.update('wallets', {'is_active': isActive ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteWallet(int id) async {
    final db = await database;
    final transactions = await db.query('transactions', where: 'wallet_id = ?', whereArgs: [id]);
    if (transactions.isNotEmpty) {
      throw Exception('لا يمكن حذف محفظة لها عمليات. يمكنك تعطيلها بدلاً من ذلك.');
    }
    return await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addTransaction({
    required int dailyRecordId,
    required int walletId,
    required String category,
    required double amount,
    String? note,
  }) async {
    final db = await database;
    return await db.insert('transactions', {
      'daily_record_id': dailyRecordId,
      'wallet_id': walletId,
      'category': category,
      'amount': amount,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getTodayTransactions() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final db = await database;
    return await db.rawQuery('''
      SELECT t.*, w.name as wallet_name, d.business_date
      FROM transactions t
      INNER JOIN daily_records d ON t.daily_record_id = d.id
      INNER JOIN wallets w ON t.wallet_id = w.id
      WHERE d.business_date = ?
      ORDER BY t.created_at DESC
    ''', [today]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getDailyStatistics(String date) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(t.amount), 0) as total,
        COALESCE(SUM(CASE WHEN t.category = 'sambousa' THEN t.amount ELSE 0 END), 0) as sambousa,
        COALESCE(SUM(CASE WHEN t.category = 'sweets' THEN t.amount ELSE 0 END), 0) as sweets,
        COUNT(t.id) as count
      FROM daily_records d
      LEFT JOIN transactions t ON d.id = t.daily_record_id
      WHERE d.business_date = ?
    ''', [date]);
    if (result.isNotEmpty) return result.first;
    return {'total': 0, 'sambousa': 0, 'sweets': 0, 'count': 0};
  }

  Future<List<Map<String, dynamic>>> getWalletStatistics(String date) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        w.id,
        w.name,
        COALESCE(SUM(t.amount), 0) as total,
        COUNT(t.id) as count,
        COALESCE(SUM(CASE WHEN t.category = 'sambousa' THEN t.amount ELSE 0 END), 0) as sambousa,
        COALESCE(SUM(CASE WHEN t.category = 'sweets' THEN t.amount ELSE 0 END), 0) as sweets
      FROM wallets w
      INNER JOIN daily_records d ON d.business_date = ?
      LEFT JOIN transactions t ON t.wallet_id = w.id AND t.daily_record_id = d.id
      GROUP BY w.id, w.name
      ORDER BY total DESC
    ''', [date]);
  }

  Future<String> getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, 'sweets_ledger.db');
  }
}