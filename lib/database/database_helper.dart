import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static Database? _database;
  static const int _dbVersion = 3;

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
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// ✅ إغلاق قاعدة البيانات
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transaction_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_name TEXT DEFAULT 'category',
        is_active INTEGER DEFAULT 1,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.insert('transaction_categories', {'name': 'سمبوسة', 'icon_name': 'fastfood', 'sort_order': 1});
    await db.insert('transaction_categories', {'name': 'حلويات', 'icon_name': 'cake', 'sort_order': 2});

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
        is_archived INTEGER DEFAULT 0,
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
        custom_name TEXT,
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN custom_name TEXT');
      } catch (e) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE daily_records ADD COLUMN is_archived INTEGER DEFAULT 0');
      } catch (e) {}
    }
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transaction_categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon_name TEXT DEFAULT 'category',
          is_active INTEGER DEFAULT 1,
          sort_order INTEGER DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM transaction_categories')) ?? 0;
      if (count == 0) {
        await db.insert('transaction_categories', {'name': 'سمبوسة', 'icon_name': 'fastfood', 'sort_order': 1});
        await db.insert('transaction_categories', {'name': 'حلويات', 'icon_name': 'cake', 'sort_order': 2});
      }
    } catch (e) {}
  }

  // ============ TRANSACTION CATEGORIES ============

  Future<List<Map<String, dynamic>>> getActiveCategories() async {
    try {
      final db = await database;
      return await db.query(
        'transaction_categories',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'sort_order ASC',
      );
    } catch (e) {
      return [
        {'id': 1, 'name': 'سمبوسة', 'icon_name': 'fastfood', 'is_active': 1, 'sort_order': 1},
        {'id': 2, 'name': 'حلويات', 'icon_name': 'cake', 'is_active': 1, 'sort_order': 2},
      ];
    }
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      final db = await database;
      return await db.query('transaction_categories', orderBy: 'sort_order ASC');
    } catch (e) {
      return [
        {'id': 1, 'name': 'سمبوسة', 'icon_name': 'fastfood', 'is_active': 1, 'sort_order': 1},
        {'id': 2, 'name': 'حلويات', 'icon_name': 'cake', 'is_active': 1, 'sort_order': 2},
      ];
    }
  }

  Future<int> addCategory(String name, {String iconName = 'category'}) async {
    final db = await database;
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transaction_categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon_name TEXT DEFAULT 'category',
          is_active INTEGER DEFAULT 1,
          sort_order INTEGER DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    } catch (e) {}

    final maxOrder = Sqflite.firstIntValue(
        await db.rawQuery('SELECT MAX(sort_order) FROM transaction_categories')) ?? 0;
    return await db.insert('transaction_categories', {
      'name': name,
      'icon_name': iconName,
      'sort_order': maxOrder + 1,
    });
  }

  Future<int> updateCategory(int id, String name, {String? iconName}) async {
    final db = await database;
    final updates = <String, dynamic>{'name': name};
    if (iconName != null) updates['icon_name'] = iconName;
    return await db.update(
      'transaction_categories',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleCategoryStatus(int id, bool isActive) async {
    final db = await database;
    return await db.update(
      'transaction_categories',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.update(
      'transaction_categories',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
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
        'is_archived': 0,
      });
    }

    return existing.first['id'] as int;
  }

  Future<Map<String, dynamic>?> getDailyRecord(String date) async {
    final db = await database;
    final result = await db.query(
      'daily_records',
      where: 'business_date = ?',
      whereArgs: [date],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> closeDailyRecord(String date) async {
    final db = await database;
    return await db.update(
      'daily_records',
      {
        'status': 'closed',
        'closed_at': DateTime.now().toIso8601String(),
      },
      where: 'business_date = ?',
      whereArgs: [date],
    );
  }

  Future<int> archiveDailyRecord(String date) async {
    final db = await database;
    return await db.update(
      'daily_records',
      {'is_archived': 1},
      where: 'business_date = ?',
      whereArgs: [date],
    );
  }

  Future<List<Map<String, dynamic>>> getAllDailyRecords() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        d.*,
        COUNT(t.id) as transaction_count,
        COALESCE(SUM(t.amount), 0) as total_amount
      FROM daily_records d
      LEFT JOIN transactions t ON d.id = t.daily_record_id
      GROUP BY d.id
      ORDER BY d.business_date DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getArchivedRecords() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        d.*,
        COUNT(t.id) as transaction_count,
        COALESCE(SUM(t.amount), 0) as total_amount
      FROM daily_records d
      LEFT JOIN transactions t ON d.id = t.daily_record_id
      WHERE d.is_archived = 1
      GROUP BY d.id
      ORDER BY d.business_date DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getRecordsByMonth(int year, int month) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = month < 12
        ? '$year-${(month + 1).toString().padLeft(2, '0')}-01'
        : '${year + 1}-01-01';

    return await db.rawQuery('''
      SELECT 
        d.*,
        COUNT(t.id) as transaction_count,
        COALESCE(SUM(t.amount), 0) as total_amount
      FROM daily_records d
      LEFT JOIN transactions t ON d.id = t.daily_record_id
      WHERE d.business_date >= ? AND d.business_date < ?
      GROUP BY d.id
      ORDER BY d.business_date DESC
    ''', [startDate, endDate]);
  }

  Future<List<int>> getAvailableYears() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT substr(business_date, 1, 4) as year
      FROM daily_records
      ORDER BY year DESC
    ''');
    return result.map((r) => int.parse(r['year'] as String)).toList();
  }

  Future<List<int>> getAvailableMonths(int year) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT substr(business_date, 6, 2) as month
      FROM daily_records
      WHERE substr(business_date, 1, 4) = ?
      ORDER BY month DESC
    ''', ['$year']);
    return result.map((r) => int.parse(r['month'] as String)).toList();
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
    return await db.update('wallets', {'name': name}, where: 'id = ?', whereArgs: [id]);
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
      throw Exception('لا يمكن حذف محفظة لها عمليات مسجلة');
    }
    return await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  // ============ TRANSACTIONS ============

  Future<int> addTransaction({
    required int dailyRecordId,
    required int walletId,
    required String category,
    String? customName,
    required double amount,
    String? note,
  }) async {
    final db = await database;
    return await db.insert('transactions', {
      'daily_record_id': dailyRecordId,
      'wallet_id': walletId,
      'category': category,
      'custom_name': customName,
      'amount': amount,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> updateTransaction({
    required int id,
    required int walletId,
    required String category,
    String? customName,
    required double amount,
    String? note,
  }) async {
    final db = await database;
    return await db.update(
      'transactions',
      {
        'wallet_id': walletId,
        'category': category,
        'custom_name': customName,
        'amount': amount,
        'note': note,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionsByDate(String date) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.*, w.name as wallet_name, d.business_date
      FROM transactions t
      INNER JOIN daily_records d ON t.daily_record_id = d.id
      INNER JOIN wallets w ON t.wallet_id = w.id
      WHERE d.business_date = ?
      ORDER BY t.created_at DESC
    ''', [date]);
  }

  Future<List<Map<String, dynamic>>> getTodayTransactions() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return getTransactionsByDate(today);
  }

  Future<List<Map<String, dynamic>>> getTransactionsByDateRange(
      String startDate, String endDate) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.*, w.name as wallet_name, d.business_date
      FROM transactions t
      INNER JOIN daily_records d ON t.daily_record_id = d.id
      INNER JOIN wallets w ON t.wallet_id = w.id
      WHERE d.business_date >= ? AND d.business_date <= ?
      ORDER BY d.business_date DESC, t.created_at DESC
    ''', [startDate, endDate]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ============ STATISTICS ============

  Future<Map<String, dynamic>> getDailyStatistics(String date) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(t.amount), 0) as total,
        COUNT(t.id) as count
      FROM daily_records d
      LEFT JOIN transactions t ON d.id = t.daily_record_id
      WHERE d.business_date = ?
    ''', [date]);

    final categoryStats = await db.rawQuery('''
      SELECT t.category as category_name, COALESCE(SUM(t.amount), 0) as total, COUNT(t.id) as count
      FROM transactions t
      INNER JOIN daily_records d ON t.daily_record_id = d.id
      WHERE d.business_date = ?
      GROUP BY t.category
      ORDER BY total DESC
    ''', [date]);

    if (result.isNotEmpty) {
      final data = <String, dynamic>{};
      data['total'] = result.first['total'] ?? 0;
      data['count'] = result.first['count'] ?? 0;
      data['category_stats'] = categoryStats;
      return data;
    }
    return {
      'total': 0,
      'count': 0,
      'category_stats': <Map<String, dynamic>>[],
    };
  }

  Future<Map<String, dynamic>> getMonthlyStatistics(int year, int month) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = month < 12
        ? '$year-${(month + 1).toString().padLeft(2, '0')}-01'
        : '${year + 1}-01-01';

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(t.amount), 0) as total,
        COUNT(t.id) as count,
        COUNT(DISTINCT d.id) as days_count
      FROM daily_records d
      LEFT JOIN transactions t ON d.id = t.daily_record_id
      WHERE d.business_date >= ? AND d.business_date < ?
    ''', [startDate, endDate]);

    return result.isNotEmpty
        ? result.first
        : {'total': 0, 'count': 0, 'days_count': 0};
  }

  Future<List<Map<String, dynamic>>> getWalletStatistics(String date) async {
    final db = await database;

    return await db.rawQuery('''
      SELECT 
        w.id, w.name,
        COALESCE(SUM(t.amount), 0) as total,
        COUNT(t.id) as count
      FROM wallets w
      INNER JOIN daily_records d ON d.business_date = ?
      LEFT JOIN transactions t ON t.wallet_id = w.id AND t.daily_record_id = d.id
      GROUP BY w.id, w.name
      ORDER BY total DESC
    ''', [date]);
  }

  Future<List<Map<String, dynamic>>> getWalletStatisticsByMonth(
      int year, int month) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = month < 12
        ? '$year-${(month + 1).toString().padLeft(2, '0')}-01'
        : '${year + 1}-01-01';

    return await db.rawQuery('''
      SELECT 
        w.id, w.name,
        COALESCE(SUM(t.amount), 0) as total,
        COUNT(t.id) as count
      FROM wallets w
      LEFT JOIN daily_records d ON d.business_date >= ? AND d.business_date < ?
      LEFT JOIN transactions t ON t.wallet_id = w.id AND t.daily_record_id = d.id
      GROUP BY w.id, w.name
      ORDER BY total DESC
    ''', [startDate, endDate]);
  }

  // ============ SEARCH ============

  Future<List<Map<String, dynamic>>> searchTransactions({
    String? walletName,
    String? category,
    String? customName,
    String? startDate,
    String? endDate,
  }) async {
    final db = await database;

    String query = '''
      SELECT t.*, w.name as wallet_name, d.business_date
      FROM transactions t
      INNER JOIN daily_records d ON t.daily_record_id = d.id
      INNER JOIN wallets w ON t.wallet_id = w.id
      WHERE 1=1
    ''';
    List<dynamic> args = [];

    if (walletName != null && walletName.isNotEmpty) {
      query += ' AND w.name LIKE ?';
      args.add('%$walletName%');
    }
    if (category != null && category.isNotEmpty) {
      query += ' AND t.category = ?';
      args.add(category);
    }
    if (customName != null && customName.isNotEmpty) {
      query += ' AND t.custom_name LIKE ?';
      args.add('%$customName%');
    }
    if (startDate != null) {
      query += ' AND d.business_date >= ?';
      args.add(startDate);
    }
    if (endDate != null) {
      query += ' AND d.business_date <= ?';
      args.add(endDate);
    }

    query += ' ORDER BY d.business_date DESC, t.created_at DESC';

    return await db.rawQuery(query, args);
  }

  // ============ BACKUP ============

  Future<String> getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, 'sweets_ledger.db');
  }
}