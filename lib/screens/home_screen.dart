import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/note_provider.dart';
import '../providers/settings_provider.dart';
import 'calendar_screen.dart';
import 'history_screen.dart';
import '../models/expense.dart';
import '../models/transaction_item.dart';

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
    final isDarkMode = theme.brightness == Brightness.dark;

    // Filter Current Month data
    final now = DateTime.now();
    final monthlyExpenses = expenses.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    final monthlyIncomes = incomes.where((i) => i.date.year == now.year && i.date.month == now.month).toList();

    final double totalIncome = monthlyIncomes.fold(0, (sum, i) => sum + i.amount);
    final double totalExpense = monthlyExpenses.fold(0, (sum, e) => sum + e.amount);
    final double balance = totalIncome - totalExpense;
    final double savings = balance > 0 ? balance : 0;

    // Budget Limit Alert
    final bool isBudgetExceeded = settings.monthlyBudget > 0 && totalExpense > settings.monthlyBudget;
    final double budgetPercent = settings.monthlyBudget > 0
        ? (totalExpense / settings.monthlyBudget).clamp(0.0, 1.0)
        : 0.0;

    // Combined recent transactions (strongly typed)
    final recentItems = <TransactionItem>[...expenses, ...incomes];
    recentItems.sort((a, b) => b.date.compareTo(a.date));
    final displayTransactions = recentItems.take(3).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: colorScheme.primary,
          onRefresh: () async {},
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Finey',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildHeaderIconButton(
                        icon: Icons.calendar_month_rounded,
                        tooltip: 'Calendar',
                        colorScheme: colorScheme,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CalendarScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Elegant Gradient Balance Card
              _buildBalanceCard(colorScheme, settings.currency, totalIncome, totalExpense, savings, balance, isDarkMode),
              const SizedBox(height: 16),

              // Budget Progress Tracker
              if (settings.monthlyBudget > 0)
                _buildBudgetTracker(colorScheme, settings.currency, totalExpense, settings.monthlyBudget, budgetPercent, isBudgetExceeded),

              const SizedBox(height: 24),

              // Recent Transactions Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (displayTransactions.isEmpty)
                _buildEmptyStateCard('No transactions logged yet', Icons.receipt_long_outlined, colorScheme)
              else
                _buildRecentTransactions(displayTransactions, settings.currency, colorScheme),
              const SizedBox(height: 24),

              // Recent Notes Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Notes & Lists',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (notes.isEmpty)
                _buildEmptyStateCard('No notes created', Icons.edit_note_rounded, colorScheme)
              else
                _buildRecentNotes(notes.take(3).toList(), colorScheme),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required String tooltip,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: colorScheme.onSurface),
        tooltip: tooltip,
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildBalanceCard(ColorScheme scheme, String currency, double inc, double exp, double sav, double bal, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isDarkMode
              ? const [Color(0xFF18181B), Color(0xFF27272A)]
              : const [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL NET BALANCE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$currency${bal.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCardStatItem('Income', '$currency${inc.toStringAsFixed(0)}', Icons.arrow_downward_rounded, const Color(0xFF34D399)),
              _buildCardStatItem('Expenses', '$currency${exp.toStringAsFixed(0)}', Icons.arrow_upward_rounded, const Color(0xFFF87171)),
              _buildCardStatItem('Savings', '$currency${sav.toStringAsFixed(0)}', Icons.savings_outlined, const Color(0xFFFBBF24)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCardStatItem(String label, String value, IconData icon, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 12),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetTracker(ColorScheme scheme, String currency, double exp, double limit, double percent, bool isExceeded) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExceeded ? scheme.error.withValues(alpha: 0.5) : scheme.outline,
          width: 1,
        ),
      ),
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
                    isExceeded ? Icons.warning_amber_rounded : Icons.donut_large_rounded,
                    color: isExceeded ? scheme.error : scheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isExceeded ? 'Monthly Budget Exceeded!' : 'Monthly Budget Planner',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isExceeded ? scheme.error : scheme.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isExceeded ? scheme.error : scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: scheme.outlineVariant,
              color: isExceeded ? scheme.error : scheme.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: $currency${exp.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
              ),
              Text(
                'Limit: $currency${limit.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List<TransactionItem> items, String currency, ColorScheme scheme) {
    return Material(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outline, width: 1),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: scheme.outline),
        itemBuilder: (context, index) {
          final item = items[index];
          final isExpense = item.isExpense;
          final color = isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981);
          final title = item.title;
          final amt = item.amount;
          final details = isExpense && item is Expense
              ? '${item.category} • ${item.paymentMethod}'
              : item.category;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: color,
                size: 18,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: scheme.onSurface),
            ),
            subtitle: Text(
              details,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            trailing: Text(
              '${isExpense ? "-" : "+"}$currency${amt.toStringAsFixed(2)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentNotes(List<dynamic> notesList, ColorScheme scheme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: notesList.length,
      itemBuilder: (context, index) {
        final note = notesList[index];
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline, width: 1),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: scheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  note.content.isNotEmpty
                      ? note.content
                      : (note.checklist.isNotEmpty ? note.checklist.join(', ') : ''),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyStateCard(String message, IconData icon, ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline, width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 32, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
