import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import 'history_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _showBudgetDialog(double currentBudget, String currency, ColorScheme colorScheme) {
    final controller = TextEditingController(text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '');
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Set Monthly Limit', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
            onChanged: (_) {
              if (errorText != null) {
                setDialogState(() => errorText = null);
              }
            },
            decoration: InputDecoration(
              labelText: 'Monthly Limit (Max 50,000)',
              hintText: 'e.g. 30000',
              errorText: errorText,
              prefixText: '$currency ',
              prefixStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final val = double.tryParse(controller.text.trim());
                if (val == null || val <= 0) {
                  setDialogState(() => errorText = 'Please enter a valid amount');
                } else if (val > 50000) {
                  setDialogState(() => errorText = "You can't put more than 50,000 monthly limit");
                } else {
                  ref.read(settingsProvider.notifier).updateMonthlyBudget(val);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Limit', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog(String currentCurrency, ColorScheme colorScheme) {
    final currencies = ['₹', '\$', '€', '£', '¥', '₩'];
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Select Currency Symbol', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        children: currencies.map((c) {
          return SimpleDialogOption(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            onPressed: () {
              ref.read(settingsProvider.notifier).updateCurrency(c);
              Navigator.pop(context);
            },
            child: Row(
              children: [
                Text(c, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                const SizedBox(width: 16),
                Text(c == currentCurrency ? 'Current' : '', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsObj = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Visual Design Section
            _sectionHeader('THEME & DESIGN', colorScheme),
            const SizedBox(height: 8),
            Material(
              color: colorScheme.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colorScheme.outline, width: 1),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  'Dark Theme',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colorScheme.onSurface),
                ),
                subtitle: Text(
                  'Sleek obsidian mode for reduced eye strain',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                secondary: Icon(
                  settingsObj.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: colorScheme.primary,
                ),
                value: settingsObj.isDarkMode,
                activeThumbColor: colorScheme.primary,
                onChanged: (bool val) {
                  ref.read(settingsProvider.notifier).toggleDarkMode();
                },
              ),
            ),
            const SizedBox(height: 24),

            // Financial Tracker Section
            _sectionHeader('FINANCIAL PREFERENCES', colorScheme),
            const SizedBox(height: 8),
            Material(
              color: colorScheme.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colorScheme.outline, width: 1),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      'Monthly Limit',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      settingsObj.monthlyBudget > 0
                          ? '${settingsObj.currency}${settingsObj.monthlyBudget.toStringAsFixed(0)} monthly spending budget'
                          : 'Tap to set monthly budget limit',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    leading: Icon(Icons.account_balance_wallet_outlined, color: colorScheme.primary),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showBudgetDialog(settingsObj.monthlyBudget, settingsObj.currency, colorScheme),
                  ),
                  Divider(height: 1, color: colorScheme.outline),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      'Currency Symbol',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      'Current: ${settingsObj.currency}',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    leading: Icon(Icons.currency_exchange_rounded, color: colorScheme.primary),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showCurrencyDialog(settingsObj.currency, colorScheme),
                  ),
                  Divider(height: 1, color: colorScheme.outline),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      'Transaction History',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      'View, search, and filter all entries',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    leading: Icon(Icons.history_rounded, color: colorScheme.primary),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
