import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../services/pdf_service.dart';

class DayDetailsScreen extends StatefulWidget {
  final String date;

  const DayDetailsScreen({super.key, required this.date});

  @override
  State<DayDetailsScreen> createState() => _DayDetailsScreenState();
}

class _DayDetailsScreenState extends State<DayDetailsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _customStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final stats = await _dbHelper.getDailyStatistics(widget.date);
    final transactions = await _dbHelper.getTransactionsByDate(widget.date);

    setState(() {
      _stats = stats;
      _transactions = transactions;
      _customStats = (stats['custom_stats'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
          [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final date = DateTime.parse(widget.date);
    final dateStr = DateFormat('EEEE d MMMM yyyy', isArabic ? 'ar' : 'en').format(date);
    final numberFormat = NumberFormat('#,###', isArabic ? 'ar' : 'en');

    return Scaffold(
      appBar: AppBar(
        title: Text(dateStr),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'PDF',
            onPressed: () => _generatePdf(isArabic, l10n),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'طباعة',
            onPressed: () => _printReport(isArabic, l10n),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'مشاركة',
            onPressed: () => _shareReport(isArabic, l10n),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(dateStr, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        numberFormat.format(_stats['total'] ?? 0),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniStat(l10n.getString('sambousa'),
                              numberFormat.format(_stats['sambousa'] ?? 0), Colors.orange),
                          _buildMiniStat(l10n.getString('sweets'),
                              numberFormat.format(_stats['sweets'] ?? 0), Colors.pink),
                          _buildMiniStat(l10n.getString('other'),
                              numberFormat.format(_stats['custom_total'] ?? 0), Colors.teal),
                          _buildMiniStat(l10n.getString('operations_count'),
                              '${_stats['count'] ?? 0}', Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (_customStats.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.getString('other'),
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._customStats.map((stat) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(stat['custom_name'] ?? ''),
                              Text(numberFormat.format((stat['total'] as num?)?.toDouble() ?? 0),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              Text('${l10n.getString('transactions')} (${_transactions.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              if (_transactions.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(l10n.getString('no_operations'))),
                  ),
                )
              else
                ..._transactions.map((t) {
                  final category = t['category'] as String? ?? 'sambousa';
                  final isSambousa = category == 'sambousa';
                  final isSweets = category == 'sweets';
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
                        numberFormat.format((t['amount'] as num?)?.toDouble() ?? 0),
                        style: TextStyle(fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Future<void> _generatePdf(bool isArabic, AppLocalizations l10n) async {
    try {
      final pdfService = PdfService();
      final filePath = await pdfService.generateDailyReport(
        date: widget.date,
        isArabic: isArabic,
        l10n: l10n,
        dbHelper: _dbHelper,
      );

      if (mounted && filePath.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إنشاء PDF'),
            action: SnackBarAction(
              label: 'مشاركة',
              onPressed: () => pdfService.sharePdf(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printReport(bool isArabic, AppLocalizations l10n) async {
    final pdfService = PdfService();
    await pdfService.printDailyReport(
      date: widget.date,
      isArabic: isArabic,
      l10n: l10n,
      dbHelper: _dbHelper,
    );
  }

  Future<void> _shareReport(bool isArabic, AppLocalizations l10n) async {
    final text = await _buildShareText(isArabic, l10n);
    await Share.share(text);
  }

  Future<String> _buildShareText(bool isArabic, AppLocalizations l10n) async {
    final numberFormat = NumberFormat('#,###', isArabic ? 'ar' : 'en');
    final date = DateTime.parse(widget.date);
    final dateStr = DateFormat('EEEE d MMMM yyyy', isArabic ? 'ar' : 'en').format(date);

    final stats = await _dbHelper.getDailyStatistics(widget.date);
    final walletStats = await _dbHelper.getWalletStatistics(widget.date);

    final buffer = StringBuffer();
    buffer.writeln('📊 ${isArabic ? "تقرير المبيعات" : "Sales Report"}');
    buffer.writeln();
    buffer.writeln('📅 $dateStr');
    buffer.writeln('━━━━━━━━━━━━');
    buffer.writeln('💰 ${isArabic ? "الإجمالي" : "Total"}: ${numberFormat.format(stats['total'] ?? 0)}');
    buffer.writeln('🥟 ${l10n.getString('sambousa')}: ${numberFormat.format(stats['sambousa'] ?? 0)}');
    buffer.writeln('🍰 ${l10n.getString('sweets')}: ${numberFormat.format(stats['sweets'] ?? 0)}');
    buffer.writeln('📦 ${l10n.getString('other')}: ${numberFormat.format(stats['custom_total'] ?? 0)}');
    buffer.writeln('━━━━━━━━━━━━');
    buffer.writeln('${isArabic ? "المحافظ" : "Wallets"}:');
    for (var w in walletStats) {
      buffer.writeln('${w['name']}: ${numberFormat.format(w['total'] ?? 0)}');
    }
    buffer.writeln('━━━━━━━━━━━━');
    buffer.writeln('${l10n.getString('operations_count')}: ${stats['count'] ?? 0}');
    buffer.writeln();
    buffer.writeln('أسامة علي');
    buffer.writeln('+967 780 155 801');

    return buffer.toString();
  }
}