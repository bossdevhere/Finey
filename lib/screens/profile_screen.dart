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
  final TextEditingController _budgetController = TextEditingController();

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showBudgetDialog() {
    final settingsObj = ref.read(settingsProvider);
    _budgetController.text = settingsObj.monthlyBudget.toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('Set Monthly Budget', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: TextField(
            controller: _budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              prefixText: '${settingsObj.currency} ',
              labelText: 'Budget Amount',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              onPressed: () {
                final val = double.tryParse(_budgetController.text);
                if (val != null && val > 0) {
                  ref.read(settingsProvider.notifier).updateBudget(val);
                  Navigator.pop(context);
                  _showSnackBar('Budget updated successfully!');
                }
              },
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  void _showCurrencyDialog() {
    final settingsObj = ref.read(settingsProvider);
    final currencies = ['₹', '\$', '€', '£', '¥', '₩', '₽'];

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('Select Currency Symbol', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.map((cur) {
              final isSelected = settingsObj.currency == cur;
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(cur, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface)),
                trailing: isSelected ? Icon(Icons.check_circle_rounded, color: colorScheme.primary) : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).updateCurrency(cur);
                  Navigator.pop(context);
                  _showSnackBar('Currency changed to $cur');
                },
              );
            }).toList(),
          ),
        );
      },
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
            // User Header Profile Card
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outline, width: 1),
              ),
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_rounded, size: 32, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Finovo User',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Personal Finance & Life Manager',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Visual Design Section
            _sectionHeader('THEME & DESIGN', colorScheme),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline, width: 1),
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
                activeColor: colorScheme.primary,
                onChanged: (bool val) {
                  ref.read(settingsProvider.notifier).toggleDarkMode();
                },
              ),
            ),
            const SizedBox(height: 24),

            // Financial Tracker Section
            _sectionHeader('FINANCIAL PREFERENCES', colorScheme),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline, width: 1),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      'Currency Symbol',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      'Active symbol: ${settingsObj.currency}',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    leading: Icon(Icons.currency_exchange_rounded, color: colorScheme.primary),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _showCurrencyDialog,
                  ),
                  Divider(height: 1, color: colorScheme.outline),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      'Monthly Budget Limit',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      'Warning limit: ${settingsObj.currency}${settingsObj.monthlyBudget.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    leading: Icon(Icons.account_balance_wallet_rounded, color: colorScheme.primary),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _showBudgetDialog,
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
