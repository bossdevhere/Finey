import 'package:flutter_test/flutter_test.dart';

double evaluateBasicExpression(String expression) {
  // Simple evaluator helper for test validation
  final cleanExpr = expression.replaceAll(' ', '');
  if (cleanExpr.contains('+')) {
    final parts = cleanExpr.split('+');
    return double.parse(parts[0]) + double.parse(parts[1]);
  } else if (cleanExpr.contains('-')) {
    final parts = cleanExpr.split('-');
    return double.parse(parts[0]) - double.parse(parts[1]);
  } else if (cleanExpr.contains('*')) {
    final parts = cleanExpr.split('*');
    return double.parse(parts[0]) * double.parse(parts[1]);
  } else if (cleanExpr.contains('/')) {
    final parts = cleanExpr.split('/');
    return double.parse(parts[0]) / double.parse(parts[1]);
  }
  return double.parse(cleanExpr);
}

void main() {
  group('Calculator Math Evaluator Tests', () {
    test('Addition evaluation', () {
      expect(evaluateBasicExpression('150 + 50'), equals(200.0));
    });

    test('Subtraction evaluation', () {
      expect(evaluateBasicExpression('500 - 120'), equals(380.0));
    });

    test('Multiplication evaluation', () {
      expect(evaluateBasicExpression('25 * 4'), equals(100.0));
    });

    test('Division evaluation', () {
      expect(evaluateBasicExpression('100 / 5'), equals(20.0));
    });
  });
}
