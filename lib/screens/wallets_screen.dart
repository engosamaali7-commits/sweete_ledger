import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _wallets = [];

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final wallets = await _dbHelper.getAllWallets();
    if (mounted) setState(() => _wallets = wallets);
  }

  Future<void> _addWallet() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: Text(l10n.getString('add_wallet')),
      content: TextField(controller: controller, decoration: InputDecoration(labelText: l10n.getString('wallet_name'), border: const OutlineInputBorder()), autofocus: true),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.getString('cancel'))), FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l10n.getString('add_wallet')))],
    ));
    if (name != null && name.isNotEmpty) { await _dbHelper.addWallet(name); _loadWallets(); }
  }

  Future<void> _editWallet(int id, String currentName) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: currentName);
    final name = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: Text(l10n.getString('edit_wallet')),
      content: TextField(controller: controller, decoration: InputDecoration(labelText: l10n.getString('wallet_name'), border: const OutlineInputBorder()), autofocus: true),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.getString('cancel'))), FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l10n.getString('save')))],
    ));
    if (name != null && name.isNotEmpty) { await _dbHelper.updateWallet(id, name); _loadWallets(); }
  }

  Future<void> _toggleWallet(int id, bool isActive) async {
    await _dbHelper.toggleWalletStatus(id, !isActive);
    _loadWallets();
  }

  Future<void> _deleteWallet(int id, String name) async {
    final l10n = AppLocalizations.of(context);
    try {
      final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: Text(l10n.getString('confirm_delete')), content: Text('هل تريد حذف محفظة "$name"؟'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.getString('cancel'))), TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.getString('delete'), style: const TextStyle(color: Colors.red)))],
      ));
      if (confirm == true) { await _dbHelper.deleteWallet(id); _loadWallets(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.orange));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.getString('manage_wallets'))),
      floatingActionButton: FloatingActionButton(onPressed: _addWallet, child: const Icon(Icons.add)),
      body: _wallets.isEmpty ? Center(child: Text(l10n.getString('no_operations'))) : ListView.builder(
        padding: const EdgeInsets.all(16), itemCount: _wallets.length, itemBuilder: (context, index) {
        final wallet = _wallets[index];
        final isActive = wallet['is_active'] == 1;
        return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
          leading: CircleAvatar(backgroundColor: (isActive ? Colors.green : Colors.grey).withOpacity(0.1), child: Icon(Icons.account_balance_wallet, color: isActive ? Colors.green : Colors.grey)),
          title: Text(wallet['name'] ?? ''), subtitle: Text(isActive ? l10n.getString('active') : l10n.getString('inactive')),
          trailing: PopupMenuButton(itemBuilder: (context) => [
            PopupMenuItem(child: ListTile(leading: const Icon(Icons.edit), title: Text(l10n.getString('edit')), contentPadding: EdgeInsets.zero), onTap: () { Navigator.pop(context); _editWallet(wallet['id'] as int, wallet['name'] as String); }),
            PopupMenuItem(child: ListTile(leading: Icon(isActive ? Icons.visibility_off : Icons.visibility), title: Text(isActive ? l10n.getString('inactive') : l10n.getString('active')), contentPadding: EdgeInsets.zero), onTap: () { Navigator.pop(context); _toggleWallet(wallet['id'] as int, isActive); }),
            PopupMenuItem(child: ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: Text(l10n.getString('delete'), style: const TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero), onTap: () { Navigator.pop(context); _deleteWallet(wallet['id'] as int, wallet['name'] as String); }),
          ]),
        ));
      },
      ),
    );
  }
}