import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, dynamic> _stats = {};
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
    setState(() { _stats = stats; _walletStats = walletStats; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nf = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(title: const Text('الإحصائيات'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStatistics)]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Text('إجمالي اليوم', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(nf.format(_stats['total'] ?? 0), style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _mini('السمبوسة', nf.format(_stats['sambousa'] ?? 0), Colors.orange),
                  _mini('الحلويات', nf.format(_stats['sweets'] ?? 0), Colors.pink),
                  _mini('العمليات', '${_stats['count'] ?? 0}', Colors.blue),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          Text('أداء المحافظ', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_walletStats.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('لا توجد بيانات'))))
          else
            ..._walletStats.map((w) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(w['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _label('السمبوسة: ${nf.format(w['sambousa'] ?? 0)}', Colors.orange),
                    const SizedBox(width: 16),
                    _label('الحلويات: ${nf.format(w['sweets'] ?? 0)}', Colors.pink),
                  ]),
                  const SizedBox(height: 4),
                  Text('الإجمالي: ${nf.format(w['total'] ?? 0)} • ${w['count']} عمليات', style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
              ),
            )),
        ]),
      ),
    );
  }

  Widget _mini(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }

  Widget _label(String text, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 12)),
    ]);
  }
}