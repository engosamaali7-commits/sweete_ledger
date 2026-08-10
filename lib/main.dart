import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ar');

  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('language') ?? 'ar';

  runApp(MyApp(initialLocale: savedLocale));
}

class MyApp extends StatefulWidget {
  final String initialLocale;

  const MyApp({super.key, required this.initialLocale});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late String _currentLocale;

  @override
  void initState() {
    super.initState();
    _currentLocale = widget.initialLocale.isNotEmpty ? widget.initialLocale : 'ar';
  }

  void changeLanguage(String languageCode) {
    if (languageCode.isNotEmpty && mounted) {
      setState(() {
        _currentLocale = languageCode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدير المحافظ',
      debugShowCheckedModeBanner: false,

      locale: Locale(_currentLocale),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

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

      home: HomeScreen(onLanguageChanged: changeLanguage),
    );
  }
}