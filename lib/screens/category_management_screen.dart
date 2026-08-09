import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final categories = await _dbHelper.getAllCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    }
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة نوع عملية'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'اسم النوع',
            border: OutlineInputBorder(),
            hintText: 'مثال: مواد غذائية',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('إضافة')),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await _dbHelper.addCategory(name);
      _loadCategories();
    }
  }

  Future<void> _editCategory(int id, String currentName) async {
    final controller = TextEditingController(text: currentName);

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل النوع'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'اسم النوع',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('حفظ')),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await _dbHelper.updateCategory(id, name);
      _loadCategories();
    }
  }

  Future<void> _toggleCategory(int id, bool isActive) async {
    await _dbHelper.toggleCategoryStatus(id, !isActive);
    _loadCategories();
  }

  Future<void> _deleteCategory(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد'),
        content: Text('هل تريد حذف/تعطيل "$name"؟\nإذا كان النوع مستخدماً في عمليات سابقة، سيتم تعطيله فقط.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteCategory(id);
      _loadCategories();
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fastfood': return Icons.fastfood;
      case 'cake': return Icons.cake;
      case 'local_grocery_store': return Icons.local_grocery_store;
      case 'local_drink': return Icons.local_drink;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'build': return Icons.build;
      default: return Icons.category;
    }
  }

  Color _getColor(int index) {
    final colors = [Colors.orange, Colors.pink, Colors.teal, Colors.blue, Colors.purple, Colors.green];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أنواع العمليات')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? const Center(child: Text('لا توجد أنواع'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isActive = cat['is_active'] == 1;
          final icon = _getIconData(cat['icon_name'] as String? ?? 'category');
          final color = _getColor(index);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (isActive ? color : Colors.grey).withOpacity(0.1),
                child: Icon(icon, color: isActive ? color : Colors.grey),
              ),
              title: Text(cat['name'] as String),
              subtitle: Text(isActive ? 'نشط' : 'معطل'),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: ListTile(leading: const Icon(Icons.edit), title: const Text('تعديل'), contentPadding: EdgeInsets.zero),
                    onTap: () {
                      Navigator.pop(context);
                      _editCategory(cat['id'] as int, cat['name'] as String);
                    },
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(isActive ? Icons.visibility_off : Icons.visibility),
                      title: Text(isActive ? 'تعطيل' : 'تفعيل'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _toggleCategory(cat['id'] as int, isActive);
                    },
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('حذف', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteCategory(cat['id'] as int, cat['name'] as String);
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