import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.getString('about')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // أيقونة التطبيق
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 50,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // اسم التطبيق
            Text(
              l10n.getString('app_title'),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // وصف التطبيق
            Text(
              l10n.getString('app_description'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            // الإصدار
            Text(
              '${l10n.getString('version')}: 1.0.0',
              style: theme.textTheme.bodySmall,
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // معلومات المطور
            Text(
              l10n.getString('developer_info'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person, size: 30),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.getString('developer_name'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.getString('developer_title'),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),

                    // أزرار التواصل
                    _buildContactButton(
                      Icons.phone,
                      '+967 780 155 801',
                          () => _callPhone('967780155801'),
                    ),
                    const SizedBox(height: 8),
                    _buildContactButton(
                      Icons.chat,
                      l10n.getString('contact_whatsapp'),
                          () => _openWhatsApp('967780155801'),
                    ),
                    const SizedBox(height: 8),
                    _buildContactButton(
                      Icons.campaign,
                      l10n.getString('whatsapp_channel'),
                          () => _openUrl(
                          'https://whatsapp.com/channel/0029Vb5lkNCKmCPSvOoUOz0M'),
                    ),
                    const SizedBox(height: 8),
                    _buildContactButton(
                      Icons.code,
                      l10n.getString('github'),
                          () => _openUrl(
                          'https://github.com/engosamaali7-commits'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton(
      IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}