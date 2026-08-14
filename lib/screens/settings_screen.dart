import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import 'about_screen.dart';
import 'wallets_screen.dart';
import 'reports_screen.dart';
import 'category_management_screen.dart';
import 'home_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Function(String)? onLanguageChanged;

  const SettingsScreen({super.key, this.onLanguageChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String _currentLanguage = 'ar';
  String _retentionPolicy = 'always';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentLanguage = prefs.getString('language') ?? 'ar';
        _retentionPolicy = prefs.getString('retentionPolicy') ?? 'always';
      });
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    if (mounted) setState(() => _currentLanguage = languageCode);
    widget.onLanguageChanged?.call(languageCode);
  }

  Future<void> _exportDatabase() async {
    try {
      final dbPath = await _dbHelper.getDatabasePath();
      final file = File(dbPath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(dbPath)],
          text: 'نسخة احتياطية - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri);
  }

  Future<void> _openWhatsApp(String phone) async {
    final uri = Uri.parse('https://wa.me/$phone');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showRetentionPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سياسة الاحتفاظ بالبيانات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('الاحتفاظ دائماً'),
              value: 'always',
              groupValue: _retentionPolicy,
              onChanged: (value) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('retentionPolicy', value!);
                if (mounted) setState(() => _retentionPolicy = value);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('الأرشفة بعد 30 يوماً'),
              value: '30days',
              groupValue: _retentionPolicy,
              onChanged: (value) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('retentionPolicy', value!);
                if (mounted) setState(() => _retentionPolicy = value);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('الأرشفة بعد 3 أشهر'),
              value: '3months',
              groupValue: _retentionPolicy,
              onChanged: (value) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('retentionPolicy', value!);
                if (mounted) setState(() => _retentionPolicy = value);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('الأرشفة بعد 6 أشهر'),
              value: '6months',
              groupValue: _retentionPolicy,
              onChanged: (value) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('retentionPolicy', value!);
                if (mounted) setState(() => _retentionPolicy = value);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('الأرشفة بعد سنة'),
              value: '1year',
              groupValue: _retentionPolicy,
              onChanged: (value) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('retentionPolicy', value!);
                if (mounted) setState(() => _retentionPolicy = value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ مسح جميع البيانات - الإصلاح الكامل
  Future<void> _clearAllData() async {
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
          const SizedBox(width: 8),
          const Text('تحذير!'),
        ]),
        content: const Text(
          'سيتم حذف جميع البيانات نهائياً:\n\n'
              '• جميع العمليات المسجلة\n'
              '• جميع المحافظ\n'
              '• جميع أنواع العمليات\n'
              '• سجل الأيام السابقة\n\n'
              'لا يمكن التراجع عن هذه العملية!\n'
              'هل أنت متأكد أنك تريد المتابعة؟',
          style: TextStyle(fontSize: 15),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: Colors.red[700]), child: const Text('متابعة')),
        ],
      ),
    );

    if (firstConfirm != true) return;

    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.dangerous, color: Colors.red[900], size: 28),
          const SizedBox(width: 8),
          const Text('تأكيد نهائي'),
        ]),
        content: const Text(
          'هذه آخر فرصة للتراجع!\n\nهل أنت متأكد 100% أنك تريد مسح جميع البيانات؟',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: Colors.red[900]), child: const Text('نعم، امسح كل شيء')),
        ],
      ),
    );

    if (secondConfirm != true) return;

    try {
      // ✅ 1. إغلاق قاعدة البيانات
      await _dbHelper.closeDatabase();

      // ✅ 2. حذف ملف قاعدة البيانات
      final dbPath = await _dbHelper.getDatabasePath();
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      // ✅ 3. حذف الملفات الإضافية
      for (final suffix in ['-journal', '-wal', '-shm']) {
        final extraFile = File('$dbPath$suffix');
        if (await extraFile.exists()) {
          await extraFile.delete();
        }
      }

      // ✅ 4. مسح SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم مسح جميع البيانات بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // ✅ 5. إعادة تشغيل التطبيق بالكامل
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => HomeScreen(onLanguageChanged: widget.onLanguageChanged),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء المسح: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = _currentLanguage == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.getString('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ============ التطبيق ============
          _buildSectionHeader(l10n.getString('app_section')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.getString('language')),
                  subtitle: Text(isArabic ? 'العربية' : 'English'),
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'ar', label: Text('AR')),
                      ButtonSegment(value: 'en', label: Text('EN')),
                    ],
                    selected: {_currentLanguage},
                    onSelectionChanged: (value) => _changeLanguage(value.first),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: Text(l10n.getString('theme')),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.getString('app_info')),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ============ البيانات ============
          _buildSectionHeader(l10n.getString('data_section')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: Text(l10n.getString('export_data')),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: _exportDatabase,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: Text(l10n.getString('backup')),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: _exportDatabase,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: Text(l10n.getString('restore')),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('سيتم إضافة هذه الميزة قريباً')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('إدارة الاحتفاظ بالبيانات'),
                  subtitle: Text(_retentionPolicy == 'always' ? 'الاحتفاظ دائماً' : _retentionPolicy),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: _showRetentionPolicyDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red[700]),
                  title: Text('مسح جميع البيانات', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
                  subtitle: const Text('حذف جميع العمليات والمحافظ نهائياً'),
                  trailing: Icon(Icons.chevron_left, color: Colors.red[700]),
                  onTap: _clearAllData,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ============ المحافظ ============
          _buildSectionHeader(l10n.getString('wallets_section')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: Text(l10n.getString('manage_wallets')),
              trailing: const Icon(Icons.chevron_left),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletsScreen()),
                );
                if (mounted) setState(() {});
              },
            ),
          ),

          const SizedBox(height: 16),

          // ============ أنواع العمليات ============
          _buildSectionHeader('أنواع العمليات'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.category),
              title: const Text('إدارة أنواع العمليات'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
                );
                if (mounted) setState(() {});
              },
            ),
          ),

          const SizedBox(height: 16),

          // ============ التقارير ============
          _buildSectionHeader(l10n.getString('reports_section')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description),
              title: Text(l10n.getString('reports_settings')),
              trailing: const Icon(Icons.chevron_left),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
              },
            ),
          ),

          const SizedBox(height: 16),

          // ============ التواصل ============
          _buildSectionHeader(l10n.getString('contact_section')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: const Text('+967 780 155 801'),
                  subtitle: Text(l10n.getString('phone')),
                  onTap: () => _callPhone('967780155801'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.chat, color: Colors.green),
                  title: Text(l10n.getString('whatsapp')),
                  subtitle: Text(l10n.getString('contact_whatsapp')),
                  onTap: () => _openWhatsApp('967780155801'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.campaign, color: Colors.green),
                  title: Text(l10n.getString('whatsapp_channel')),
                  subtitle: const Text('مركز الدفاع الإلكتروني'),
                  onTap: () => _openUrl('https://whatsapp.com/channel/0029Vb5lkNCKmCPSvOoUOz0M'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code, color: Colors.black),
                  title: Text(l10n.getString('github')),
                  subtitle: const Text('OQ-Developer'),
                  onTap: () => _openUrl('https://github.com/engosamaali7-commits/OQ-Developer'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ============ حول التطبيق ============
          _buildSectionHeader(l10n.getString('about_section')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info),
              title: Text(l10n.getString('about')),
              trailing: const Icon(Icons.chevron_left),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
              },
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}