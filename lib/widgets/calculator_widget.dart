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
  List<String> _history = [];
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
      // Simple parser for safety and offline execution
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
    // A clean, simple double expression parser for standard operators (+, -, *, /)
    // Supports BODMAS hierarchy
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
    
    Color buttonBg = bg ?? colorScheme.surfaceVariant;
    Color buttonFg = fg ?? colorScheme.onSurfaceVariant;

    return Expanded(
      flex: isDouble ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: InkWell(
          onTap: () => _onKeyPress(text),
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.center,
            height: 64,
            decoration: BoxDecoration(
              color: buttonBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 22,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calculator',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              IconButton(
                icon: Icon(
                  _showHistory ? Icons.keyboard : Icons.history,
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
              height: 250,
              child: _history.isEmpty
                  ? Center(
                      child: Text(
                        'No history yet',
                        style: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            _history[index],
                            style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _input.isEmpty ? '0' : _input,
                    style: TextStyle(
                      fontSize: 20,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _result,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
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
                    _buildButton('C', bg: colorScheme.errorContainer, fg: colorScheme.onErrorContainer),
                    _buildButton('⌫', bg: colorScheme.secondaryContainer),
                    _buildButton('%', bg: colorScheme.secondaryContainer),
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
                    _buildButton('=', bg: colorScheme.primaryContainer, fg: colorScheme.onPrimaryContainer),
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
