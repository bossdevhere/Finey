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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period Selector
          _buildPeriodSelector(colorScheme),
          const SizedBox(height: 16),

          // Core Financial Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Income',
                  '${settings.currency}${totalIncome.toStringAsFixed(0)}',
                  Colors.green,
                  Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Expenses',
                  '${settings.currency}${totalExpense.toStringAsFixed(0)}',
                  Colors.red,
                  Icons.arrow_upward,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Net Savings',
            '${settings.currency}${netSavings.toStringAsFixed(0)}',
            netSavings >= 0 ? Colors.teal : Colors.deepOrange,
            Icons.savings_outlined,
            isFullWidth: true,
          ),
          const SizedBox(height: 20),

          // Pie Chart: Category breakdown
          _sectionTitle('Category Distribution'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: categoryTotals.isEmpty
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: Text('No expense data to analyze')),
                    )
                  : Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
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
                              final pct = (entry.value / totalExpense) * 100;
                              return Row(
                                children: [
                                  Container(width: 10, height: 10, color: color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${entry.key} (${pct.toStringAsFixed(0)}%)',
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Bar Chart: Weekly or monthly expenses
          _sectionTitle('Expense History'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 200,
                child: filteredExpenses.isEmpty
                    ? const Center(child: Text('No historical transaction data'))
                    : BarChart(
                        BarChartData(
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return _getBarLabels(value, filteredExpenses);
                                },
                              ),
                            ),
                          ),
                          barGroups: _buildBarGroups(filteredExpenses, colorScheme),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Line Chart: Income vs Expense Trend
          _sectionTitle('Income vs Expense Trend'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 200,
                child: (expenses.isEmpty && incomes.isEmpty)
                    ? const Center(child: Text('No trend data available'))
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
                              color: Colors.redAccent,
                              barWidth: 4,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: true, color: Colors.redAccent.withOpacity(0.1)),
                            ),
                            // Incomes line
                            LineChartBarData(
                              spots: _buildLineSpotsForIncome(incomes),
                              isCurved: true,
                              color: Colors.greenAccent,
                              barWidth: 4,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: true, color: Colors.greenAccent.withOpacity(0.1)),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick statistics cards
          _sectionTitle('Key Insights'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInsightRow('Highest Spending Category', highestCategory, colorScheme),
                  const Divider(),
                  _buildInsightRow('Average Daily Spending', '${settings.currency}${avgDailyExpense.toStringAsFixed(1)}', colorScheme),
                  const Divider(),
                  _buildInsightRow('Current Savings Margin', '${settings.currency}${netSavings.toStringAsFixed(0)}', colorScheme),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(ColorScheme colorScheme) {
    final periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
    return Center(
      child: SegmentedButton<String>(
        segments: periods.map((p) => ButtonSegment(value: p, label: Text(p))).toList(),
        selected: {_selectedPeriod},
        onSelectionChanged: (newSelection) {
          setState(() {
            _selectedPeriod = newSelection.first;
          });
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String val, Color color, IconData icon, {bool isFullWidth = false}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(val, style: TextStyle(fontSize: isFullWidth ? 26 : 22, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            Icon(icon, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(String title, String val, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: colorScheme.outline, fontWeight: FontWeight.w500)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // --- Filtering & Calculation Helpers ---
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
        return Colors.orangeAccent;
      case 'Shopping':
        return Colors.purpleAccent;
      case 'Travel':
        return Colors.blueAccent;
      case 'Bills':
        return Colors.redAccent;
      case 'Health':
        return Colors.greenAccent;
      case 'Entertainment':
        return Colors.pinkAccent;
      case 'Education':
        return Colors.tealAccent;
      case 'Fuel':
        return Colors.yellowAccent;
      default:
        return Colors.grey;
    }
  }

  List<BarChartGroupData> _buildBarGroups(List<Expense> list, ColorScheme scheme) {
    final Map<int, double> grouped = {};
    // Group by day of week or month depending on period
    if (_selectedPeriod == 'Daily' || _selectedPeriod == 'Weekly') {
      for (var e in list) {
        final day = e.date.weekday;
        grouped[day] = (grouped[day] ?? 0.0) + e.amount;
      }
    } else {
      for (var e in list) {
        final dayIndex = (e.date.day / 5).floor() + 1; // Group into 5-day intervals
        grouped[dayIndex] = (grouped[dayIndex] ?? 0.0) + e.amount;
      }
    }

    final List<BarChartGroupData> groups = [];
    grouped.forEach((key, val) {
      groups.add(
        BarChartGroupData(
          x: key,
          barRods: [
            BarChartRodData(
              toY: val,
              color: scheme.primary,
              width: 14,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      );
    });

    groups.sort((a, b) => a.x.compareTo(b.x));
    return groups;
  }

  Widget _getBarLabels(double value, List<Expense> list) {
    final style = TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold);
    if (_selectedPeriod == 'Daily' || _selectedPeriod == 'Weekly') {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      int index = value.toInt() - 1;
      if (index >= 0 && index < weekdays.length) {
        return Text(weekdays[index], style: style);
      }
    } else {
      int index = value.toInt();
      return Text('P$index', style: style); // Period chunk (e.g. part of month)
    }
    return const Text('');
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
