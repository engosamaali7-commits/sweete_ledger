import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../services/pdf_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _reportType = 'daily';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.getString('reports'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('نوع التقرير', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'daily', label: Text('يومي')),
                        ButtonSegment(value: 'weekly', label: Text('أسبوعي')),
                        ButtonSegment(value: 'monthly', label: Text('شهري')),
                        ButtonSegment(value: 'custom', label: Text('مخصص')),
                      ],
                      selected: {_reportType},
                      onSelectionChanged: (value) {
                        setState(() => _reportType = value.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildDateCard('التاريخ', _startDate, (date) {
              setState(() => _startDate = date);
            }),
            if (_reportType == 'custom') ...[
              const SizedBox(height: 8),
              _buildDateCard('إلى', _endDate, (date) {
                setState(() => _endDate = date);
              }),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(Icons.print, 'طباعة', () => _printReport(isArabic, l10n)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(Icons.picture_as_pdf, 'PDF', () => _generatePdf(isArabic, l10n)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(Icons.share, 'مشاركة PDF', () => _sharePdf(isArabic, l10n)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(Icons.text_snippet, 'مشاركة كنص', () => _shareText(isArabic, l10n)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard(String label, DateTime date, Function(DateTime) onChanged) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          DateFormat('yyyy-MM-dd', isArabic ? 'ar' : 'en').format(date),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null) onChanged(picked);
        },
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
    );
  }

  Future<void> _generatePdf(bool isArabic, AppLocalizations l10n) async {
    try {
      final pdfService = PdfService();
      final filePath = await pdfService.generateCustomReport(
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
        isArabic: isArabic, l10n: l10n, dbHelper: _dbHelper,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('تم إنشاء PDF'),
            action: SnackBarAction(label: 'مشاركة', onPressed: () => pdfService.sharePdf(filePath)),
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
    await pdfService.printCustomReport(
      startDate: DateFormat('yyyy-MM-dd').format(_startDate),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate),
      isArabic: isArabic, l10n: l10n, dbHelper: _dbHelper,
    );
  }

  Future<void> _sharePdf(bool isArabic, AppLocalizations l10n) async {
    try {
      final pdfService = PdfService();
      final filePath = await pdfService.generateCustomReport(
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
        isArabic: isArabic, l10n: l10n, dbHelper: _dbHelper,
      );
      await pdfService.sharePdf(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _shareText(bool isArabic, AppLocalizations l10n) async {
    final numberFormat = NumberFormat('#,###', isArabic ? 'ar' : 'en');
    final transactions = await _dbHelper.getTransactionsByDateRange(
      DateFormat('yyyy-MM-dd').format(_startDate),
      DateFormat('yyyy-MM-dd').format(_endDate),
    );

    final totalAmount = transactions.fold<double>(0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));
    final sambousaTotal = transactions.where((t) => t['category'] == 'sambousa').fold<double>(0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));
    final sweetsTotal = transactions.where((t) => t['category'] == 'sweets').fold<double>(0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));
    final customTotal = transactions.where((t) => t['category'] == 'custom').fold<double>(0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));

    final buffer = StringBuffer();
    buffer.writeln('📊 ${isArabic ? "تقرير المبيعات" : "Sales Report"}');
    buffer.writeln('📅 ${DateFormat('yyyy-MM-dd').format(_startDate)} - ${DateFormat('yyyy-MM-dd').format(_endDate)}');
    buffer.writeln('━━━━━━━━━━━━');
    buffer.writeln('💰 ${isArabic ? "الإجمالي" : "Total"}: ${numberFormat.format(totalAmount)}');
    buffer.writeln('🥟 ${l10n.getString('sambousa')}: ${numberFormat.format(sambousaTotal)}');
    buffer.writeln('🍰 ${l10n.getString('sweets')}: ${numberFormat.format(sweetsTotal)}');
    buffer.writeln('📦 ${l10n.getString('other')}: ${numberFormat.format(customTotal)}');
    buffer.writeln('━━━━━━━━━━━━');
    buffer.writeln('${isArabic ? "عدد العمليات" : "Transactions"}: ${transactions.length}');
    buffer.writeln();
    buffer.writeln('أسامة علي');
    buffer.writeln('+967 780 155 801');

    await Share.share(buffer.toString());
  }
}