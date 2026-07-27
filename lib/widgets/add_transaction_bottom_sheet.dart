import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense.dart';
import '../models/income.dart';
import 'calculator_widget.dart';

class AddTransactionBottomSheet extends ConsumerStatefulWidget {
  const AddTransactionBottomSheet({super.key});

  @override
  ConsumerState<AddTransactionBottomSheet> createState() => _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends ConsumerState<AddTransactionBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers & Form variables
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _expenseCategory = 'Food';
  String _incomeCategory = 'Salary';
  String _paymentMethod = 'Cash';
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    final rawTitle = _titleController.text.trim();
    final amtText = _amountController.text.trim();
    final double? amount = double.tryParse(amtText);

    setState(() {
      if (amtText.isEmpty) {
        _amountError = 'Amount is required';
      } else if (amount == null || amount <= 0) {
        _amountError = 'Please enter a valid positive amount';
      } else {
        _amountError = null;
      }
    });

    if (_amountError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _amountError!,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final double validAmount = amount!;
    final isExpense = _tabController.index == 0;
    final title = rawTitle.isEmpty ? (isExpense ? _expenseCategory : _incomeCategory) : rawTitle;

    if (isExpense) {
      final exp = Expense(
        id: const Uuid().v4(),
        title: title,
        amount: validAmount,
        category: _expenseCategory,
        description: _descController.text.trim(),
        date: _selectedDate,
        paymentMethod: _paymentMethod,
      );
      ref.read(expenseProvider.notifier).addExpense(exp);
    } else {
      final inc = Income(
        id: const Uuid().v4(),
        title: title,
        amount: validAmount,
        category: _incomeCategory,
        date: _selectedDate,
        notes: _descController.text.trim(),
      );
      ref.read(incomeProvider.notifier).addIncome(inc);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final expCategories = ref.read(expenseCategoriesProvider);
    final incCategories = ref.read(incomeCategoriesProvider);
    final payMethods = ref.read(paymentMethodsProvider);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isExpenseTab = _tabController.index == 0;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomInset > 0 ? bottomInset + 16 : bottomPadding + 24,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Tab bar for Expense vs Income
            Container(
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: colorScheme.onSurface,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(
                    height: 38,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_upward_rounded, color: Color(0xFFEF4444), size: 16),
                        SizedBox(width: 6),
                        Text('Expense'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 38,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 6),
                        Text('Income'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Title Input
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                labelText: 'Title / Description (Optional)',
                hintText: 'e.g. Grocery, Salary, Coffee',
              ),
            ),
            const SizedBox(height: 14),

            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600),
              onChanged: (_) {
                if (_amountError != null) {
                  setState(() => _amountError = null);
                }
              },
              decoration: InputDecoration(
                labelText: 'Amount *',
                errorText: _amountError,
                prefixText: '${ref.read(settingsProvider).currency} ',
                prefixStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 14),

            // Category & Pay Mode dropdowns
            if (isExpenseTab) ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: expCategories.contains(_expenseCategory) ? _expenseCategory : expCategories.first,
                      isExpanded: true,
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: expCategories.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _expenseCategory = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: payMethods.contains(_paymentMethod) ? _paymentMethod : payMethods.first,
                      isExpanded: true,
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        labelText: 'Pay Mode',
                      ),
                      items: payMethods.map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _paymentMethod = val);
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                value: incCategories.contains(_incomeCategory) ? _incomeCategory : incCategories.first,
                isExpanded: true,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  labelText: 'Source Category',
                ),
                items: incCategories.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _incomeCategory = val);
                },
              ),
            ],
            const SizedBox(height: 14),

            // Description input
            TextField(
              controller: _descController,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
              ),
            ),
            const SizedBox(height: 20),

            // Date picker, Calculator & Save Entry row
            Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: colorScheme.outline, width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  icon: Icon(Icons.calendar_today_rounded, size: 16, color: colorScheme.onSurface),
                  label: Text(
                    DateFormat('dd MMM').format(_selectedDate),
                    style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.calculate_outlined, color: colorScheme.onSurface),
                  tooltip: 'Open Calculator',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CalculatorWidget(
                        onExpressionEvaluated: (val) {
                          setState(() {
                            _amountController.text = val;
                          });
                        },
                      ),
                    );
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                  ),
                  onPressed: _saveTransaction,
                  child: const Text('Save Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
