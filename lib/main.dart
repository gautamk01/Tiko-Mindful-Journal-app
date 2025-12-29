import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tracking_app/pages/journal_page.dart';
import 'package:tracking_app/pages/mood_chart_page.dart';
import 'package:tracking_app/pages/settings_page.dart';
import 'package:tracking_app/pages/splash_screen.dart';
import 'package:tracking_app/widgets/custom_bottom_nav.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tracking_app/services/database_service.dart';
import 'package:tracking_app/services/notification_service.dart';

// Global navigator key for showing dialogs from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set edge-to-edge mode (blends status bar)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          Brightness.dark, // Dark icons for light background
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Database BEFORE app runs to avoid LateInitializationError
  await DatabaseService().init();

  // Initialize notification service in background after app starts
  Future.delayed(const Duration(milliseconds: 100), () {
    NotificationService().initialize();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: DatabaseService().getUserDataListenable(),
      builder: (context, box, child) {
        final modeString =
            box.get('themeMode', defaultValue: 'system') as String;
        final mode = _getThemeMode(modeString);

        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Tiko',
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFBE4D8),
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFFAF3F0),
            // Light theme overrides
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFAF3F0),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black87),
              systemOverlayStyle: SystemUiOverlayStyle.dark, // Black icons
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFBE4D8),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.black, // AMOLED Black
            cardColor: const Color(0xFF1C1C1E),
            dividerColor: Colors.grey[800],
            // Dark theme overrides
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              systemOverlayStyle: SystemUiOverlayStyle.light, // White icons
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.black,
              selectedItemColor: Color(0xFFF39E75),
              unselectedItemColor: Colors.grey,
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }

  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pages rebuilt on each tab switch to refresh data
    final pages = [
      JournalPage(key: ValueKey(_selectedIndex == 0)),
      MoodChartPage(key: ValueKey(_selectedIndex == 1)),
      SettingsPage(key: ValueKey(_selectedIndex == 2)),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
