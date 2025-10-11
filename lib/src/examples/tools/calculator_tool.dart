import 'dart:math' as math;

import '../../core/result.dart';
import '../../core/tool.dart';

/// A calculator tool that evaluates mathematical expressions.
///
/// Supports:
/// - Basic arithmetic: +, -, *, /
/// - Parentheses for grouping
/// - Mathematical functions: sin, cos, tan, sqrt, pow, log, etc.
/// - Constants: pi, e
class CalculatorTool extends Tool {
  @override
  String get name => 'calculator';

  @override
  String get description =>
      'Evaluates mathematical expressions. Supports basic arithmetic (+, -, *, /), '
      'parentheses, and functions like sin, cos, sqrt, pow, etc.';

  @override
  Map<String, dynamic> get parameterSchema => {
        'type': 'object',
        'properties': {
          'expression': {
            'type': 'string',
            'description':
                'The mathematical expression to evaluate (e.g., "2 + 2", "sqrt(16)", "sin(pi/2)")',
          },
        },
        'required': ['expression'],
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> params) async {
    try {
      final expression = params['expression'] as String?;

      if (expression == null || expression.isEmpty) {
        return ToolResult.failure(
          toolName: name,
          error: 'Expression parameter is required and cannot be empty',
        );
      }

      // Evaluate the expression
      final result = _evaluate(expression);

      return ToolResult.success(
        toolName: name,
        data: {
          'expression': expression,
          'result': result,
        },
        metadata: {
          'calculated_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      return ToolResult.failure(
        toolName: name,
        error: 'Failed to evaluate expression: $e',
      );
    }
  }

  @override
  bool canHandle(String query) {
    final lowerQuery = query.toLowerCase();
    return lowerQuery.contains('calculate') ||
        lowerQuery.contains('compute') ||
        lowerQuery.contains('math') ||
        lowerQuery.contains('what is') ||
        _containsNumbers(query);
  }

  bool _containsNumbers(String text) {
    return RegExp(r'\d+').hasMatch(text);
  }

  /// Simple expression evaluator.
  ///
  /// This is a basic implementation. For production use, consider using
  /// a proper expression parser library.
  double _evaluate(String expression) {
    // Remove whitespace
    var expr = expression.replaceAll(' ', '');

    // Replace constants
    expr = expr.replaceAll('pi', math.pi.toString());
    expr = expr.replaceAll('e', math.e.toString());

    // Handle functions
    expr = _replaceFunctions(expr);

    // Evaluate the expression
    return _evaluateExpression(expr);
  }

  String _replaceFunctions(String expr) {
    // This is a simplified function replacer
    // In production, use a proper expression parser

    // Handle sqrt
    final sqrtRegex = RegExp(r'sqrt\(([^)]+)\)');
    expr = expr.replaceAllMapped(sqrtRegex, (match) {
      final value = _evaluateExpression(match.group(1)!);
      return math.sqrt(value).toString();
    });

    // Handle pow
    final powRegex = RegExp(r'pow\(([^,]+),([^)]+)\)');
    expr = expr.replaceAllMapped(powRegex, (match) {
      final base = _evaluateExpression(match.group(1)!);
      final exponent = _evaluateExpression(match.group(2)!);
      return math.pow(base, exponent).toString();
    });

    // Handle sin
    final sinRegex = RegExp(r'sin\(([^)]+)\)');
    expr = expr.replaceAllMapped(sinRegex, (match) {
      final value = _evaluateExpression(match.group(1)!);
      return math.sin(value).toString();
    });

    // Handle cos
    final cosRegex = RegExp(r'cos\(([^)]+)\)');
    expr = expr.replaceAllMapped(cosRegex, (match) {
      final value = _evaluateExpression(match.group(1)!);
      return math.cos(value).toString();
    });

    // Handle tan
    final tanRegex = RegExp(r'tan\(([^)]+)\)');
    expr = expr.replaceAllMapped(tanRegex, (match) {
      final value = _evaluateExpression(match.group(1)!);
      return math.tan(value).toString();
    });

    // Handle log (natural logarithm)
    final logRegex = RegExp(r'log\(([^)]+)\)');
    expr = expr.replaceAllMapped(logRegex, (match) {
      final value = _evaluateExpression(match.group(1)!);
      return math.log(value).toString();
    });

    return expr;
  }

  /// Evaluates a simple arithmetic expression.
  ///
  /// This is a basic implementation using recursive descent parsing.
  double _evaluateExpression(String expr) {
    expr = expr.trim();

    // Handle parentheses
    while (expr.contains('(')) {
      final start = expr.lastIndexOf('(');
      final end = expr.indexOf(')', start);
      if (end == -1) throw FormatException('Mismatched parentheses');

      final subExpr = expr.substring(start + 1, end);
      final result = _evaluateExpression(subExpr);
      expr = expr.substring(0, start) +
          result.toString() +
          expr.substring(end + 1);
    }

    // Handle addition and subtraction
    for (var i = expr.length - 1; i >= 0; i--) {
      if (expr[i] == '+' && i > 0) {
        final left = _evaluateExpression(expr.substring(0, i));
        final right = _evaluateExpression(expr.substring(i + 1));
        return left + right;
      } else if (expr[i] == '-' && i > 0 && _isOperator(expr[i - 1]) == false) {
        final left = _evaluateExpression(expr.substring(0, i));
        final right = _evaluateExpression(expr.substring(i + 1));
        return left - right;
      }
    }

    // Handle multiplication and division
    for (var i = expr.length - 1; i >= 0; i--) {
      if (expr[i] == '*') {
        final left = _evaluateExpression(expr.substring(0, i));
        final right = _evaluateExpression(expr.substring(i + 1));
        return left * right;
      } else if (expr[i] == '/') {
        final left = _evaluateExpression(expr.substring(0, i));
        final right = _evaluateExpression(expr.substring(i + 1));
        if (right == 0) throw ArgumentError('Division by zero');
        return left / right;
      }
    }

    // Try to parse as a number
    return double.parse(expr);
  }

  bool _isOperator(String char) {
    return char == '+' || char == '-' || char == '*' || char == '/';
  }
}
