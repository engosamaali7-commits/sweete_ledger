import 'package:flutter/material.dart';
import '../database/database_helper.dart';


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
    setState(() => _wallets = wallets);
  }

  Future<void> _addWallet() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة محفظة'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'اسم المحفظة', border: OutlineInputBorder()), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('إضافة')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await _dbHelper.addWallet(name);
      _loadWallets();
    }
  }

  Future<void> _editWallet(int id, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل المحفظة'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'اسم المحفظة', border: OutlineInputBorder()), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('حفظ')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await _dbHelper.updateWallet(id, name);
      _loadWallets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المحافظ')),
      floatingActionButton: FloatingActionButton(onPressed: _addWallet, child: const Icon(Icons.add)),
      body: _wallets.isEmpty
          ? const Center(child: Text('لا توجد محافظ'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _wallets.length,
        itemBuilder: (context, index) {
          final wallet = _wallets[index];
          final isActive = wallet['is_active'] == 1;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: (isActive ? Colors.green : Colors.grey).withOpacity(0.1), child: Icon(Icons.account_balance_wallet, color: isActive ? Colors.green : Colors.grey)),
              title: Text(wallet['name'] ?? ''),
              subtitle: Text(isActive ? 'نشطة' : 'معطلة'),
              trailing: PopupMenuButton(
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    child: const ListTile(leading: Icon(Icons.edit), title: Text('تعديل'), contentPadding: EdgeInsets.zero),
                    onTap: () { Navigator.pop(ctx); _editWallet(wallet['id'], wallet['name']); },
                  ),
                  PopupMenuItem(
                    child: ListTile(leading: Icon(isActive ? Icons.visibility_off : Icons.visibility), title: Text(isActive ? 'تعطيل' : 'تفعيل'), contentPadding: EdgeInsets.zero),
                    onTap: () async { Navigator.pop(ctx); await _dbHelper.toggleWalletStatus(wallet['id'], !isActive); _loadWallets(); },
                  ),
                  PopupMenuItem(
                    child: const ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('حذف', style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        await _dbHelper.deleteWallet(wallet['id']);
                        _loadWallets();
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.orange));
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}