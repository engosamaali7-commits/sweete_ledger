import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';

class PdfService {
  static pw.Font? _arabicFont;
  static pw.Font? _arabicBoldFont;

  Future<void> _loadFonts() async {
    if (_arabicFont != null) return;

    try {
      final arabicFontData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
      final arabicBoldFontData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Bold.ttf');
      _arabicFont = pw.Font.ttf(arabicFontData);
      _arabicBoldFont = pw.Font.ttf(arabicBoldFontData);
    } catch (e) {
      _arabicFont = pw.Font.helvetica();
      _arabicBoldFont = pw.Font.helveticaBold();
    }
  }

  pw.Font _getFont({bool bold = false}) {
    if (_arabicFont != null && bold && _arabicBoldFont != null) return _arabicBoldFont!;
    if (_arabicFont != null) return _arabicFont!;
    return bold ? pw.Font.helveticaBold() : pw.Font.helvetica();
  }

  Future<String> generateDailyReport({
    required String date,
    required bool isArabic,
    required AppLocalizations l10n,
    required DatabaseHelper dbHelper,
  }) async {
    await _loadFonts();

    final stats = await dbHelper.getDailyStatistics(date);
    final transactions = await dbHelper.getTransactionsByDate(date);
    final walletStats = await dbHelper.getWalletStatistics(date);
    final categoryStats = (stats['category_stats'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];

    final pdf = pw.Document();
    final numberFormat = NumberFormat('#,###', isArabic ? 'ar' : 'en');
    final dateObj = DateTime.parse(date);
    final dateStr = DateFormat('EEEE d MMMM yyyy', isArabic ? 'ar' : 'en').format(dateObj);

    final font = _getFont();
    final boldFont = _getFont(bold: true);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(font: font)),
        build: (context) => [
          _buildHeader(dateStr, isArabic, font, boldFont),
          pw.SizedBox(height: 20),
          _buildSummarySection(stats, categoryStats, walletStats, numberFormat, isArabic, font, boldFont),
          pw.SizedBox(height: 20),
          _buildTransactionsTable(transactions, numberFormat, isArabic, font, boldFont),
          pw.SizedBox(height: 30),
          _buildFooter(isArabic, font, boldFont),
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
    await _loadFonts();

    final stats = await dbHelper.getMonthlyStatistics(year, month);
    final walletStats = await dbHelper.getWalletStatisticsByMonth(year, month);

    final pdf = pw.Document();
    final numberFormat = NumberFormat('#,###', isArabic ? 'ar' : 'en');

    const arabicMonths = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    const englishMonths = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final monthName = isArabic ? arabicMonths[month] : englishMonths[month];

    final font = _getFont();
    final boldFont = _getFont(bold: true);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(font: font)),
        build: (context) => [
          _buildHeader('$monthName $year', isArabic, font, boldFont),
          pw.SizedBox(height: 20),
          _buildMonthlySummary(stats, walletStats, numberFormat, isArabic, font, boldFont),
          pw.SizedBox(height: 30),
          _buildFooter(isArabic, font, boldFont),
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
    await _loadFonts();

    final transactions = await dbHelper.getTransactionsByDateRange(startDate, endDate);
    final totalAmount = transactions.fold<double>(0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));

    final pdf = pw.Document();
    final numberFormat = NumberFormat('#,###', isArabic ? 'ar' : 'en');

    final font = _getFont();
    final boldFont = _getFont(bold: true);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(font: font)),
        build: (context) => [
          _buildHeader('$startDate - $endDate', isArabic, font, boldFont),
          pw.SizedBox(height: 20),
          pw.Text(
            '${isArabic ? "الإجمالي" : "Total"}: ${numberFormat.format(totalAmount)}',
            style: pw.TextStyle(font: boldFont, fontSize: 18),
          ),
          pw.SizedBox(height: 10),
          pw.Text('${isArabic ? "عدد العمليات" : "Transactions"}: ${transactions.length}'),
          pw.SizedBox(height: 20),
          _buildTransactionsTable(transactions, numberFormat, isArabic, font, boldFont),
          pw.SizedBox(height: 30),
          _buildFooter(isArabic, font, boldFont),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report_custom.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  pw.Widget _buildHeader(String title, bool isArabic, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        pw.Text('مدير المحافظ', style: pw.TextStyle(font: boldFont, fontSize: 24)),
        pw.Text(title, style: pw.TextStyle(font: font, fontSize: 16)),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildSummarySection(
      Map<String, dynamic> stats,
      List<Map<String, dynamic>> categoryStats,
      List<Map<String, dynamic>> walletStats,
      NumberFormat numberFormat,
      bool isArabic,
      pw.Font font,
      pw.Font boldFont,
      ) {
    return pw.Column(
      crossAxisAlignment: isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(isArabic ? 'الملخص' : 'Summary', style: pw.TextStyle(font: boldFont, fontSize: 18)),
        pw.SizedBox(height: 10),
        pw.Text('${isArabic ? "الإجمالي" : "Total"}: ${numberFormat.format(stats['total'] ?? 0)}',
            style: pw.TextStyle(font: boldFont)),
        pw.SizedBox(height: 10),
        if (categoryStats.isNotEmpty) ...[
          pw.Text(isArabic ? 'أنواع العمليات' : 'Categories', style: pw.TextStyle(font: boldFont, fontSize: 14)),
          ...categoryStats.map((c) => pw.Text(
            '${c['category_name'] ?? ''}: ${numberFormat.format((c['total'] as num?)?.toDouble() ?? 0)}',
            style: pw.TextStyle(font: font),
          )),
          pw.SizedBox(height: 10),
        ],
        pw.Text(isArabic ? 'المحافظ' : 'Wallets', style: pw.TextStyle(font: boldFont, fontSize: 14)),
        ...walletStats.map((w) => pw.Text(
          '${w['name'] ?? ''}: ${numberFormat.format((w['total'] as num?)?.toDouble() ?? 0)}',
          style: pw.TextStyle(font: font),
        )),
      ],
    );
  }

  pw.Widget _buildMonthlySummary(
      Map<String, dynamic> stats,
      List<Map<String, dynamic>> walletStats,
      NumberFormat numberFormat,
      bool isArabic,
      pw.Font font,
      pw.Font boldFont,
      ) {
    return pw.Column(
      crossAxisAlignment: isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(isArabic ? 'الملخص' : 'Summary', style: pw.TextStyle(font: boldFont, fontSize: 18)),
        pw.SizedBox(height: 10),
        pw.Text('${isArabic ? "الإجمالي" : "Total"}: ${numberFormat.format(stats['total'] ?? 0)}',
            style: pw.TextStyle(font: boldFont)),
        pw.Text('${isArabic ? "عدد العمليات" : "Transactions"}: ${stats['count'] ?? 0}'),
        pw.Text('${isArabic ? "أيام العمل" : "Working days"}: ${stats['days_count'] ?? 0}'),
        pw.SizedBox(height: 10),
        pw.Text(isArabic ? 'المحافظ' : 'Wallets', style: pw.TextStyle(font: boldFont, fontSize: 14)),
        ...walletStats.map((w) => pw.Text(
          '${w['name'] ?? ''}: ${numberFormat.format((w['total'] as num?)?.toDouble() ?? 0)}',
          style: pw.TextStyle(font: font),
        )),
      ],
    );
  }

  pw.Widget _buildTransactionsTable(
      List<Map<String, dynamic>> transactions,
      NumberFormat numberFormat,
      bool isArabic,
      pw.Font font,
      pw.Font boldFont,
      ) {
    if (transactions.isEmpty) {
      return pw.Text(isArabic ? 'لا توجد عمليات' : 'No transactions', style: pw.TextStyle(font: font));
    }

    return pw.Column(
      crossAxisAlignment: isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(isArabic ? 'العمليات' : 'Transactions', style: pw.TextStyle(font: boldFont, fontSize: 16)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              children: [
                _tableCell(isArabic ? 'الوقت' : 'Time', true, boldFont),
                _tableCell(isArabic ? 'النوع' : 'Type', true, boldFont),
                _tableCell(isArabic ? 'المحفظة' : 'Wallet', true, boldFont),
                _tableCell(isArabic ? 'المبلغ' : 'Amount', true, boldFont),
              ],
            ),
            ...transactions.map((t) {
              final time = t['created_at'] != null
                  ? DateFormat('hh:mm a', isArabic ? 'ar' : 'en').format(DateTime.parse(t['created_at'] as String))
                  : '';
              final type = (t['category_name'] as String?) ?? (t['custom_name'] as String?) ?? '';
              final walletName = (t['wallet_name'] as String?) ?? '';
              final amount = (t['amount'] as num?)?.toDouble() ?? 0;

              return pw.TableRow(
                children: [
                  _tableCell(time, false, font),
                  _tableCell(type, false, font),
                  _tableCell(walletName, false, font),
                  _tableCell(numberFormat.format(amount), false, font),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _tableCell(String text, bool isHeader, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 10, fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  pw.Widget _buildFooter(bool isArabic, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),
        pw.Text('أسامة علي', style: pw.TextStyle(font: boldFont)),
        pw.Text('Software Developer', style: pw.TextStyle(font: font)),
        pw.Text('+967 780 155 801', style: pw.TextStyle(font: font)),
      ],
    );
  }

  Future<void> printDailyReport({
    required String date,
    required bool isArabic,
    required AppLocalizations l10n,
    required DatabaseHelper dbHelper,
  }) async {
    final filePath = await generateDailyReport(date: date, isArabic: isArabic, l10n: l10n, dbHelper: dbHelper);
    await Printing.layoutPdf(onLayout: (format) async => await File(filePath).readAsBytes());
  }

  Future<void> printCustomReport({
    required String startDate,
    required String endDate,
    required bool isArabic,
    required AppLocalizations l10n,
    required DatabaseHelper dbHelper,
  }) async {
    final filePath = await generateCustomReport(startDate: startDate, endDate: endDate, isArabic: isArabic, l10n: l10n, dbHelper: dbHelper);
    await Printing.layoutPdf(onLayout: (format) async => await File(filePath).readAsBytes());
  }

  Future<void> sharePdf(String filePath) async {
    await Share.shareXFiles([XFile(filePath)]);
  }
}