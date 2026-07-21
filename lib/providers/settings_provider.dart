import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/hive_database.dart';
import '../models/settings.dart';

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier()
      : super(
          HiveDatabase.settingsBox.get('user_settings') ??
              Settings(
                isDarkMode: true,
                themeColor: 0xFF2E7D32,
                currency: '₹',
                monthlyBudget: 30000.0,
              ),
        );

  Future<void> updateSettings(Settings newSettings) async {
    state = newSettings;
    await HiveDatabase.settingsBox.put('user_settings', newSettings);
  }

  Future<void> updateBudget(double budget) async {
    final newSettings = state.copyWith(monthlyBudget: budget);
    await updateSettings(newSettings);
  }

  Future<void> updateCurrency(String currency) async {
    final newSettings = state.copyWith(currency: currency);
    await updateSettings(newSettings);
  }

  Future<void> toggleDarkMode() async {
    final newSettings = state.copyWith(isDarkMode: !state.isDarkMode);
    await updateSettings(newSettings);
  }

  Future<void> updateThemeColor(int colorValue) async {
    final newSettings = state.copyWith(themeColor: colorValue);
    await updateSettings(newSettings);
  }

  Future<void> resetApp() async {
    await HiveDatabase.clearAll();
    state = Settings(
      isDarkMode: true,
      themeColor: 0xFF2E7D32,
      currency: '₹',
      monthlyBudget: 30000.0,
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  return SettingsNotifier();
});
