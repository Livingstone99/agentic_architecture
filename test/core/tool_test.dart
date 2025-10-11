import 'package:agentic_architecture/agentic_architecture.dart';
import 'package:test/test.dart';

void main() {
  group('EchoTool', () {
    late EchoTool tool;

    setUp(() {
      tool = EchoTool();
    });

    test('has correct name and description', () {
      expect(tool.name, equals('echo'));
      expect(tool.description, isNotEmpty);
    });

    test('execute returns input message', () async {
      final result = await tool.execute({'message': 'Hello'});

      expect(result.success, isTrue);
      expect(result.data, equals('Hello'));
      expect(result.toolName, equals('echo'));
    });

    test('execute fails with missing parameter', () async {
      final result = await tool.execute({});

      expect(result.success, isFalse);
      expect(result.error, contains('required'));
    });

    test('canHandle recognizes echo keywords', () {
      expect(tool.canHandle('Please echo this'), isTrue);
      expect(tool.canHandle('repeat after me'), isTrue);
      expect(tool.canHandle('random query'), isFalse);
    });

    test('toSchema returns valid ToolSchema', () {
      final schema = tool.toSchema();

      expect(schema.type, equals('function'));
      expect(schema.function.name, equals('echo'));
      expect(schema.function.parameters['required'], contains('message'));
    });
  });

  group('CalculatorTool', () {
    late CalculatorTool tool;

    setUp(() {
      tool = CalculatorTool();
    });

    test('evaluates simple arithmetic', () async {
      final result = await tool.execute({'expression': '2 + 2'});

      expect(result.success, isTrue);
      final data = result.data as Map<String, dynamic>;
      expect(data['result'], equals(4.0));
    });

    test('evaluates multiplication', () async {
      final result = await tool.execute({'expression': '5 * 6'});

      expect(result.success, isTrue);
      final data = result.data as Map<String, dynamic>;
      expect(data['result'], equals(30.0));
    });

    test('handles division', () async {
      final result = await tool.execute({'expression': '10 / 2'});

      expect(result.success, isTrue);
      final data = result.data as Map<String, dynamic>;
      expect(data['result'], equals(5.0));
    });

    test('fails on division by zero', () async {
      final result = await tool.execute({'expression': '5 / 0'});

      expect(result.success, isFalse);
      expect(result.error, contains('Division by zero'));
    });

    test('canHandle math-related queries', () {
      expect(tool.canHandle('calculate 2+2'), isTrue);
      expect(tool.canHandle('what is 5*6'), isTrue);
      expect(tool.canHandle('weather today'), isFalse);
    });
  });

  group('ToolRegistry', () {
    late ToolRegistry registry;

    setUp(() {
      registry = ToolRegistry();
    });

    test('starts empty', () {
      expect(registry.count, equals(0));
      expect(registry.tools, isEmpty);
    });

    test('registers tools', () {
      registry.register(EchoTool());

      expect(registry.count, equals(1));
      expect(registry.has('echo'), isTrue);
    });

    test('gets registered tool', () {
      final tool = EchoTool();
      registry.register(tool);

      final retrieved = registry.get('echo');
      expect(retrieved, equals(tool));
    });

    test('returns null for unknown tool', () {
      final retrieved = registry.get('unknown');
      expect(retrieved, isNull);
    });

    test('finds tools by query', () {
      registry.registerAll([
        EchoTool(),
        CalculatorTool(),
      ]);

      final found = registry.findToolsForQuery('calculate something');
      expect(found, hasLength(1));
      expect(found.first.name, equals('calculator'));
    });

    test('clears all tools', () {
      registry.registerAll([EchoTool(), CalculatorTool()]);
      expect(registry.count, equals(2));

      registry.clear();
      expect(registry.count, equals(0));
    });
  });
}
