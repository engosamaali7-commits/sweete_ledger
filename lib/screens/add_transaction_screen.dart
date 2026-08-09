import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _customNameController = TextEditingController();
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
    setState(() {
      _wallets = wallets;
    });
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
        customName: _selectedCategory == 'custom' ? _customNameController.text.trim() : null,
        amount: double.parse(_amountController.text),
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.getString('saved')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.getString('add_transaction')),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // نوع العملية
              Text(l10n.getString('category'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCategoryCard(
                      l10n.getString('sambousa'),
                      Icons.fastfood,
                      Colors.orange,
                      'sambousa',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCategoryCard(
                      l10n.getString('sweets'),
                      Icons.cake,
                      Colors.pink,
                      'sweets',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCategoryCard(
                      l10n.getString('other'),
                      Icons.more_horiz,
                      Colors.teal,
                      'custom',
                    ),
                  ),
                ],
              ),

              // حقل اسم العملية المخصصة
              if (_selectedCategory == 'custom') ...[
                const SizedBox(height: 24),
                Text(l10n.getString('custom_name'), style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customNameController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.edit_note),
                    hintText: l10n.getString('custom_name'),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.getString('custom_name_required');
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 24),

              // اختيار المحفظة
              Text(l10n.getString('wallet'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                  hintText: l10n.getString('select_wallet'),
                ),
                items: _wallets.map((w) {
                  return DropdownMenuItem<int>(
                    value: w['id'] as int,
                    child: Text(w['name'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedWalletId = value);
                },
                validator: (value) {
                  if (value == null) return l10n.getString('wallet_required');
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // المبلغ
              Text(l10n.getString('amount'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                  suffixText: 'ريال',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.getString('amount_required');
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return l10n.getString('amount_positive');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ملاحظات
              Text('${l10n.getString('note')} (${l10n.getString('optional')})',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  hintText: 'مثال: طلب رقم ٢٥',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // زر الحفظ
              FilledButton.icon(
                onPressed: _isLoading ? null : _saveTransaction,
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.save),
                label: Text(_isLoading
                    ? l10n.getString('saving')
                    : l10n.getString('save')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
      String label, IconData icon, Color color, String value) {
    final isSelected = _selectedCategory == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = value;
          if (value != 'custom') {
            _customNameController.clear();
          }
        });
      },
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : null,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _customNameController.dispose();
    super.dispose();
  }
}