import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';  // ← ضروري جداً
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة اللغة العربية للتواريخ
  await initializeDateFormatting('ar');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دفتر المحافظ',
      debugShowCheckedModeBanner: false,

      // ========== اللغة العربية ==========
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,   // ← هذا المطلوب لـ AppBar
        GlobalWidgetsLocalizations.delegate,    // ← هذا المطلوب للـ Widgets
        GlobalCupertinoLocalizations.delegate,  // ← هذا لـ Cupertino widgets
      ],

      // ========== الثيم ==========
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      // ========== الشاشة الرئيسية ==========
      home: const HomeScreen(),
    );
  }
}