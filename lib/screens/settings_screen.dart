import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> _exportDatabase() async {
    try {
      final dbPath = await _dbHelper.getDatabasePath();
      final file = File(dbPath);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(dbPath)], text: 'نسخة احتياطية - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}');
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ملف قاعدة البيانات غير موجود')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('تصدير نسخة احتياطية'),
                subtitle: const Text('مشاركة قاعدة البيانات'),
                trailing: const Icon(Icons.chevron_left),
                onTap: _exportDatabase,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('استعادة نسخة'),
                subtitle: const Text('استيراد قاعدة بيانات'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سيتم إضافة هذه الميزة قريباً')));
                },
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('عن التطبيق'),
              subtitle: const Text('الإصدار 1.0.0'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'دفتر المحافظ',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'تطبيق لإدارة مبيعات الحلويات والسمبوسة',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}