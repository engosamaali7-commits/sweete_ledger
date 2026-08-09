import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';


class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  int? _selectedWalletId;
  List<Map<String, dynamic>> _wallets = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final wallets = await _dbHelper.getActiveWallets();
    setState(() => _wallets = wallets);
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final recordId = await _dbHelper.createDailyRecordIfNotExists(today);

      await _dbHelper.addTransaction(
        dailyRecordId: recordId,
        walletId: _selectedWalletId!,
        category: _selectedCategory!,
        amount: double.parse(_amountController.text),
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ العملية بنجاح ✓'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل عملية جديدة')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('نوع العملية', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _catCard('سمبوسة', Icons.fastfood, Colors.orange, 'sambousa')),
              const SizedBox(width: 12),
              Expanded(child: _catCard('حلويات', Icons.cake, Colors.pink, 'sweets')),
            ]),
            const SizedBox(height: 24),
            Text('المحفظة', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.account_balance_wallet)),
              hint: const Text('اختر المحفظة'),
              items: _wallets.map((w) => DropdownMenuItem<int>(value: w['id'] as int, child: Text(w['name'] as String))).toList(),
              onChanged: (value) => setState(() => _selectedWalletId = value),
              validator: (value) => value == null ? 'يجب اختيار المحفظة' : null,
            ),
            const SizedBox(height: 24),
            Text('المبلغ', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.monetization_on), suffixText: 'ريال'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'يجب إدخال المبلغ';
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) return 'يجب أن يكون المبلغ أكبر من صفر';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('ملاحظات (اختياري)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(controller: _noteController, decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.note), hintText: 'مثال: طلب رقم ٢٥'), maxLines: 2),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isLoading ? null : _saveTransaction,
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
              label: Text(_isLoading ? 'جاري الحفظ...' : 'حفظ العملية'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _catCard(String label, IconData icon, Color color, String value) {
    final isSelected = _selectedCategory == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = value),
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? color : Colors.transparent, width: 2)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : null)),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}