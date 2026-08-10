import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';

class PdfService {
  static pw.Font? _arabicFont;
  static pw.Font? _arabicBoldFont;

  Future<void> _loadFonts() async {
    if (_arabicFont != null) return;

    // محاولة تحميل الخط من assets
    try {
      final fontData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
      _arabicFont = pw.Font.ttf(fontData);
    } catch (e1) {
      try {
        final fontData = await rootBundle.load('assets/fonts/NotoNaskhArabic-SemiBold.ttf');
        _arabicFont = pw.Font.ttf(fontData);
      } catch (e2) {
        // استخدام خط مدمج من Google Fonts عبر الإنترنت كحل أخير
        _arabicFont = pw.Font.courier();
      }
    }

    try {
      final boldData = await rootBundle.load('assets/fonts/NotoNaskhArabic-SemiBold.ttf');
      _arabicBoldFont = pw.Font.ttf(boldData);
    } catch (e) {
      _arabicBoldFont = _arabicFont;
    }
  }

  // ============ تقرير يومي ============
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
    final categoryStats = (stats['category_stats'] as List<dynamic>?)
        ?.map((e) => e as Map<String, dynamic>)
        .toList() ??
        [];

    final pdf = pw.Document();
    final numberFormat = NumberFormat('#,###', isArabic ? 'ar' : 'en');
    final dateObj = DateTime.parse(date);
    final dateStr =
    DateFormat('EEEE d MMMM yyyy', isArabic ? 'ar' : 'en').format(dateObj);

    final font = _arabicFont ?? pw.Font.courier();
    final boldFont = _arabicBoldFont ?? _arabicFont ?? pw.Font.courier();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      theme: pw.ThemeData(
        defaultTextStyle: pw.TextStyle(font: font, fontSize: 11),
      ),
      build: (context) => [
        _buildHeader(dateStr, isArabic, boldFont),
        pw.SizedBox(height: 15),
        _buildSummarySection(
            stats, categoryStats, walletStats, numberFormat, isArabic, font, boldFont),
        pw.SizedBox(height: 15),
        _buildTransactionsTable(transactions, numberFormat, isArabic, font, boldFont),
        pw.SizedBox(height: 25),
        _buildFooter(isArabic, font, boldFont),
      ],
    ));

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report_$date.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  // ============ تقرير شهري ============
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

    const arabicMonths = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    const englishMonths = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthName = isArabic ? arabicMonths[month] : englishMonths[month];

    final font = _arabicFont ?? pw.Font.courier();
    final boldFont = _arabicBoldFont ?? _arabicFont ?? pw.Font.courier();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      theme: pw.ThemeData(
        defaultTextStyle: pw.TextStyle(font: font, fontSize: 11),
      ),
      build: (context) => [
        _buildHeader('$monthName $year', isArabic, boldFont),
        pw.SizedBox(height: 15),
        _buildMonthlySummary(stats, walletStats, numberFormat, isArabic, font, boldFont),
        pw.SizedBox(height: 25),
        _buildFooter(isArabic, font, boldFont),
      ],
    ));

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report_${year}_$month.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  // ============ تقرير مخصص ============
  Future<String> generateCustomReport({
    required String startDate,
    required String endDate,
    required bool isArabic,
    required AppLocalizations l10n,
    required DatabaseHelper dbHelper,
  }) async {
    await _loadFonts();

    final transactions =
    await dbHelper.getTransactionsByDateRange(startDate, endDate);
    final totalAmount = transactions.fold<double>(
        0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));

    final pdf = pw.Document();
    final numberFormat = NumberFormat('#,###', isArabic ? 'ar' : 'en');

    final font = _arabicFont ?? pw.Font.courier();
    final boldFont = _arabicBoldFont ?? _arabicFont ?? pw.Font.courier();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      theme: pw.ThemeData(
        defaultTextStyle: pw.TextStyle(font: font, fontSize: 11),
      ),
      build: (context) => [
        _buildHeader('$startDate - $endDate', isArabic, boldFont),
        pw.SizedBox(height: 15),
        pw.Text(
          '${isArabic ? "الإجمالي" : "Total"}: ${numberFormat.format(totalAmount)}',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          '${isArabic ? "عدد العمليات" : "Transactions"}: ${transactions.length}',
          style: pw.TextStyle(font: font, fontSize: 11),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
        pw.SizedBox(height: 15),
        _buildTransactionsTable(transactions, numberFormat, isArabic, font, boldFont),
        pw.SizedBox(height: 25),
        _buildFooter(isArabic, font, boldFont),
      ],
    ));

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report_custom.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  // ============ HEADER ============
  pw.Widget _buildHeader(String title, bool isArabic, pw.Font boldFont) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey, width: 1)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment:
        isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isArabic ? 'مدير المحافظ' : 'Wallet Manager',
            style: pw.TextStyle(font: boldFont, fontSize: 22),
            textDirection:
            isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            isArabic ? 'تقرير المبيعات' : 'Sales Report',
            style: pw.TextStyle(font: boldFont, fontSize: 16),
            textDirection:
            isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: pw.TextStyle(font: boldFont, fontSize: 13, color: PdfColors.grey700),
            textDirection:
            isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  // ============ SUMMARY ============
  pw.Widget _buildSummarySection(
      Map<String, dynamic> stats,
      List<Map<String, dynamic>> categoryStats,
      List<Map<String, dynamic>> walletStats,
      NumberFormat numberFormat,
      bool isArabic,
      pw.Font font,
      pw.Font boldFont,
      ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment:
        isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          // العنوان
          pw.Text(
            isArabic ? 'ملخص التقرير' : 'Summary',
            style: pw.TextStyle(font: boldFont, fontSize: 15),
            textDirection:
            isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),

          // الإجمالي
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                isArabic ? 'الإجمالي العام' : 'Total',
                style: pw.TextStyle(font: boldFont, fontSize: 12),
                textDirection:
                isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
              pw.Text(
                numberFormat.format(stats['total'] ?? 0),
                style: pw.TextStyle(font: boldFont, fontSize: 12),
                textDirection:
                isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                isArabic ? 'عدد العمليات' : 'Transactions',
                style: pw.TextStyle(font: font, fontSize: 11),
                textDirection:
                isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
              pw.Text(
                '${stats['count'] ?? 0}',
                style: pw.TextStyle(font: font, fontSize: 11),
                textDirection:
                isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
            ],
          ),

          // أنواع العمليات
          if (categoryStats.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              isArabic ? 'تفاصيل أنواع العمليات' : 'Category Details',
              style: pw.TextStyle(font: boldFont, fontSize: 12),
              textDirection:
              isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            ),
            pw.SizedBox(height: 6),
            ...categoryStats.map((c) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${c['category_name'] ?? ''}',
                    style: pw.TextStyle(font: font, fontSize: 11),
                    textDirection: isArabic
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr,
                  ),
                  pw.Text(
                    numberFormat
                        .format((c['total'] as num?)?.toDouble() ?? 0),
                    style: pw.TextStyle(font: font, fontSize: 11),
                    textDirection: isArabic
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr,
                  ),
                ],
              ),
            )),
          ],

          // المحافظ
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            isArabic ? 'المحافظ' : 'Wallets',
            style: pw.TextStyle(font: boldFont, fontSize: 12),
            textDirection:
            isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
          pw.SizedBox(height: 6),
          ...walletStats.map((w) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${w['name'] ?? ''}',
                  style: pw.TextStyle(font: font, fontSize: 11),
                  textDirection: isArabic
                      ? pw.TextDirection.rtl
                      : pw.TextDirection.ltr,
                ),
                pw.Text(
                  numberFormat
                      .format((w['total'] as num?)?.toDouble() ?? 0),
                  style: pw.TextStyle(font: font, fontSize: 11),
                  textDirection: isArabic
                      ? pw.TextDirection.rtl
                      : pw.TextDirection.ltr,
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ============ MONTHLY SUMMARY ============
  pw.Widget _buildMonthlySummary(
      Map<String, dynamic> stats,
      List<Map<String, dynamic>> walletStats,
      NumberFormat numberFormat,
      bool isArabic,
      pw.Font font,
      pw.Font boldFont,
      ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment:
        isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isArabic ? 'ملخص الشهر' : 'Monthly Summary',
            style: pw.TextStyle(font: boldFont, fontSize: 15),
            textDirection:
            isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),
          _summaryRow(isArabic ? 'الإجمالي' : 'Total',
              numberFormat.format(stats['total'] ?? 0), boldFont, isArabic),
          _summaryRow(isArabic ? 'عدد العمليات' : 'Transactions',
              '${stats['count'] ?? 0}', font, isArabic),
          _summaryRow(isArabic ? 'أيام العمل' : 'Working Days',
              '${stats['days_count'] ?? 0}', font, isArabic),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            isArabic ? 'المحافظ' : 'Wallets',
            style: pw.TextStyle(font: boldFont, fontSize: 12),
            textDirection:
            isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
          pw.SizedBox(height: 6),
          ...walletStats.map((w) => _summaryRow(
              '${w['name'] ?? ''}',
              numberFormat.format((w['total'] as num?)?.toDouble() ?? 0),
              font,
              isArabic)),
        ],
      ),
    );
  }

  pw.Widget _summaryRow(
      String label, String value, pw.Font font, bool isArabic) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: font, fontSize: 11),
            textDirection:
            isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: font, fontSize: 11),
            textDirection:
            isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  // ============ TRANSACTIONS TABLE ============
  pw.Widget _buildTransactionsTable(
      List<Map<String, dynamic>> transactions,
      NumberFormat numberFormat,
      bool isArabic,
      pw.Font font,
      pw.Font boldFont,
      ) {
    if (transactions.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Text(
          isArabic ? 'لا توجد عمليات' : 'No transactions',
          style: pw.TextStyle(font: font, fontSize: 12),
          textDirection:
          isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment:
      isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          isArabic ? 'سجل العمليات' : 'Transactions Log',
          style: pw.TextStyle(font: boldFont, fontSize: 15),
          textDirection:
          isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // رأس الجدول
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableCell(
                    isArabic ? 'الوقت' : 'Time', true, boldFont, isArabic),
                _tableCell(
                    isArabic ? 'النوع' : 'Type', true, boldFont, isArabic),
                _tableCell(isArabic ? 'المحفظة' : 'Wallet', true, boldFont,
                    isArabic),
                _tableCell(isArabic ? 'المبلغ' : 'Amount', true, boldFont,
                    isArabic),
              ],
            ),
            // بيانات الجدول
            ...transactions.asMap().entries.map((entry) {
              final index = entry.key;
              final t = entry.value;
              final time = t['created_at'] != null
                  ? DateFormat('hh:mm a', isArabic ? 'ar' : 'en')
                  .format(DateTime.parse(t['created_at'] as String))
                  : '';
              final type =
                  (t['category'] as String?) ?? (t['custom_name'] as String?) ?? '';
              final walletName = (t['wallet_name'] as String?) ?? '';
              final amount = (t['amount'] as num?)?.toDouble() ?? 0;
              final bgColor = index.isEven ? PdfColors.white : PdfColors.grey50;

              return pw.TableRow(
                decoration: pw.BoxDecoration(color: bgColor),
                children: [
                  _tableCell(time, false, font, isArabic),
                  _tableCell(type, false, font, isArabic),
                  _tableCell(walletName, false, font, isArabic),
                  _tableCell(numberFormat.format(amount), false, font, isArabic),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _tableCell(
      String text, bool isHeader, pw.Font font, bool isArabic) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  // ============ FOOTER ============
  pw.Widget _buildFooter(bool isArabic, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        crossAxisAlignment:
        isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'أسامة علي',
            style: pw.TextStyle(font: boldFont, fontSize: 11),
            textDirection:
            isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Software Developer',
            style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700),
            textDirection:
            isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '+967 780 155 801',
            style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700),
            textDirection:
            isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  // ============ طباعة ومشاركة ============

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