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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showBudgetDialog() {
    final settingsObj = ref.read(settingsProvider);
    _budgetController.text = settingsObj.monthlyBudget.toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Monthly Budget'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: settingsObj.currency,
              labelText: 'Budget Amount',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(_budgetController.text);
                if (val != null && val > 0) {
                  ref.read(settingsProvider.notifier).updateBudget(val);
                  Navigator.pop(context);
                  _showSnackBar('Budget updated successfully!');
                }
              },
              child: const Text('Save'),
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
        return AlertDialog(
          title: const Text('Select Currency Symbol'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.map((cur) {
              return ListTile(
                title: Text(cur, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                trailing: settingsObj.currency == cur ? const Icon(Icons.check, color: Colors.green) : null,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                    child: Icon(Icons.person, size: 36, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PocketLife User',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Personal Expense Tracker',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Styling settings section
          _sectionHeader('Visual Design'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Easy on eyes & saves battery'),
                  secondary: const Icon(Icons.dark_mode),
                  value: settingsObj.isDarkMode,
                  onChanged: (bool val) {
                    ref.read(settingsProvider.notifier).toggleDarkMode();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tracker settings section
          _sectionHeader('Financial Tracker'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Currency Symbol'),
                  subtitle: Text('Current currency: ${settingsObj.currency}'),
                  leading: const Icon(Icons.currency_exchange),
                  onTap: _showCurrencyDialog,
                ),
                ListTile(
                  title: const Text('Monthly Budget Limit'),
                  subtitle: Text('Budget warning fires at: ${settingsObj.currency}${settingsObj.monthlyBudget.toStringAsFixed(0)}'),
                  leading: const Icon(Icons.wallet),
                  onTap: _showBudgetDialog,
                ),
                ListTile(
                  title: const Text('Transaction History'),
                  subtitle: const Text('View and filter monthly activities'),
                  leading: const Icon(Icons.history),
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
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
