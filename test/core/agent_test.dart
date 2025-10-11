import 'package:agentic_architecture/agentic_architecture.dart';
import 'package:test/test.dart';

void main() {
  group('SimpleAgent', () {
    late MockLLMProvider mockLLM;
    late SimpleAgent agent;

    setUp(() {
      mockLLM = MockLLMProvider(
        responses: ['Test response'],
      );

      agent = SimpleAgent(
        id: 'test_agent',
        name: 'Test Agent',
        description: 'A test agent',
        llmProvider: mockLLM,
        tools: [EchoTool()],
      );
    });

    test('can be created with required parameters', () {
      expect(agent.id, equals('test_agent'));
      expect(agent.name, equals('Test Agent'));
      expect(agent.tools, hasLength(1));
    });

    test('canHandle returns true for all requests', () {
      final request = AgentRequest(query: 'test query');
      expect(agent.canHandle(request), isTrue);
    });

    test('process returns valid response', () async {
      final request = AgentRequest(query: 'test query');
      final response = await agent.process(request);

      expect(response.agentId, equals('test_agent'));
      expect(response.content, isNotEmpty);
    });

    test('has correct tool schemas', () {
      expect(agent.toolSchemas, hasLength(1));
      expect(agent.toolSchemas.first.function.name, equals('echo'));
    });
  });

  group('AgentConfig', () {
    test('has default values', () {
      const config = AgentConfig();

      expect(config.maxToolRounds, equals(5));
      expect(config.enableLogging, isFalse);
      expect(config.extra, isEmpty);
    });

    test('copyWith creates new config with updated fields', () {
      const config = AgentConfig(maxToolRounds: 3);
      final newConfig = config.copyWith(enableLogging: true);

      expect(newConfig.maxToolRounds, equals(3));
      expect(newConfig.enableLogging, isTrue);
    });
  });
}
