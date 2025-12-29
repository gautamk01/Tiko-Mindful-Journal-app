import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tracking_app/pages/journal_page.dart';
import 'package:tracking_app/pages/mood_chart_page.dart';
import 'package:tracking_app/pages/settings_page.dart';
import 'package:tracking_app/pages/splash_screen.dart';
import 'package:tracking_app/widgets/custom_bottom_nav.dart';
import 'package:tracking_app/services/notification_service.dart';

// Global navigator key for showing dialogs from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set full screen mode - hide status bar
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );

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
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Wellness Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFBE4D8)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF3F0),
      ),
      home: const SplashScreen(),
    );
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
