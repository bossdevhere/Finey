import 'package:flutter/material.dart';

class CalculatorWidget extends StatefulWidget {
  final ValueChanged<String>? onExpressionEvaluated;

  const CalculatorWidget({super.key, this.onExpressionEvaluated});

  @override
  State<CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<CalculatorWidget> {
  String _input = '';
  String _result = '0';
  final List<String> _history = [];
  bool _showHistory = false;

  void _onKeyPress(String value) {
    setState(() {
      if (value == 'C') {
        _input = '';
        _result = '0';
      } else if (value == '⌫') {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      } else if (value == '=') {
        _evaluateExpression();
      } else if (value == '%') {
        if (_input.isNotEmpty) {
          _input += '/100';
          _evaluateExpression();
        }
      } else {
        _input += value;
      }
    });
  }

  void _evaluateExpression() {
    if (_input.isEmpty) return;
    try {
      String formattedInput = _input.replaceAll('×', '*').replaceAll('÷', '/');
      double evaluated = _customEval(formattedInput);
      
      String res = evaluated.toString();
      if (res.endsWith('.0')) {
        res = res.substring(0, res.length - 2);
      }
      
      setState(() {
        _result = res;
        _history.insert(0, '$_input = $_result');
        if (_history.length > 20) {
          _history.removeLast();
        }
      });
      if (widget.onExpressionEvaluated != null) {
        widget.onExpressionEvaluated!(_result);
      }
    } catch (e) {
      setState(() {
        _result = 'Error';
      });
    }
  }

  double _customEval(String expression) {
    return _parseAdditionSubtraction(expression);
  }

  double _parseAdditionSubtraction(String expression) {
    List<String> parts = [];
    int start = 0;
    int parenthesisCount = 0;

    for (int i = 0; i < expression.length; i++) {
      if (expression[i] == '(') parenthesisCount++;
      if (expression[i] == ')') parenthesisCount--;
      if (parenthesisCount == 0 && (expression[i] == '+' || expression[i] == '-')) {
        parts.add(expression.substring(start, i));
        parts.add(expression[i]);
        start = i + 1;
      }
    }
    parts.add(expression.substring(start));

    double total = _parseMultiplicationDivision(parts[0]);
    for (int i = 1; i < parts.length; i += 2) {
      String op = parts[i];
      double val = _parseMultiplicationDivision(parts[i + 1]);
      if (op == '+') {
        total += val;
      } else {
        total -= val;
      }
    }
    return total;
  }

  double _parseMultiplicationDivision(String expression) {
    List<String> parts = [];
    int start = 0;
    for (int i = 0; i < expression.length; i++) {
      if (expression[i] == '*' || expression[i] == '/') {
        parts.add(expression.substring(start, i));
        parts.add(expression[i]);
        start = i + 1;
      }
    }
    parts.add(expression.substring(start));

    double total = double.parse(parts[0].trim());
    for (int i = 1; i < parts.length; i += 2) {
      String op = parts[i];
      double val = double.parse(parts[i + 1].trim());
      if (op == '*') {
        total *= val;
      } else {
        if (val == 0) throw Exception("Division by zero");
        total /= val;
      }
    }
    return total;
  }

  Widget _buildButton(String text, {Color? bg, Color? fg, bool isDouble = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color buttonBg = bg ?? colorScheme.outlineVariant;
    Color buttonFg = fg ?? colorScheme.onSurface;

    return Expanded(
      flex: isDouble ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: InkWell(
          onTap: () => _onKeyPress(text),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.center,
            height: 56,
            decoration: BoxDecoration(
              color: buttonBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: buttonFg,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Material(
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        side: BorderSide(color: colorScheme.outline, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: bottomInset > 0 ? bottomInset + 16 : bottomPadding + 24,
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calculator',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(
                  _showHistory ? Icons.keyboard_rounded : Icons.history_rounded,
                  color: colorScheme.onSurface,
                ),
                onPressed: () => setState(() => _showHistory = !_showHistory),
              ),
            ],
          ),

          if (_showHistory) ...[
            // History list
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 240,
              child: _history.isEmpty
                  ? Center(
                      child: Text(
                        'No history yet',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            _history[index],
                            style: TextStyle(fontSize: 15, color: colorScheme.onSurface, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right,
                          ),
                          onTap: () {
                            setState(() {
                              _input = _history[index].split(' = ')[0];
                              _showHistory = false;
                            });
                          },
                        );
                      },
                    ),
            ),
          ] else ...[
            // Screen area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _input.isEmpty ? '0' : _input,
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _result,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Numpad rows
            Column(
              children: [
                Row(
                  children: [
                    _buildButton('C', bg: const Color(0xFFEF4444).withValues(alpha: 0.15), fg: const Color(0xFFEF4444)),
                    _buildButton('⌫', bg: colorScheme.outlineVariant),
                    _buildButton('%', bg: colorScheme.outlineVariant),
                    _buildButton('÷', bg: colorScheme.primary, fg: colorScheme.onPrimary),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('7'),
                    _buildButton('8'),
                    _buildButton('9'),
                    _buildButton('×', bg: colorScheme.primary, fg: colorScheme.onPrimary),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('4'),
                    _buildButton('5'),
                    _buildButton('6'),
                    _buildButton('-', bg: colorScheme.primary, fg: colorScheme.onPrimary),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('1'),
                    _buildButton('2'),
                    _buildButton('3'),
                    _buildButton('+', bg: colorScheme.primary, fg: colorScheme.onPrimary),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('0', isDouble: true),
                    _buildButton('.'),
                    _buildButton('=', bg: colorScheme.primary, fg: colorScheme.onPrimary),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
  }
}
