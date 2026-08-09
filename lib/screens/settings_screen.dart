import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import 'about_screen.dart';
import 'wallets_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Function(String)? onLanguageChanged;

  const SettingsScreen({super.key, this.onLanguageChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String _currentLanguage = 'ar';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguage = prefs.getString('language') ?? 'ar';
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    setState(() {
      _currentLanguage = languageCode;
    });
    widget.onLanguageChanged?.call(languageCode);
  }

  Future<void> _exportDatabase() async {
    try {
      final dbPath = await _dbHelper.getDatabasePath();
      final file = File(dbPath);

      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(dbPath)],
          text:
          'نسخة احتياطية - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = _currentLanguage == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.getString('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ============ التطبيق ============
          _buildSectionHeader(l10n.getString('app_section')),
          Card(
            child: Column(
              children: [
                // اللغة
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
                    onSelectionChanged: (value) {
                      _changeLanguage(value.first);
                    },
                  ),
                ),
                const Divider(height: 1),
                // المظهر
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: Text(l10n.getString('theme')),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {
                    // TODO: فتح إعدادات المظهر
                  },
                ),
                const Divider(height: 1),
                // معلومات التطبيق
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.getString('app_info')),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AboutScreen()),
                    );
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
                      const SnackBar(
                          content: Text('سيتم إضافة هذه الميزة قريباً')),
                    );
                  },
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WalletsScreen()),
                );
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
                // TODO: فتح إعدادات التقارير
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
                  onTap: () => _openUrl(
                      'https://whatsapp.com/channel/0029Vb5lkNCKmCPSvOoUOz0M'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code, color: Colors.black),
                  title: Text(l10n.getString('github')),
                  onTap: () => _openUrl(
                      'https://github.com/engosamaali7-commits'),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AboutScreen()),
                );
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