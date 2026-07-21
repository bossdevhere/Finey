import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';

import '../providers/note_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/calculator_widget.dart';
import 'calendar_screen.dart';
import 'search_screen.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../providers/navigation_provider.dart';
import 'history_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseProvider);
    final incomes = ref.watch(incomeProvider);
    final notes = ref.watch(noteProvider);
    final settings = ref.watch(settingsProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filter Current Month data
    final now = DateTime.now();
    final monthlyExpenses = expenses.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    final monthlyIncomes = incomes.where((i) => i.date.year == now.year && i.date.month == now.month).toList();

    final double totalIncome = monthlyIncomes.fold(0, (sum, i) => sum + i.amount);
    final double totalExpense = monthlyExpenses.fold(0, (sum, e) => sum + e.amount);
    final double balance = totalIncome - totalExpense;
    final double savings = balance > 0 ? balance : 0;

    // Budget Limit Alert
    final bool isBudgetExceeded = totalExpense > settings.monthlyBudget;
    final double budgetPercent = (totalExpense / settings.monthlyBudget).clamp(0.0, 1.0);



    // Combined recent transactions (Expenses & Incomes sorted together)
    final recentItems = <dynamic>[];
    recentItems.addAll(expenses);
    recentItems.addAll(incomes);
    recentItems.sort((a, b) => b.date.compareTo(a.date));
    final displayTransactions = recentItems.take(3).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Hive reactive updates will reload automatically via provider invalidation
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              // Greeting and Profile Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PocketLife',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          color: colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Glassmorphic Balance & Tracker Card
              _buildBalanceCard(colorScheme, settings.currency, totalIncome, totalExpense, savings, balance),
              const SizedBox(height: 16),

              // Budget Progress & Alarm Notification Warning
              if (settings.monthlyBudget > 0)
                _buildBudgetTracker(colorScheme, settings.currency, totalExpense, settings.monthlyBudget, budgetPercent, isBudgetExceeded),

              const SizedBox(height: 20),

              // Recent Transactions with View All link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Activity', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      ref.read(navigationIndexProvider.notifier).state = 3; // Switch to Profile tab (index 3)
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                    child: const Text('View All', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (displayTransactions.isEmpty)
                _buildEmptyStateCard('No transactions logged yet', Icons.receipt_long_outlined, colorScheme)
              else
                _buildRecentTransactions(displayTransactions, settings.currency, ref),
              const SizedBox(height: 20),

              // Recent Notes list
              _buildSectionHeader(theme, 'Recent Notes & Lists', null),
              const SizedBox(height: 8),
              if (notes.isEmpty)
                _buildEmptyStateCard('No notes saved', Icons.description_outlined, colorScheme)
              else
                _buildRecentNotes(notes.take(3).toList(), theme),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ColorScheme scheme, String currency, double inc, double exp, double sav, double bal) {
    return Card(
      elevation: 4,
      shadowColor: Color(scheme.primary.value).withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              scheme.primary,
              scheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NET CASH BALANCE',
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 6),
            Text(
              '$currency${bal.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCardStatItem('Income', '$currency${inc.toStringAsFixed(0)}', Icons.arrow_downward, Colors.greenAccent),
                _buildCardStatItem('Expenses', '$currency${exp.toStringAsFixed(0)}', Icons.arrow_upward, Colors.redAccent),
                _buildCardStatItem('Savings', '$currency${sav.toStringAsFixed(0)}', Icons.savings_outlined, Colors.amberAccent),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCardStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBudgetTracker(ColorScheme scheme, String currency, double exp, double limit, double percent, bool isExceeded) {
    return Card(
      elevation: 0,
      color: isExceeded ? Colors.red.withOpacity(0.06) : scheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isExceeded ? Colors.red.withOpacity(0.2) : scheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isExceeded ? Icons.warning_amber_rounded : Icons.pie_chart_outline,
                      color: isExceeded ? Colors.red : scheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isExceeded ? 'Budget Limit Exceeded!' : 'Monthly Budget Planner',
                      style: TextStyle(fontWeight: FontWeight.bold, color: isExceeded ? Colors.red : scheme.onSurface),
                    ),
                  ],
                ),
                Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isExceeded ? Colors.red : scheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: scheme.outline.withOpacity(0.1),
                color: isExceeded ? Colors.red : scheme.primary,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: $currency${exp.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Limit: $currency${limit.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildSectionHeader(ThemeData theme, String title, String? trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
            child: Text(trailing, style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }



  Widget _buildRecentTransactions(List<dynamic> items, String currency, WidgetRef ref) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          final isExpense = item is Expense;
          final color = isExpense ? Colors.red : Colors.green;
          final title = isExpense ? item.title : item.title;
          final amt = isExpense ? item.amount : item.amount;
          final details = isExpense ? '${item.category} • ${item.paymentMethod}' : item.category;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(isExpense ? Icons.arrow_upward : Icons.arrow_downward, color: color, size: 18),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(details),
            trailing: Text(
              '${isExpense ? "-" : "+"}$currency${amt.toStringAsFixed(1)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentNotes(List<dynamic> notesList, ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemCount: notesList.length,
      itemBuilder: (context, index) {
        final note = notesList[index];
        final isDarkMode = theme.brightness == Brightness.dark;
        final noteBgColor = isDarkMode ? const Color(0xFF0E2012) : const Color(0xFFE8F5E9);
        final noteTextColor = isDarkMode ? Colors.white70 : Colors.black87;
        final noteSubColor = isDarkMode ? Colors.white60 : Colors.black54;

        return Card(
          elevation: 0,
          color: noteBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isDarkMode ? const Color(0xFF1B3C22) : const Color(0xFFE2EFE7)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: noteTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    note.content.isNotEmpty ? note.content : (note.checklist.isNotEmpty ? note.checklist.join(', ') : ''),
                    style: TextStyle(
                      fontSize: 10,
                      color: noteSubColor,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyStateCard(String message, IconData icon, ColorScheme scheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: scheme.outline.withOpacity(0.1))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 36, color: scheme.outline.withOpacity(0.4)),
              const SizedBox(height: 8),
              Text(message, style: TextStyle(color: scheme.outline, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
