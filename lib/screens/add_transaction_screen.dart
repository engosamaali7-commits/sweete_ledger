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

  int? _selectedCategoryId;
  String? _selectedCategoryName;
  int? _selectedWalletId;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _wallets = [];
  bool _isLoading = false;
  bool _isCustom = false;
  bool _categoryError = false; // ✅ متغير لتتبع خطأ عدم اختيار النوع

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categories = await _dbHelper.getActiveCategories();
      final wallets = await _dbHelper.getActiveWallets();
      if (mounted) {
        setState(() {
          _categories = categories;
          _wallets = wallets;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categories = [
            {'id': 1, 'name': 'سمبوسة', 'icon_name': 'fastfood'},
            {'id': 2, 'name': 'حلويات', 'icon_name': 'cake'},
          ];
          _wallets = [];
        });
      }
      try {
        final wallets = await _dbHelper.getActiveWallets();
        if (mounted) setState(() => _wallets = wallets);
      } catch (e2) {}
    }
  }

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.orange, Colors.pink, Colors.teal,
      Colors.blue, Colors.purple, Colors.green,
      Colors.red, Colors.amber, Colors.indigo, Colors.cyan,
    ];
    return colors[index % colors.length];
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fastfood': return Icons.fastfood;
      case 'cake': return Icons.cake;
      case 'local_grocery_store': return Icons.local_grocery_store;
      case 'local_drink': return Icons.local_drink;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'build': return Icons.build;
      case 'handyman': return Icons.handyman;
      case 'checkroom': return Icons.checkroom;
      default: return Icons.category;
    }
  }

  /// ✅ دالة التحقق من صحة البيانات قبل الحفظ
  bool _validateData() {
    // التحقق من اختيار نوع العملية
    if (!_isCustom && _selectedCategoryId == null) {
      setState(() => _categoryError = true);
      _showWarningDialog('يجب اختيار نوع العملية أولاً');
      return false;
    }

    // التحقق من اسم العملية المخصصة
    if (_isCustom && _customNameController.text.trim().isEmpty) {
      _showWarningDialog('يجب إدخال اسم العملية المخصصة');
      return false;
    }

    // التحقق من اختيار المحفظة
    if (_selectedWalletId == null) {
      _showWarningDialog('يجب اختيار المحفظة');
      return false;
    }

    // التحقق من المبلغ
    if (_amountController.text.isEmpty) {
      _showWarningDialog('يجب إدخال المبلغ');
      return false;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showWarningDialog('يجب أن يكون المبلغ أكبر من صفر');
      return false;
    }

    return true;
  }

  /// ✅ عرض رسالة تحذير احترافية
  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
            const SizedBox(width: 8),
            const Text('تنبيه'),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange[700],
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('حسناً'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTransaction() async {
    // ✅ التحقق من البيانات قبل أي عملية حفظ
    if (!_validateData()) return;

    setState(() => _isLoading = true);

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final recordId = await _dbHelper.createDailyRecordIfNotExists(today);

      final String categoryName;
      if (_isCustom) {
        categoryName = _customNameController.text.trim();
      } else {
        categoryName = _selectedCategoryName ?? 'أخرى';
      }

      await _dbHelper.addTransaction(
        dailyRecordId: recordId,
        walletId: _selectedWalletId!,
        category: categoryName,
        customName: _isCustom ? _customNameController.text.trim() : null,
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
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.getString('add_transaction'))),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ============ نوع العملية ============
              Row(
                children: [
                  Text(l10n.getString('category'), style: theme.textTheme.titleMedium),
                  const SizedBox(width: 4),
                  Text('*', style: TextStyle(color: Colors.red, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),

              // ✅ إظهار رسالة خطأ إذا لم يتم اختيار نوع
              if (_categoryError)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[400], size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'يجب اختيار نوع العملية',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              if (_categoryError) const SizedBox(height: 8),

              // ✅ عرض جميع الفئات من قاعدة البيانات
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._categories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final cat = entry.value;
                    final isSelected = _selectedCategoryId == cat['id'] && !_isCustom;
                    final color = _getCategoryColor(index);
                    final iconName = cat['icon_name'] as String? ?? 'category';
                    final icon = _getIconData(iconName);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = cat['id'] as int;
                          _selectedCategoryName = cat['name'] as String;
                          _isCustom = false;
                          _categoryError = false; // ✅ إزالة الخطأ عند الاختيار
                          _customNameController.clear();
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
                                cat['name'] as String,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? color : null,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // ✅ زر "أخرى" للعمليات المخصصة
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCustom = true;
                        _selectedCategoryId = null;
                        _selectedCategoryName = null;
                        _categoryError = false; // ✅ إزالة الخطأ
                      });
                    },
                    child: Card(
                      elevation: _isCustom ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _isCustom ? Colors.grey : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Icon(Icons.edit_note, color: Colors.grey, size: 32),
                            SizedBox(height: 4),
                            Text('أخرى', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ============ اسم العملية المخصصة ============
              if (_isCustom) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(l10n.getString('custom_name'), style: theme.textTheme.titleMedium),
                    const SizedBox(width: 4),
                    Text('*', style: TextStyle(color: Colors.red, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customNameController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.edit_note),
                    hintText: l10n.getString('custom_name'),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ============ المحفظة ============
              Row(
                children: [
                  Text(l10n.getString('wallet'), style: theme.textTheme.titleMedium),
                  const SizedBox(width: 4),
                  Text('*', style: TextStyle(color: Colors.red, fontSize: 16)),
                ],
              ),
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
              ),
              const SizedBox(height: 24),

              // ============ المبلغ ============
              Row(
                children: [
                  Text(l10n.getString('amount'), style: theme.textTheme.titleMedium),
                  const SizedBox(width: 4),
                  Text('*', style: TextStyle(color: Colors.red, fontSize: 16)),
                ],
              ),
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
              ),
              const SizedBox(height: 24),

              // ============ ملاحظات ============
              Text(
                '${l10n.getString('note')} (${l10n.getString('optional')})',
                style: theme.textTheme.titleMedium,
              ),
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

              // ============ زر الحفظ ============
              FilledButton.icon(
                onPressed: _isLoading ? null : _saveTransaction,
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(
                  _isLoading ? l10n.getString('saving') : l10n.getString('save'),
                ),
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

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _customNameController.dispose();
    super.dispose();
  }
}