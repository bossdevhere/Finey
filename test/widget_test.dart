import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/models/expense.dart';
import 'package:finovo/models/income.dart';
import 'package:finovo/models/settings.dart';

void main() {
  group('Finovo Data Model & Business Logic Unit Tests', () {
    test('Expense model creation and copyWith test', () {
      final expense = Expense(
        id: '123',
        title: 'Grocery Shopping',
        amount: 450.50,
        category: 'Food',
        description: 'Supermarket purchase',
        date: DateTime(2026, 7, 28),
        paymentMethod: 'UPI',
      );

      expect(expense.id, equals('123'));
      expect(expense.amount, equals(450.50));
      expect(expense.isExpense, isTrue);
      expect(expense.noteOrDescription, equals('Supermarket purchase'));

      final updated = expense.copyWith(amount: 500.00);
      expect(updated.amount, equals(500.00));
      expect(updated.title, equals('Grocery Shopping'));
    });

    test('Income model creation and copyWith test', () {
      final income = Income(
        id: 'inc-1',
        title: 'Monthly Salary',
        amount: 85000.00,
        category: 'Salary',
        date: DateTime(2026, 7, 1),
        notes: 'Direct deposit',
      );

      expect(income.id, equals('inc-1'));
      expect(income.amount, equals(85000.00));
      expect(income.isExpense, isFalse);
      expect(income.noteOrDescription, equals('Direct deposit'));
    });

    test('Settings model copyWith and defaults test', () {
      final settings = Settings(
        isDarkMode: true,
        themeColor: 0xFF10B981,
        currency: '₹',
        monthlyBudget: 30000.00,
      );

      expect(settings.currency, equals('₹'));
      expect(settings.monthlyBudget, equals(30000.00));

      final updatedSettings = settings.copyWith(currency: '\$', monthlyBudget: 50000.00);
      expect(updatedSettings.currency, equals('\$'));
      expect(updatedSettings.monthlyBudget, equals(50000.00));
      expect(updatedSettings.isDarkMode, isTrue);
    });
  });
}
