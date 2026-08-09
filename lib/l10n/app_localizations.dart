import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'app_title': 'دفتر المحافظ',
      'dashboard': 'الرئيسية',
      'transactions': 'العمليات',
      'wallets': 'المحافظ',
      'statistics': 'الإحصائيات',
      'settings': 'الإعدادات',
      'add_transaction': 'تسجيل عملية',
      'sambousa': 'سمبوسة',
      'sweets': 'حلويات',
      'other': 'عملية أخرى',
      'category': 'نوع العملية',
      'custom_name': 'اسم العملية',
      'wallet': 'المحفظة',
      'amount': 'المبلغ',
      'note': 'ملاحظات',
      'optional': 'اختياري',
      'save': 'حفظ العملية',
      'saving': 'جاري الحفظ...',
      'saved': 'تم حفظ العملية بنجاح',
      'select_wallet': 'اختر المحفظة',
      'wallet_required': 'يجب اختيار المحفظة',
      'amount_required': 'يجب إدخال المبلغ',
      'amount_positive': 'يجب أن يكون المبلغ أكبر من صفر',
      'custom_name_required': 'يجب إدخال اسم العملية',
      'edit': 'تعديل',
      'delete': 'حذف',
      'cancel': 'إلغاء',
      'confirm_delete': 'تأكيد الحذف',
      'delete_confirm_msg': 'هل تريد حذف هذه العملية؟',
      'today_total': 'إجمالي اليوم',
      'operations_count': 'عدد العمليات',
      'no_operations': 'لا توجد عمليات اليوم',
      'good_morning': 'صباح الخير',
      'wallet_performance': 'أداء المحافظ',
      'operations': 'عمليات',
      'active': 'نشطة',
      'inactive': 'معطلة',
      'add_wallet': 'إضافة محفظة',
      'edit_wallet': 'تعديل المحفظة',
      'wallet_name': 'اسم المحفظة',
      'manage_wallets': 'إدارة المحافظ',
      'export_backup': 'تصدير نسخة احتياطية',
      'restore_backup': 'استعادة نسخة',
      'language': 'اللغة',
      'theme': 'المظهر',
      'app_info': 'معلومات التطبيق',
      'data_management': 'إدارة البيانات',
      'reports': 'التقارير',
      'contact': 'التواصل',
      'whatsapp': 'WhatsApp',
      'whatsapp_channel': 'قناة WhatsApp',
      'github': 'GitHub',
      'about': 'حول التطبيق',
      'developer_info': 'معلومات المطور',
      'developer_name': 'أسامة علي',
      'developer_title': 'Software Developer',
      'phone': 'رقم الهاتف',
      'version': 'الإصدار',
      'app_description': 'تطبيق لإدارة مبيعات الحلويات والسمبوسة والعمليات الأخرى عبر المحافظ الإلكترونية',
      'app_section': 'التطبيق',
      'data_section': 'البيانات',
      'wallets_section': 'المحافظ',
      'reports_section': 'التقارير',
      'contact_section': 'التواصل',
      'about_section': 'حول التطبيق',
      'export_data': 'تصدير البيانات',
      'backup': 'النسخ الاحتياطي',
      'restore': 'استعادة البيانات',
      'reports_settings': 'إعدادات التقارير',
      'contact_whatsapp': 'تواصل عبر WhatsApp',
    },
    'en': {
      'app_title': 'Wallet Ledger',
      'dashboard': 'Dashboard',
      'transactions': 'Transactions',
      'wallets': 'Wallets',
      'statistics': 'Statistics',
      'settings': 'Settings',
      'add_transaction': 'Add Transaction',
      'sambousa': 'Sambousa',
      'sweets': 'Sweets',
      'other': 'Other',
      'category': 'Category',
      'custom_name': 'Item Name',
      'wallet': 'Wallet',
      'amount': 'Amount',
      'note': 'Note',
      'optional': 'Optional',
      'save': 'Save Transaction',
      'saving': 'Saving...',
      'saved': 'Transaction saved successfully',
      'select_wallet': 'Select Wallet',
      'wallet_required': 'Wallet is required',
      'amount_required': 'Amount is required',
      'amount_positive': 'Amount must be greater than zero',
      'custom_name_required': 'Item name is required',
      'edit': 'Edit',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'confirm_delete': 'Confirm Delete',
      'delete_confirm_msg': 'Are you sure you want to delete this transaction?',
      'today_total': 'Today Total',
      'operations_count': 'Operations Count',
      'no_operations': 'No transactions today',
      'good_morning': 'Good Morning',
      'wallet_performance': 'Wallet Performance',
      'operations': 'operations',
      'active': 'Active',
      'inactive': 'Inactive',
      'add_wallet': 'Add Wallet',
      'edit_wallet': 'Edit Wallet',
      'wallet_name': 'Wallet Name',
      'manage_wallets': 'Manage Wallets',
      'export_backup': 'Export Backup',
      'restore_backup': 'Restore Backup',
      'language': 'Language',
      'theme': 'Theme',
      'app_info': 'App Info',
      'data_management': 'Data Management',
      'reports': 'Reports',
      'contact': 'Contact',
      'whatsapp': 'WhatsApp',
      'whatsapp_channel': 'WhatsApp Channel',
      'github': 'GitHub',
      'about': 'About',
      'developer_info': 'Developer Info',
      'developer_name': 'Osama Ali',
      'developer_title': 'Software Developer',
      'phone': 'Phone',
      'version': 'Version',
      'app_description': 'An app for managing sweets, sambousa, and other sales via e-wallets',
      'app_section': 'Application',
      'data_section': 'Data',
      'wallets_section': 'Wallets',
      'reports_section': 'Reports',
      'contact_section': 'Contact',
      'about_section': 'About',
      'export_data': 'Export Data',
      'backup': 'Backup',
      'restore': 'Restore',
      'reports_settings': 'Reports Settings',
      'contact_whatsapp': 'Contact via WhatsApp',
    },
  };

  String getString(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ar', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}