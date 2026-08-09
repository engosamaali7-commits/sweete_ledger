import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import 'add_transaction_screen.dart';
import 'wallets_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  int _currentIndex = 0;
  double _totalToday = 0;
  double _totalSambousa = 0;
  double _totalSweets = 0;
  int _transactionCount = 0;
  List<Map<String, dynamic>> _walletStats = [];

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    await _dbHelper.createDailyRecordIfNotExists(todayStr);

    final stats = await _dbHelper.getDailyStatistics(todayStr);
    final walletStats = await _dbHelper.getWalletStatistics(todayStr);

    if (mounted) {
      setState(() {
        _totalToday = (stats['total'] as num?)?.toDouble() ?? 0;
        _totalSambousa = (stats['sambousa'] as num?)?.toDouble() ?? 0;
        _totalSweets = (stats['sweets'] as num?)?.toDouble() ?? 0;
        _transactionCount = (stats['count'] as int?) ?? 0;
        _walletStats = walletStats;
      });
    }
  }

  void _navigateTo(int index) async {
    if (index == 2) {
      // فتح صفحة المحافظ
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const WalletsScreen(),
        ),
      );
      _loadTodayData();
    } else if (index == 3) {
      // فتح صفحة الإحصائيات
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const StatisticsScreen(),
        ),
      );
    } else if (index == 4) {
      // فتح صفحة الإعدادات
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        ),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _openAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(),
      ),
    );
    if (result == true) {
      _loadTodayData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0
          ? _buildDashboard()
          : _buildTransactionsList(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _navigateTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'العمليات',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'المحافظ',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'إحصائيات',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'إعدادات',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTransaction,
        icon: const Icon(Icons.add),
        label: const Text('تسجيل عملية'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // ================ DASHBOARD ================
  Widget _buildDashboard() {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE d MMMM yyyy', 'ar').format(now);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadTodayData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // الترحيب والتاريخ
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('صباح الخير 👋',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(dateStr,
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // بطاقات الملخص
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'إجمالي اليوم',
                    _formatCurrency(_totalToday),
                    Icons.today,
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'السمبوسة',
                    _formatCurrency(_totalSambousa),
                    Icons.fastfood,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'الحلويات',
                    _formatCurrency(_totalSweets),
                    Icons.cake,
                    Colors.pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // عدد العمليات
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'عدد العمليات: $_transactionCount',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // أداء المحافظ
            Text('أداء المحافظ',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            if (_walletStats.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_wallet,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      const Text('لا توجد عمليات اليوم'),
                    ],
                  ),
                ),
              )
            else
              ..._walletStats.map((wallet) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: const Icon(Icons.account_balance_wallet,
                        color: Colors.blue),
                  ),
                  title: Text('${wallet['name'] ?? ''}'),
                  subtitle: Text('${wallet['count'] ?? 0} عمليات'),
                  trailing: Text(
                    _formatCurrency(
                        (wallet['total'] as num?)?.toDouble() ?? 0),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  // ================ TRANSACTIONS LIST ================
  Widget _buildTransactionsList() {
    return SafeArea(
      child: Column(
        children: [
          // شريط عنوان بسيط
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('سجل العمليات',
                    style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadTodayData,
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _dbHelper.getTodayTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = snapshot.data ?? [];

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('لا توجد عمليات اليوم',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final t = transactions[index];
                    final isSambousa = t['category'] == 'sambousa';
                    final time = t['created_at'] != null
                        ? DateFormat('hh:mm a', 'ar').format(
                        DateTime.parse(t['created_at']))
                        : '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isSambousa ? Colors.orange : Colors.pink)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isSambousa ? Icons.fastfood : Icons.cake,
                            color: isSambousa ? Colors.orange : Colors.pink,
                          ),
                        ),
                        title: Text(isSambousa ? 'سمبوسة' : 'حلويات'),
                        subtitle: Text('${t['wallet_name'] ?? ''} • $time'),
                        trailing: Text(
                          _formatCurrency(
                              (t['amount'] as num?)?.toDouble() ?? 0),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onTap: () => _showTransactionOptions(t),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionOptions(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('تعديل'),
              onTap: () {
                Navigator.pop(context);
                // TODO: فتح شاشة التعديل
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title:
              const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(transaction['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int transactionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذه العملية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _dbHelper.deleteTransaction(transactionId);
              _loadTodayData();
            },
            child:
            const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(title,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat('#,###', 'ar');
    return format.format(amount);
  }
}