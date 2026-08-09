import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _customStats = [];
  List<Map<String, dynamic>> _walletStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final stats = await _dbHelper.getDailyStatistics(today);
    final walletStats = await _dbHelper.getWalletStatistics(today);

    setState(() {
      _stats = stats;
      _customStats = (stats['custom_stats'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
          [];
      _walletStats = walletStats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.getString('statistics')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ملخص اليوم
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(l10n.getString('today_total'),
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      numberFormat.format(_stats['total'] ?? 0),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat(
                          l10n.getString('sambousa'),
                          numberFormat.format(_stats['sambousa'] ?? 0),
                          Colors.orange,
                        ),
                        _buildMiniStat(
                          l10n.getString('sweets'),
                          numberFormat.format(_stats['sweets'] ?? 0),
                          Colors.pink,
                        ),
                        _buildMiniStat(
                          l10n.getString('other'),
                          numberFormat.format(_stats['custom_total'] ?? 0),
                          Colors.teal,
                        ),
                        _buildMiniStat(
                          l10n.getString('operations_count'),
                          '${_stats['count'] ?? 0}',
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // عرض العمليات المخصصة
            if (_customStats.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(l10n.getString('other'),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _customStats.map((stat) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.circle,
                                  size: 8, color: Colors.teal),
                              const SizedBox(width: 8),
                              Text(stat['custom_name'] ?? ''),
                            ],
                          ),
                          Text(
                            numberFormat.format(
                                (stat['total'] as num?)?.toDouble() ?? 0),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // أداء المحافظ
            Text(l10n.getString('wallet_performance'),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (_walletStats.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('لا توجد بيانات')),
                ),
              )
            else
              ..._walletStats.map((wallet) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet['name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildLabel(
                            '${l10n.getString('sambousa')}: ${numberFormat.format(wallet['sambousa'] ?? 0)}',
                            Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          _buildLabel(
                            '${l10n.getString('sweets')}: ${numberFormat.format(wallet['sweets'] ?? 0)}',
                            Colors.pink,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildLabel(
                            '${l10n.getString('other')}: ${numberFormat.format(wallet['custom_total'] ?? 0)}',
                            Colors.teal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الإجمالي: ${numberFormat.format(wallet['total'] ?? 0)} • ${wallet['count']} ${l10n.getString('operations')}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}