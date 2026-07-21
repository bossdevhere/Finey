import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/hive_database.dart';
import 'services/notification_service.dart';
import 'providers/settings_provider.dart';
import 'screens/navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive Offline Storage
  await HiveDatabase.initialize();

  // Initialize Notification Service
  await NotificationService.init();
  await NotificationService.requestPermissions();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PocketLife',

      // Dynamic Material 3 Light Theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1B5E20), // Dark green
          onPrimary: Colors.white,
          secondary: Color(0xFF4CAF50), // Light green
          onSecondary: Colors.black,
          surface: Color(0xFFF4FAF6), // Soft minty background
          onSurface: Colors.black87,
          outline: Color(0xFFE2EFE7),
        ),
        scaffoldBackgroundColor: const Color(
          0xFFF4FAF6,
        ), // Soft minty background
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFFF4FAF6),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: Color(0xFFE2EFE7),
            ), // Subtle mint border
          ),
        ),
      ),

      // Dynamic Material 3 Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4CAF50), // Vibrant Green highlight
          onPrimary: Colors.black,
          secondary: Color(0xFF2E7D32), // Dark green
          onSecondary: Colors.white,
          surface: Color(0xFF000000), // Pure Black surface
          onSurface: Colors.white,
          onSurfaceVariant: Colors.white70,
          outline: Color(0xFF1B3C22), // Forest Green outline
          error: Colors.redAccent,
        ),
        scaffoldBackgroundColor: const Color(
          0xFF000000,
        ), // Pure Black background
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFF000000), // Pure Black appBar
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF0E2012), // Dark green card background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF1B3C22)), // Forest border
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF000000), // Pure Black navbar
          indicatorColor: const Color(0xFF0E2012), // Dark green indicator
          surfaceTintColor: Colors.transparent, // Disable surface tinting
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: Color(0xFF4CAF50),
              ); // Light green icon
            }
            return const IconThemeData(color: Colors.grey);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              );
            }
            return const TextStyle(color: Colors.grey, fontSize: 12);
          }),
        ),
      ),

      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const NavigationScreen(),
    );
  }
}
