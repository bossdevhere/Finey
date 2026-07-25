import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense.dart';
import '../models/income.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _selectedPeriod = 'Monthly'; // Daily, Weekly, Monthly, Yearly

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider);
    final incomes = ref.watch(incomeProvider);
    final settings = ref.watch(settingsProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filtered data based on selection
    final filteredExpenses = _filterExpenses(expenses);
    final filteredIncomes = _filterIncomes(incomes);

    // Totals
    final double totalExpense = filteredExpenses.fold(0, (sum, item) => sum + item.amount);
    final double totalIncome = filteredIncomes.fold(0, (sum, item) => sum + item.amount);
    final double netSavings = totalIncome - totalExpense;

    // Stat: Average Daily Expense
    final double avgDailyExpense = _calculateAvgDaily(filteredExpenses);

    // Stat: Highest spending category
    final categoryTotals = _getCategoryTotals(filteredExpenses);
    String highestCategory = 'N/A';
    double highestAmt = 0.0;
    categoryTotals.forEach((cat, amt) {
      if (amt > highestAmt) {
        highestAmt = amt;
        highestCategory = cat;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Analytics'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Period Selector Segmented Button
            _buildPeriodSelector(colorScheme),
            const SizedBox(height: 20),

            // Financial Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Income',
                    '${settings.currency}${totalIncome.toStringAsFixed(0)}',
                    const Color(0xFF10B981),
                    Icons.arrow_downward_rounded,
                    colorScheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Expenses',
                    '${settings.currency}${totalExpense.toStringAsFixed(0)}',
                    const Color(0xFFEF4444),
                    Icons.arrow_upward_rounded,
                    colorScheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Net Savings',
              '${settings.currency}${netSavings.toStringAsFixed(0)}',
              netSavings >= 0 ? const Color(0xFF6366F1) : const Color(0xFFF97316),
              Icons.savings_outlined,
              colorScheme,
              isFullWidth: true,
            ),
            const SizedBox(height: 24),

            // Pie Chart: Category breakdown
            _sectionTitle('Category Distribution', colorScheme),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline, width: 1),
              ),
              padding: const EdgeInsets.all(20.0),
              child: categoryTotals.isEmpty
                  ? SizedBox(
                      height: 180,
                      child: Center(
                        child: Text(
                          'No expense data to analyze',
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 180,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 36,
                                sections: _buildPieSections(categoryTotals, colorScheme),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: categoryTotals.entries.map((entry) {
                              final color = _getCategoryColor(entry.key, colorScheme);
                              final pct = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${entry.key} (${pct.toStringAsFixed(0)}%)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // Line Chart: Spending & Income Trends
            _sectionTitle('Financial Trends', colorScheme),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline, width: 1),
              ),
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                height: 200,
                child: (expenses.isEmpty && incomes.isEmpty)
                    ? Center(
                        child: Text(
                          'No trend data logged yet',
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            // Expenses line
                            LineChartBarData(
                              spots: _buildLineSpots(expenses),
                              isCurved: true,
                              color: const Color(0xFFEF4444),
                              barWidth: 3.5,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: true, color: const Color(0xFFEF4444).withOpacity(0.1)),
                            ),
                            // Incomes line
                            LineChartBarData(
                              spots: _buildLineSpotsForIncome(incomes),
                              isCurved: true,
                              color: const Color(0xFF10B981),
                              barWidth: 3.5,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: true, color: const Color(0xFF10B981).withOpacity(0.1)),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Key Insights Card
            _sectionTitle('Key Insights', colorScheme),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline, width: 1),
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildInsightRow('Highest Spending Category', highestCategory, colorScheme),
                  Divider(color: colorScheme.outline, height: 20),
                  _buildInsightRow('Average Daily Spending', '${settings.currency}${avgDailyExpense.toStringAsFixed(1)}', colorScheme),
                  Divider(color: colorScheme.outline, height: 20),
                  _buildInsightRow('Current Savings Margin', '${settings.currency}${netSavings.toStringAsFixed(0)}', colorScheme),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(ColorScheme colorScheme) {
    final periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: Row(
        children: periods.map((p) {
          final isSelected = _selectedPeriod == p;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = p;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  p,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatCard(String title, String val, Color accentColor, IconData icon, ColorScheme colorScheme, {bool isFullWidth = false}) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                val,
                style: TextStyle(
                  fontSize: isFullWidth ? 26 : 22,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String title, String val, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            val,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: colorScheme.onSurface,
      ),
    );
  }

  // Helper calculation functions
  List<Expense> _filterExpenses(List<Expense> list) {
    final now = DateTime.now();
    if (_selectedPeriod == 'Daily') {
      return list.where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day).toList();
    } else if (_selectedPeriod == 'Weekly') {
      final start = now.subtract(const Duration(days: 7));
      return list.where((e) => e.date.isAfter(start)).toList();
    } else if (_selectedPeriod == 'Monthly') {
      return list.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    } else {
      return list.where((e) => e.date.year == now.year).toList();
    }
  }

  List<Income> _filterIncomes(List<Income> list) {
    final now = DateTime.now();
    if (_selectedPeriod == 'Daily') {
      return list.where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day).toList();
    } else if (_selectedPeriod == 'Weekly') {
      final start = now.subtract(const Duration(days: 7));
      return list.where((e) => e.date.isAfter(start)).toList();
    } else if (_selectedPeriod == 'Monthly') {
      return list.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    } else {
      return list.where((e) => e.date.year == now.year).toList();
    }
  }

  double _calculateAvgDaily(List<Expense> list) {
    if (list.isEmpty) return 0.0;
    if (_selectedPeriod == 'Daily') return list.fold(0.0, (sum, e) => sum + e.amount);

    final dates = list.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet();
    final total = list.fold(0.0, (sum, e) => sum + e.amount);
    return total / (dates.isEmpty ? 1 : dates.length);
  }

  Map<String, double> _getCategoryTotals(List<Expense> list) {
    final Map<String, double> data = {};
    for (var item in list) {
      data[item.category] = (data[item.category] ?? 0.0) + item.amount;
    }
    return data;
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> totals, ColorScheme scheme) {
    return totals.entries.map((entry) {
      final color = _getCategoryColor(entry.key, scheme);
      return PieChartSectionData(
        value: entry.value,
        title: '',
        color: color,
        radius: 18,
      );
    }).toList();
  }

  Color _getCategoryColor(String category, ColorScheme scheme) {
    switch (category) {
      case 'Food':
        return const Color(0xFFF59E0B);
      case 'Shopping':
        return const Color(0xFF8B5CF6);
      case 'Travel':
        return const Color(0xFF3B82F6);
      case 'Bills':
        return const Color(0xFFEF4444);
      case 'Health':
        return const Color(0xFF10B981);
      case 'Entertainment':
        return const Color(0xFFEC4899);
      case 'Education':
        return const Color(0xFF14B8A6);
      case 'Fuel':
        return const Color(0xFFEAB308);
      default:
        return scheme.onSurfaceVariant;
    }
  }

  List<FlSpot> _buildLineSpots(List<Expense> list) {
    if (list.isEmpty) return [const FlSpot(0, 0)];
    list.sort((a, b) => a.date.compareTo(b.date));
    final double maxVal = list.fold(0, (max, e) => e.amount > max ? e.amount : max);
    return list.map((e) {
      final index = list.indexOf(e).toDouble();
      return FlSpot(index, maxVal > 0 ? (e.amount / maxVal) * 10 : 0.0);
    }).toList();
  }

  List<FlSpot> _buildLineSpotsForIncome(List<Income> list) {
    if (list.isEmpty) return [const FlSpot(0, 0)];
    list.sort((a, b) => a.date.compareTo(b.date));
    final double maxVal = list.fold(0, (max, e) => e.amount > max ? e.amount : max);
    return list.map((e) {
      final index = list.indexOf(e).toDouble();
      return FlSpot(index, maxVal > 0 ? (e.amount / maxVal) * 10 : 0.0);
    }).toList();
  }
}
