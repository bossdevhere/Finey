import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/hive_database.dart';
import 'services/notification_service.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure transparent status and nav bars for edge-to-edge rendering
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

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
      title: 'Finovo',

      // Premium Minimal Light Theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF10B981), // Emerald accent
          onPrimary: Colors.white,
          secondary: Color(0xFF6366F1), // Indigo accent
          onSecondary: Colors.white,
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF0F172A), // Deep Slate
          onSurfaceVariant: Color(0xFF64748B), // Muted Grey
          outline: Color(0xFFE2E8F0), // Subtle Border
          outlineVariant: Color(0xFFF1F5F9),
          error: Color(0xFFEF4444),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Porcelain Background
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFFF8F9FA),
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: const Color(0xFFECFDF5),
          surfaceTintColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF059669), size: 22);
            }
            return const IconThemeData(color: Color(0xFF94A3B8), size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Color(0xFF059669),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              );
            }
            return const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500);
          }),
        ),
      ),

      // Premium Minimal Dark Theme (Obsidian & Emerald)
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981), // Emerald accent
          onPrimary: Colors.black,
          secondary: Color(0xFF818CF8), // Indigo accent
          onSecondary: Colors.black,
          surface: Color(0xFF18181B), // Zinc surface card
          onSurface: Color(0xFFFAFAFA), // Pure white
          onSurfaceVariant: Color(0xFFA1A1AA), // Muted light grey
          outline: Color(0xFF27272A), // Subtle border
          outlineVariant: Color(0xFF27272A),
          error: Color(0xFFF43F5E),
        ),
        scaffoldBackgroundColor: const Color(0xFF09090B), // OLED Obsidian Background
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFF09090B),
          foregroundColor: Color(0xFFFAFAFA),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFFFAFAFA),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF18181B),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF27272A), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF18181B),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF27272A), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF27272A), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF09090B),
          elevation: 0,
          indicatorColor: const Color(0xFF27272A),
          surfaceTintColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF10B981), size: 22);
            }
            return const IconThemeData(color: Color(0xFF71717A), size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              );
            }
            return const TextStyle(color: Color(0xFF71717A), fontSize: 12, fontWeight: FontWeight.w500);
          }),
        ),
      ),

      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
