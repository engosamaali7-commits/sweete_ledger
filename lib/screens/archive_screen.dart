import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import 'month_details_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<int> _years = [];
  Map<int, List<int>> _monthsByYear = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchive();
  }

  Future<void> _loadArchive() async {
    setState(() => _isLoading = true);

    final years = await _dbHelper.getAvailableYears();
    final monthsByYear = <int, List<int>>{};

    for (var year in years) {
      monthsByYear[year] = await _dbHelper.getAvailableMonths(year);
    }

    setState(() {
      _years = years;
      _monthsByYear = monthsByYear;
      _isLoading = false;
    });
  }

  String _getMonthName(int month, bool isArabic) {
    const arabicMonths = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    const englishMonths = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return isArabic ? arabicMonths[month] : englishMonths[month];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('الأرشيف')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _years.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('الأرشيف فارغ', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _years.length,
        itemBuilder: (context, yearIndex) {
          final year = _years[yearIndex];
          final months = _monthsByYear[year] ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
              title: Text('$year', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              children: months.map((month) {
                return ListTile(
                  leading: const Icon(Icons.folder, color: Colors.amber),
                  title: Text(_getMonthName(month, isArabic)),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MonthDetailsScreen(year: year, month: month),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}