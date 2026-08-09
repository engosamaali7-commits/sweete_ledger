import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import 'add_transaction_screen.dart';
import 'wallets_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'previous_days_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(String)? onLanguageChanged;

  const HomeScreen({super.key, this.onLanguageChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  int _currentIndex = 0;
  Map<String, dynamic> _stats = {};
  double _totalToday = 0;
  double _totalSambousa = 0;
  double _totalSweets = 0;
  double _totalCustom = 0;
  List<Map<String, dynamic>> _customStats = [];
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
        _stats = stats;
        _totalToday = (stats['total'] as num?)?.toDouble() ?? 0;
        _totalSambousa = (stats['sambousa'] as num?)?.toDouble() ?? 0;
        _totalSweets = (stats['sweets'] as num?)?.toDouble() ?? 0;
        _totalCustom = (stats['custom_total'] as num?)?.toDouble() ?? 0;
        _customStats = (stats['custom_stats'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
            [];
        _transactionCount = (stats['count'] as int?) ?? 0;
        _walletStats = walletStats;
      });
    }
  }

  void _navigateTo(int index) async {
    if (index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WalletsScreen()),
      );
      _loadTodayData();
    } else if (index == 3) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StatisticsScreen()),
      );
    } else if (index == 4) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsScreen(
            onLanguageChanged: widget.onLanguageChanged,
          ),
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
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );
    if (result == true) {
      _loadTodayData();
    }
  }

  String _getDateString() {
    final now = DateTime.now();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return DateFormat('EEEE d MMMM yyyy', isArabic ? 'ar' : 'en').format(now);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.getString('good_morning'), style: const TextStyle(fontSize: 14)),
            Text(_getDateString(), style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.description),
            tooltip: 'التقارير',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'الأيام السابقة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PreviousDaysScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTodayData,
          ),
        ],
      ),
      body: _currentIndex == 0 ? _buildDashboard(l10n) : _buildTransactionsList(l10n),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _navigateTo,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.getString('dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.getString('transactions'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: l10n.getString('wallets'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.getString('statistics'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.getString('settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTransaction,
        icon: const Icon(Icons.add),
        label: Text(l10n.getString('add_transaction')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // ================ DASHBOARD ================
  Widget _buildDashboard(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final categoryStats = (_stats['category_stats'] as List<dynamic>?)
        ?.map((e) => e as Map<String, dynamic>)
        .toList() ?? [];

    return RefreshIndicator(
      onRefresh: _loadTodayData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  l10n.getString('today_total'),
                  _formatCurrency(_totalToday),
                  Icons.today,
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  l10n.getString('operations_count'),
                  '$_transactionCount',
                  Icons.receipt_long,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (categoryStats.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أنواع العمليات', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...categoryStats.asMap().entries.map((entry) {
                      final index = entry.key;
                      final stat = entry.value;
                      final colors = [Colors.orange, Colors.pink, Colors.teal, Colors.blue, Colors.purple, Colors.green];
                      final color = colors[index % colors.length];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.circle, size: 8, color: color),
                                const SizedBox(width: 8),
                                Text(stat['category_name'] ?? ''),
                              ],
                            ),
                            Text(
                              _formatCurrency((stat['total'] as num?)?.toDouble() ?? 0),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          Text(l10n.getString('wallet_performance'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (_walletStats.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(l10n.getString('no_operations')),
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
                  child: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                ),
                title: Text('${wallet['name'] ?? ''}'),
                subtitle: Text('${wallet['count'] ?? 0} ${l10n.getString('operations')}'),
                trailing: Text(
                  _formatCurrency((wallet['total'] as num?)?.toDouble() ?? 0),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            )),
        ],
      ),
    );
  }

  // ================ TRANSACTIONS LIST ================
  Widget _buildTransactionsList(AppLocalizations l10n) {
    return FutureBuilder<List<Map<String, dynamic>>>(
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
                Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(l10n.getString('no_operations'),
                    style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final t = transactions[index];
            final category = t['category'] as String? ?? 'sambousa';
            final isSambousa = category == 'sambousa';
            final isSweets = category == 'sweets';
            final isCustom = category == 'custom';
            final isArabic = Localizations.localeOf(context).languageCode == 'ar';
            final time = t['created_at'] != null
                ? DateFormat('hh:mm a', isArabic ? 'ar' : 'en')
                .format(DateTime.parse(t['created_at'] as String))
                : '';

            IconData icon;
            Color color;
            String title;

            if (isSambousa) {
              icon = Icons.fastfood;
              color = Colors.orange;
              title = l10n.getString('sambousa');
            } else if (isSweets) {
              icon = Icons.cake;
              color = Colors.pink;
              title = l10n.getString('sweets');
            } else {
              icon = Icons.more_horiz;
              color = Colors.teal;
              title = (t['custom_name'] as String?) ?? l10n.getString('other');
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                title: Text(title, style: const TextStyle(fontSize: 14)),
                subtitle: Text('${t['wallet_name'] ?? ''} • $time',
                    style: const TextStyle(fontSize: 12)),
                trailing: Text(
                  _formatCurrency((t['amount'] as num?)?.toDouble() ?? 0),
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                onTap: () => _showTransactionOptions(t, l10n),
              ),
            );
          },
        );
      },
    );
  }

  void _showTransactionOptions(Map<String, dynamic> transaction, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.getString('edit')),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(l10n.getString('delete'),
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(transaction['id'] as int, l10n);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int transactionId, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.getString('confirm_delete')),
        content: Text(l10n.getString('delete_confirm_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.getString('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _dbHelper.deleteTransaction(transactionId);
              _loadTodayData();
            },
            child: Text(l10n.getString('delete'),
                style: const TextStyle(color: Colors.red)),
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final format = NumberFormat('#,###', isArabic ? 'ar' : 'en');
    return format.format(amount);
  }
}