import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import 'day_details_screen.dart';

class PreviousDaysScreen extends StatefulWidget {
  const PreviousDaysScreen({super.key});

  @override
  State<PreviousDaysScreen> createState() => _PreviousDaysScreenState();
}

class _PreviousDaysScreenState extends State<PreviousDaysScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await _dbHelper.getAllDailyRecords();
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأيام السابقة'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('لا توجد أيام سابقة',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _records.length,
        itemBuilder: (context, index) {
          final record = _records[index];
          final date = DateTime.parse(record['business_date']);
          final dateStr = DateFormat('EEEE d MMMM yyyy', isArabic ? 'ar' : 'en').format(date);
          final total = (record['total_amount'] as num?)?.toDouble() ?? 0;
          final count = record['transaction_count'] ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
              ),
              title: Text(dateStr),
              subtitle: Text('$count ${l10n.getString('operations')}'),
              trailing: Text(
                _formatCurrency(total),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DayDetailsScreen(
                      date: record['business_date'],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatCurrency(double amount) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final format = NumberFormat('#,###', isArabic ? 'ar' : 'en');
    return format.format(amount);
  }
}