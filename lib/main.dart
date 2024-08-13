import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(CalculatorApp());
}

class CalculatorApp extends StatefulWidget {
  @override
  _CalculatorAppState createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  bool _isDarkMode = false;
  bool _isScientificMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: CalculatorScreen(
        isDarkMode: _isDarkMode,
        isScientificMode: _isScientificMode,
        onThemeChanged: _toggleTheme,
        onScientificModeChanged: _toggleScientificMode,
      ),
    );
  }

  void _toggleTheme(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  void _toggleScientificMode(bool isScientificMode) {
    setState(() {
      _isScientificMode = isScientificMode;
    });
  }
}

class CalculatorScreen extends StatefulWidget {
  final bool isDarkMode;
  final bool isScientificMode;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<bool> onScientificModeChanged;

  CalculatorScreen({
    required this.isDarkMode,
    required this.isScientificMode,
    required this.onThemeChanged,
    required this.onScientificModeChanged,
  });

  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _output = "0";
  String _expression = "";
  bool _isButtonSoundOn = false;
  List<String> _history = [];

  void _buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "AC") {
        _output = "0";
        _expression = "";
      } else if (buttonText == "=") {
        _evaluateExpression();
      } else if (buttonText == "+/-") {
        if (_expression.isNotEmpty) {
          // Find the last number in the expression
          RegExp regExp = RegExp(r'(\d*\.?\d+)(?![\d\.])');
          Iterable<RegExpMatch> matches = regExp.allMatches(_expression);
          if (matches.isNotEmpty) {
            String? lastNumber = matches.last.group(0);
            if (lastNumber != null) {
              double currentValue = double.parse(lastNumber);
              String negatedValue = (-currentValue).toString();

              // Avoid showing decimal if not needed
              if (negatedValue.endsWith('.0')) {
                negatedValue =
                    negatedValue.substring(0, negatedValue.length - 2);
              }

              // Replace the last number in the expression with its negated value
              _expression = _expression.substring(0, matches.last.start) +
                  negatedValue +
                  _expression.substring(matches.last.end);
              _output = _expression;
            }
          }
        }
      } else if (buttonText == "%") {
        if (_expression.isNotEmpty &&
            !_expression.contains(RegExp(r'[+\-×÷]'))) {
          double currentValue = double.parse(_expression);
          _expression = (currentValue / 100).toString();
          _output = _expression;
        }
      } else if (widget.isScientificMode) {
        if (buttonText == "log" ||
            buttonText == "sin" ||
            buttonText == "cos" ||
            buttonText == "tan") {
          if (_expression.isNotEmpty && RegExp(r'\d$').hasMatch(_expression)) {
            _expression += ' × $buttonText(';
          } else {
            _expression += '$buttonText(';
          }
        } else if (buttonText == "deg" || buttonText == "rad") {
          if (_expression.isNotEmpty && RegExp(r'\d$').hasMatch(_expression)) {
            _expression += ' × $buttonText(';
          } else {
            _expression += '$buttonText(';
          }
        } else if (buttonText == "x²") {
          _expression += '^2';
        } else if (buttonText == "x³") {
          _expression += '^3';
        } else if (buttonText == "xⁿ") {
          _expression += '^';
        } else if (buttonText == "π") {
          if (_expression.isNotEmpty && RegExp(r'\d$').hasMatch(_expression)) {
            _expression += ' * 3.141592653589793';
          } else {
            _expression += '3.141592653589793';
          }
        } else if (buttonText == "√") {
          _expression += 'sqrt(';
        } else if (buttonText == "10ⁿ") {
          _expression += '10^';
        } else if (buttonText == "x!") {
          _expression += '!';
        } else {
          _expression += buttonText;
        }
        _output = _expression;
      } else {
        if (_expression == "0" && buttonText != ".") {
          _expression = buttonText;
        } else {
          _expression += buttonText;
        }
        _output = _expression;
      }
    });
  }

  // Function to format the output

  void _evaluateExpression() {
    try {
      // Store the original expression for history
      String originalExpression = _expression;

      // Preprocess the expression: Replace custom operators with standard ones
      String processedExpression = _expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('log(', 'log10(') // Convert custom log to base 10
          .replaceAll('ln(', 'log(') // Natural logarithm
          .replaceAll('π', '3.141592653589793'); // Replace π with its value

      // Add support for exponentiation and square roots
      processedExpression = processedExpression
          .replaceAll('sqrt(', 'pow(') // Replace sqrt() with pow()
          .replaceAll('^', '**'); // Replace ^ with ** for exponentiation

      // Parse and evaluate the expression
      Parser p = Parser();
      Expression exp = p.parse(processedExpression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      // Check if the result is a whole number
      if (eval == eval.toInt()) {
        _output =
            eval.toInt().toString(); // Convert to integer if no decimal part
      } else {
        _output = eval.toString(); // Keep as double if there's a decimal part
      }

      // Update the expression with the result
      _expression = originalExpression; // Restore the original expression

      // Add the evaluated expression to history
      _history.add('$originalExpression = $_output');
    } catch (e) {
      // If there's an error during evaluation, output "Error"
      _output = "Error";
      _expression = ""; // Optionally clear the expression
    }
  }

  String _handleCustomFunctions(String expression) {
    // Replace custom functions with actual calculations
    expression = expression.replaceAll(
        RegExp(r'log\(([^)]+)\)'),
        (match) {
          // Replace 'log' with 'log10' for base 10 logarithm
          return 'log10(${match.group(1)})';
        } as String);

    expression = expression.replaceAll(
        RegExp(r'deg\(([^)]+)\)'),
        (match) {
          // Convert degrees to radians
          return '(${match.group(1)} * pi / 180)';
        } as String);

    expression = expression.replaceAll(
        RegExp(r'rad\(([^)]+)\)'),
        (match) {
          // Handle radians directly
          return '${match.group(1)}';
        } as String);

    return expression;
  }

  void _backspace() {
    setState(() {
      if (_expression.isNotEmpty) {
        _expression = _expression.substring(0, _expression.length - 1);
        _output = _expression.isEmpty ? "0" : _expression;
      }
    });
  }

  String _calculateIntermediateResult() {
    try {
      String finalExpression =
          _expression.replaceAll('×', '*').replaceAll('÷', '/');
      Parser p = Parser();
      Expression exp = p.parse(finalExpression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      if (eval == eval.toInt()) {
        return eval.toInt().toString();
      } else {
        return eval.toString();
      }
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    String intermediateResult = _calculateIntermediateResult();

    return Scaffold(
      appBar: AppBar(
        title: Text('Calculator'),
        actions: [
          IconButton(
            icon: Icon(Icons.calculate, size: 26),
            onPressed: () {
              widget.onScientificModeChanged(!widget.isScientificMode);
            },
          ),
          IconButton(
            icon: Icon(Icons.history, size: 26),
            onPressed: () {
              _showHistoryDialog(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, size: 26),
            onPressed: () {
              _showSettingsDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _output,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  if (intermediateResult.isNotEmpty &&
                      _expression != intermediateResult)
                    Text(
                      '$_expression = $intermediateResult',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildButtonRow([
                  _buildButton("AC"),
                  _buildButtonWithIcon(Icons.backspace, _backspace),
                  _buildButton(widget.isScientificMode ? "log" : "+/-"),
                  _buildButton(widget.isScientificMode ? "÷" : "÷"),
                ]),
                _buildButtonRow([
                  _buildButton(widget.isScientificMode ? "x²" : "7"),
                  _buildButton(widget.isScientificMode ? "ln" : "8"),
                  _buildButton(widget.isScientificMode ? "xⁿ" : "9"),
                  _buildButton(widget.isScientificMode ? "(" : "×"),
                ]),
                _buildButtonRow([
                  _buildButton(widget.isScientificMode ? "sin" : "4"),
                  _buildButton(widget.isScientificMode ? "cos" : "5"),
                  _buildButton(widget.isScientificMode ? "tan" : "6"),
                  _buildButton(widget.isScientificMode ? ")" : "-"),
                ]),
                _buildButtonRow([
                  _buildButton(widget.isScientificMode ? "π" : "1"),
                  _buildButton(widget.isScientificMode ? "deg" : "2"),
                  _buildButton(widget.isScientificMode ? "rad" : "3"),
                  _buildButton(widget.isScientificMode ? "+" : "+"),
                ]),
                _buildButtonRow([
                  _buildButton(widget.isScientificMode ? "√" : "%"),
                  _buildButton(widget.isScientificMode ? "10ⁿ" : "0"),
                  _buildButton(widget.isScientificMode ? "x!" : "."),
                  _buildButton("="),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text('Dark Mode'),
                value: widget.isDarkMode,
                onChanged: (bool value) {
                  widget.onThemeChanged(value);
                },
              ),
              SwitchListTile(
                title: Text('Scientific Mode'),
                value: widget.isScientificMode,
                onChanged: (bool value) {
                  widget.onScientificModeChanged(value);
                },
              ),
              SwitchListTile(
                title: Text('Button Sound'),
                value: _isButtonSoundOn,
                onChanged: (bool value) {
                  setState(() {
                    _isButtonSoundOn = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
    });
  }

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Calculation History'),
          content: SingleChildScrollView(
            child: ListBody(
              children: _history.isNotEmpty
                  ? _history.map((entry) => Text(entry)).toList()
                  : [Text("No history available")],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearHistory();
                Navigator.of(context).pop();
              },
              child: Text('Clear History'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSwitchListTile(
      String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildButton(String buttonText) {
    return Expanded(
      child: Padding(
        padding:
            EdgeInsets.all(0.5), // Further reduced padding for smaller buttons
        child: ElevatedButton(
          onPressed: () => _buttonPressed(buttonText),
          child: Text(buttonText,
              style: TextStyle(fontSize: 26)), // Reduced font size
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0), // Smaller border radius
            ),
            minimumSize: Size(40, 40), // Further reduced size for buttons
            padding: EdgeInsets.all(8.0), // Further reduced padding
          ),
        ),
      ),
    );
  }

  Widget _buildButtonWithIcon(IconData icon, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding:
            EdgeInsets.all(0.5), // Further reduced padding for smaller buttons
        child: ElevatedButton(
          onPressed: onPressed,
          child: Icon(icon, size: 18), // Reduced icon size for smaller buttons
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0), // Smaller border radius
            ),
            minimumSize: Size(40, 40), // Further reduced size for buttons
            padding: EdgeInsets.all(8.0), // Further reduced padding
          ),
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<Widget> buttons) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons,
      ),
    );
  }
}
