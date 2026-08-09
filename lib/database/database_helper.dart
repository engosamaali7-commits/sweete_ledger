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
      version: 2,  // ← غيّر الإصدار إلى 2
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,  // ← أضف هذا
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // جدول المحافظ
    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // جدول السجلات اليومية
    await db.execute('''
      CREATE TABLE daily_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        business_date TEXT NOT NULL UNIQUE,
        status TEXT DEFAULT 'open',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        closed_at TEXT
      )
    ''');

    // جدول العمليات - مع custom_name
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        daily_record_id INTEGER NOT NULL,
        wallet_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        custom_name TEXT,
        amount REAL NOT NULL,
        note TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (daily_record_id) REFERENCES daily_records(id),
        FOREIGN KEY (wallet_id) REFERENCES wallets(id)
      )
    ''');

    // إضافة محافظ افتراضية
    await db.insert('wallets', {'name': 'محفظة ١'});
    await db.insert('wallets', {'name': 'محفظة ٢'});
    await db.insert('wallets', {'name': 'محفظة ٣'});
  }

  // ============ UPGRADE للإصدار 2 ============
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // إضافة عمود custom_name إذا كان غير موجود
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN custom_name TEXT');
      } catch (e) {
        // العمود موجود مسبقاً
      }
    }
  }

  // ============ DAILY RECORDS ============

  Future<int> createDailyRecordIfNotExists(String date) async {
    final db = await database;

    final existing = await db.query(
      'daily_records',
      where: 'business_date = ?',
      whereArgs: [date],
    );

    if (existing.isEmpty) {
      return await db.insert('daily_records', {
        'business_date': date,
        'status': 'open',
      });
    }

    return existing.first['id'] as int;
  }

  Future<int?> getTodayRecordId() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final db = await database;

    final result = await db.query(
      'daily_records',
      where: 'business_date = ?',
      whereArgs: [today],
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    return null;
  }

  // ============ WALLETS ============

  Future<List<Map<String, dynamic>>> getActiveWallets() async {
    final db = await database;
    return await db.query(
      'wallets',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
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
    return await db.update(
      'wallets',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleWalletStatus(int id, bool isActive) async {
    final db = await database;
    return await db.update(
      'wallets',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteWallet(int id) async {
    final db = await database;
    final transactions = await db.query(
      'transactions',
      where: 'wallet_id = ?',
      whereArgs: [id],
    );

    if (transactions.isNotEmpty) {
      throw Exception('لا يمكن حذف محفظة لها عمليات مسجلة. يمكنك تعطيلها بدلاً من ذلك.');
    }

    return await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  // ============ TRANSACTIONS ============

  Future<int> addTransaction({
    required int dailyRecordId,
    required int walletId,
    required String category,
    String? customName,     // ← أضف هذا
    required double amount,
    String? note,
  }) async {
    final db = await database;
    return await db.insert('transactions', {
      'daily_record_id': dailyRecordId,
      'wallet_id': walletId,
      'category': category,
      'custom_name': customName,  // ← أضف هذا
      'amount': amount,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> updateTransaction({
    required int id,
    required int walletId,
    required String category,
    String? customName,     // ← أضف هذا
    required double amount,
    String? note,
  }) async {
    final db = await database;
    return await db.update(
      'transactions',
      {
        'wallet_id': walletId,
        'category': category,
        'custom_name': customName,  // ← أضف هذا
        'amount': amount,
        'note': note,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
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

  // ============ STATISTICS ============

  Future<Map<String, dynamic>> getDailyStatistics(String date) async {
    final db = await database;

    // الإحصائيات العامة
    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(t.amount), 0) as total,
        COALESCE(SUM(CASE WHEN t.category = 'sambousa' THEN t.amount ELSE 0 END), 0) as sambousa,
        COALESCE(SUM(CASE WHEN t.category = 'sweets' THEN t.amount ELSE 0 END), 0) as sweets,
        COALESCE(SUM(CASE WHEN t.category = 'custom' THEN t.amount ELSE 0 END), 0) as custom_total,
        COUNT(t.id) as count
      FROM daily_records d
      LEFT JOIN transactions t ON d.id = t.daily_record_id
      WHERE d.business_date = ?
    ''', [date]);

    // إحصائيات العمليات المخصصة مجمعة حسب الاسم
    final customStats = await db.rawQuery('''
      SELECT 
        t.custom_name,
        COALESCE(SUM(t.amount), 0) as total,
        COUNT(t.id) as count
      FROM transactions t
      INNER JOIN daily_records d ON t.daily_record_id = d.id
      WHERE d.business_date = ? AND t.category = 'custom' AND t.custom_name IS NOT NULL
      GROUP BY t.custom_name
      ORDER BY total DESC
    ''', [date]);

    if (result.isNotEmpty) {
      final data = result.first;
      data['custom_stats'] = customStats;
      return data;
    }
    return {'total': 0, 'sambousa': 0, 'sweets': 0, 'custom_total': 0, 'count': 0, 'custom_stats': []};
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
        COALESCE(SUM(CASE WHEN t.category = 'sweets' THEN t.amount ELSE 0 END), 0) as sweets,
        COALESCE(SUM(CASE WHEN t.category = 'custom' THEN t.amount ELSE 0 END), 0) as custom_total
      FROM wallets w
      INNER JOIN daily_records d ON d.business_date = ?
      LEFT JOIN transactions t ON t.wallet_id = w.id AND t.daily_record_id = d.id
      GROUP BY w.id, w.name
      ORDER BY total DESC
    ''', [date]);
  }

  // ============ BACKUP ============

  Future<String> getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, 'sweets_ledger.db');
  }
}