import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import 'day_details_screen.dart';
import '../services/pdf_service.dart';

class MonthDetailsScreen extends StatefulWidget {
  final int year;
  final int month;

  const MonthDetailsScreen({super.key, required this.year, required this.month});

  @override
  State<MonthDetailsScreen> createState() => _MonthDetailsScreenState();
}

class _MonthDetailsScreenState extends State<MonthDetailsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, dynamic> _monthStats = {};
  List<Map<String, dynamic>> _walletStats = [];
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final monthStats = await _dbHelper.getMonthlyStatistics(widget.year, widget.month);
    final walletStats = await _dbHelper.getWalletStatisticsByMonth(widget.year, widget.month);
    final records = await _dbHelper.getRecordsByMonth(widget.year, widget.month);

    if (mounted) {
      setState(() {
        _monthStats = monthStats;
        _walletStats = walletStats;
        _records = records;
        _isLoading = false;
      });
    }
  }

  String _getMonthName(int month, bool isArabic) {
    const arabicMonths = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    const englishMonths = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return isArabic ? arabicMonths[month] : englishMonths[month];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,###', isArabic ? 'ar' : 'en');
    final monthName = _getMonthName(widget.month, isArabic);

    return Scaffold(
      appBar: AppBar(
        title: Text('$monthName ${widget.year}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generatePdf(isArabic, l10n),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('$monthName ${widget.year}', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      numberFormat.format(_monthStats['total'] ?? 0),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat(
                          l10n.getString('operations_count'),
                          '${_monthStats['count'] ?? 0}',
                          Colors.blue,
                        ),
                        _buildMiniStat(
                          isArabic ? 'أيام العمل' : 'Days',
                          '${_monthStats['days_count'] ?? 0}',
                          Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              l10n.getString('wallet_performance'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

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
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                  ),
                  title: Text(wallet['name'] ?? ''),
                  subtitle: Text('${wallet['count'] ?? 0} ${l10n.getString('operations')}'),
                  trailing: Text(
                    numberFormat.format((wallet['total'] as num?)?.toDouble() ?? 0),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              )),

            const SizedBox(height: 16),

            Text(
              '${isArabic ? "الأيام" : "Days"} (${_records.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (_records.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('لا توجد أيام')),
                ),
              )
            else
              ..._records.map((record) {
                final date = DateTime.parse(record['business_date'] as String);
                final dateStr = DateFormat('EEEE d MMMM', isArabic ? 'ar' : 'en').format(date);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(dateStr),
                    subtitle: Text('${record['transaction_count'] ?? 0} ${l10n.getString('operations')}'),
                    trailing: Text(
                      numberFormat.format((record['total_amount'] as num?)?.toDouble() ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DayDetailsScreen(
                            date: record['business_date'] as String,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
          ],
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
      final filePath = await pdfService.generateMonthlyReport(
        year: widget.year,
        month: widget.month,
        isArabic: isArabic,
        l10n: l10n,
        dbHelper: _dbHelper,
      );

      if (mounted) {
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
}