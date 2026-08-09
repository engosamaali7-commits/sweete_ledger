import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';

class PdfService {
  Future<String> generateDailyReport({
    required String date,
    required bool isArabic,
    required AppLocalizations l10n,
    required DatabaseHelper dbHelper,
  }) async {
    final stats = await dbHelper.getDailyStatistics(date);
    final transactions = await dbHelper.getTransactionsByDate(date);
    final walletStats = await dbHelper.getWalletStatistics(date);

    final pdf = pw.Document();
    final numberFormat = NumberFormat('#,###', isArabic ? 'ar' : 'en');
    final dateObj = DateTime.parse(date);
    final dateStr = DateFormat('EEEE d MMMM yyyy', isArabic ? 'ar' : 'en').format(dateObj);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (context) => [
          _buildHeader(dateStr, isArabic),
          pw.SizedBox(height: 20),
          _buildSummarySection(stats, walletStats, numberFormat, l10n, isArabic),
          pw.SizedBox(height: 20),
          _buildTransactionsTable(transactions, numberFormat, l10n, isArabic),
          pw.SizedBox(height: 30),
          _buildFooter(isArabic),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report_$date.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  Future<String> generateMonthlyReport({
    required int year,
    required int month,
    required bool isArabic,
    required AppLocalizations l10n,
    required DatabaseHelper dbHelper,
  }) async {
    final stats = await dbHelper.getMonthlyStatistics(year, month);
    final walletStats = await dbHelper.getWalletStatisticsByMonth(year, month);

    final pdf = pw.Document();
    final numberFormat = NumberFormat('#,###', isArabic ? 'ar' : 'en');

    const arabicMonths = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    const englishMonths = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthName = isArabic ? arabicMonths[month] : englishMonths[month];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (context) => [
          _buildHeader('$monthName $year', isArabic),
          pw.SizedBox(height: 20),
          _buildSummarySection(stats, walletStats, numberFormat, l10n, isArabic),
          pw.SizedBox(height: 30),
          _buildFooter(isArabic),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report_${year}_$month.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  Future<String> generateCustomReport({
    required String startDate,
    required String endDate,
    required bool isArabic,
    required AppLocalizations l10n,
    required DatabaseHelper dbHelper,
  }) async {
    final transactions = await dbHelper.getTransactionsByDateRange(startDate, endDate);
    final totalAmount = transactions.fold<double>(
        0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0)
    );

    final sambousaTotal = transactions
        .where((t) => t['category'] == 'sambousa')
        .fold<double>(0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));
    final sweetsTotal = transactions
        .where((t) => t['category'] == 'sweets')
        .fold<double>(0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));
    final customTotal = transactions
        .where((t) => t['category'] == 'custom')
        .fold<double>(0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));

    final pdf = pw.Document();
    final numberFormat = NumberFormat('#,###', isArabic ? 'ar' : 'en');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (context) => [
          _buildHeader('$startDate - $endDate', isArabic),
          pw.SizedBox(height: 20),
          pw.Text(
            '${isArabic ? "الإجمالي" : "Total"}: ${numberFormat.format(totalAmount)}',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text('${l10n.getString('sambousa')}: ${numberFormat.format(sambousaTotal)}'),
          pw.Text('${l10n.getString('sweets')}: ${numberFormat.format(sweetsTotal)}'),
          pw.Text('${l10n.getString('other')}: ${numberFormat.format(customTotal)}'),
          pw.SizedBox(height: 10),
          pw.Text('${isArabic ? "عدد العمليات" : "Transactions"}: ${transactions.length}'),
          pw.SizedBox(height: 20),
          _buildTransactionsTable(transactions, numberFormat, l10n, isArabic),
          pw.SizedBox(height: 30),
          _buildFooter(isArabic),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report_custom.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  pw.Widget _buildHeader(String title, bool isArabic) {
    return pw.Column(
      crossAxisAlignment: isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'دفتر المحافظ',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(title, style: const pw.TextStyle(fontSize: 16)),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildSummarySection(
      Map<String, dynamic> stats,
      List<Map<String, dynamic>> walletStats,
      NumberFormat numberFormat,
      AppLocalizations l10n,
      bool isArabic,
      ) {
    return pw.Column(
      crossAxisAlignment: isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          isArabic ? 'الملخص' : 'Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('${l10n.getString('sambousa')}: ${numberFormat.format(stats['sambousa'] ?? 0)}'),
        pw.Text('${l10n.getString('sweets')}: ${numberFormat.format(stats['sweets'] ?? 0)}'),
        pw.Text('${l10n.getString('other')}: ${numberFormat.format(stats['custom_total'] ?? 0)}'),
        pw.Text(
          '${isArabic ? "الإجمالي" : "Total"}: ${numberFormat.format(stats['total'] ?? 0)}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          isArabic ? 'المحافظ' : 'Wallets',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        ...walletStats.map((w) => pw.Text(
          '${w['name'] ?? ''}: ${numberFormat.format((w['total'] as num?)?.toDouble() ?? 0)}',
        )),
      ],
    );
  }

  pw.Widget _buildTransactionsTable(
      List<Map<String, dynamic>> transactions,
      NumberFormat numberFormat,
      AppLocalizations l10n,
      bool isArabic,
      ) {
    if (transactions.isEmpty) {
      return pw.Text(isArabic ? 'لا توجد عمليات' : 'No transactions');
    }

    return pw.Column(
      crossAxisAlignment: isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          isArabic ? 'العمليات' : 'Transactions',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              children: [
                _tableCell(isArabic ? 'الوقت' : 'Time', true),
                _tableCell(isArabic ? 'النوع' : 'Type', true),
                _tableCell(isArabic ? 'المحفظة' : 'Wallet', true),
                _tableCell(isArabic ? 'المبلغ' : 'Amount', true),
              ],
            ),
            ...transactions.map((t) {
              final time = t['created_at'] != null
                  ? DateFormat('hh:mm a', isArabic ? 'ar' : 'en')
                  .format(DateTime.parse(t['created_at'] as String))
                  : '';
              final category = t['category'] as String? ?? 'sambousa';
              String type;
              if (category == 'sambousa') {
                type = l10n.getString('sambousa');
              } else if (category == 'sweets') {
                type = l10n.getString('sweets');
              } else {
                type = (t['custom_name'] as String?) ?? l10n.getString('other');
              }
              final walletName = (t['wallet_name'] as String?) ?? '';
              final amount = (t['amount'] as num?)?.toDouble() ?? 0;

              return pw.TableRow(
                children: [
                  _tableCell(time, false),
                  _tableCell(type, false),
                  _tableCell(walletName, false),
                  _tableCell(numberFormat.format(amount), false),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _tableCell(String text, bool isHeader) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 10,
        ),
      ),
    );
  }

  pw.Widget _buildFooter(bool isArabic) {
    return pw.Column(
      crossAxisAlignment: isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),
        pw.Text('أسامة علي', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('Software Developer'),
        pw.Text('+967 780 155 801'),
      ],
    );
  }

  Future<void> printDailyReport({
    required String date,
    required bool isArabic,
    required AppLocalizations l10n,
    required DatabaseHelper dbHelper,
  }) async {
    final filePath = await generateDailyReport(
      date: date,
      isArabic: isArabic,
      l10n: l10n,
      dbHelper: dbHelper,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => await File(filePath).readAsBytes(),
    );
  }

  Future<void> printCustomReport({
    required String startDate,
    required String endDate,
    required bool isArabic,
    required AppLocalizations l10n,
    required DatabaseHelper dbHelper,
  }) async {
    final filePath = await generateCustomReport(
      startDate: startDate,
      endDate: endDate,
      isArabic: isArabic,
      l10n: l10n,
      dbHelper: dbHelper,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => await File(filePath).readAsBytes(),
    );
  }

  Future<void> sharePdf(String filePath) async {
    await Share.shareXFiles([XFile(filePath)]);
  }
}