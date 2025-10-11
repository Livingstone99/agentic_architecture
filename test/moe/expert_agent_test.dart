import 'package:agentic_architecture/agentic_architecture.dart';
import 'package:test/test.dart';

void main() {
  group('ExpertAgent', () {
    late MockLLMProvider mockLLM;
    late ExpertAgent expert;

    setUp(() {
      mockLLM = MockLLMProvider(responses: ['Expert response']);

      expert = ExpertAgent(
        id: 'weather_expert',
        name: 'Weather Expert',
        description: 'Expert in weather forecasts',
        domain: 'weather',
        keywords: ['weather', 'temperature', 'forecast'],
        llmProvider: mockLLM,
        tools: [WeatherTool()],
        confidence: 0.9,
      );
    });

    test('can be created with required parameters', () {
      expect(expert.id, equals('weather_expert'));
      expect(expert.domain, equals('weather'));
      expect(expert.confidence, equals(0.9));
      expect(expert.keywords, hasLength(3));
    });

    test('canHandle recognizes matching keywords', () {
      final request = AgentRequest(query: 'What is the weather today?');
      expect(expert.canHandle(request), isTrue);
    });

    test('canHandle rejects non-matching queries', () {
      final request = AgentRequest(query: 'Calculate 2+2');
      expect(expert.canHandle(request), isFalse);
    });

    test('calculateRelevanceScore returns score for matching query', () {
      final score = expert.calculateRelevanceScore('weather forecast');
      expect(score, greaterThan(0.0));
      expect(score, lessThanOrEqualTo(1.0));
    });

    test('calculateRelevanceScore returns 0 for non-matching query', () {
      final score = expert.calculateRelevanceScore('calculate numbers');
      expect(score, equals(0.0));
    });

    test('process returns valid response', () async {
      final request = AgentRequest(query: 'What is the weather?');
      final response = await expert.process(request);

      expect(response.agentId, equals('weather_expert'));
      expect(response.content, isNotEmpty);
      expect(response.confidence, equals(0.9));
    });

    test('toExpertResponse converts correctly', () {
      final agentResponse = AgentResponse(
        agentId: expert.id,
        content: 'Test content',
        confidence: 0.9,
      );

      final expertResponse = expert.toExpertResponse(agentResponse);

      expect(expertResponse.expertId, equals(expert.id));
      expect(expertResponse.expertName, equals(expert.name));
      expect(expertResponse.domain, equals(expert.domain));
      expect(expertResponse.content, equals('Test content'));
    });
  });

  group('DelegationStrategy', () {
    test('has correct descriptions', () {
      expect(DelegationStrategy.single.description, isNotEmpty);
      expect(DelegationStrategy.parallel.description, isNotEmpty);
      expect(DelegationStrategy.sequential.description, isNotEmpty);
      expect(DelegationStrategy.intelligent.description, isNotEmpty);
    });

    test('usesMultipleExperts is correct', () {
      expect(DelegationStrategy.single.usesMultipleExperts, isFalse);
      expect(DelegationStrategy.parallel.usesMultipleExperts, isTrue);
      expect(DelegationStrategy.sequential.usesMultipleExperts, isTrue);
      expect(DelegationStrategy.intelligent.usesMultipleExperts, isTrue);
    });

    test('requiresLLM is correct', () {
      expect(DelegationStrategy.single.requiresLLM, isFalse);
      expect(DelegationStrategy.parallel.requiresLLM, isFalse);
      expect(DelegationStrategy.sequential.requiresLLM, isFalse);
      expect(DelegationStrategy.intelligent.requiresLLM, isTrue);
    });
  });
}
