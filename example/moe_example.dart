// ignore_for_file: avoid_print

import 'package:agentic_architecture/agentic_architecture.dart';

/// MOE (Mixture of Experts) example demonstrating multi-agent coordination.
///
/// This example shows:
/// 1. Creating multiple expert agents with different specializations
/// 2. Setting up a lead agent to coordinate experts
/// 3. Using different delegation strategies
/// 4. Processing complex queries that require multiple experts
Future<void> main() async {
  print('🧠 MOE (Mixture of Experts) Example\n');

  // 1. Create LLM providers
  // In production, you might use different providers for different experts:
  // final cheapLLM = DeepSeekProvider(apiKey: 'key1');
  // final smartLLM = OpenAIProvider(apiKey: 'key2', model: 'gpt-4');

  final cheapLLM = MockLLMProvider(
    name: 'cheap-llm',
    responses: ['Based on my analysis...'],
  );

  final smartLLM = MockLLMProvider(
    name: 'smart-llm',
    responses: ['Combining expert insights...'],
  );

  // 2. Create expert agents
  print('👥 Creating expert agents...\n');

  final weatherExpert = ExpertAgent(
    id: 'weather_expert',
    name: 'Weather Expert',
    description: 'Specializes in weather forecasts and meteorological data',
    domain: 'weather',
    keywords: ['weather', 'temperature', 'forecast', 'rain', 'sunny', 'cloudy'],
    llmProvider: cheapLLM,
    tools: [WeatherTool()],
    confidence: 0.9,
    config: const AgentConfig(enableLogging: false),
  );

  final mathExpert = ExpertAgent(
    id: 'math_expert',
    name: 'Math Expert',
    description: 'Specializes in mathematical calculations and problem-solving',
    domain: 'mathematics',
    keywords: ['calculate', 'math', 'number', 'equation', 'compute'],
    llmProvider: cheapLLM,
    tools: [CalculatorTool()],
    confidence: 0.95,
    config: const AgentConfig(enableLogging: false),
  );

  final generalExpert = ExpertAgent(
    id: 'general_expert',
    name: 'General Knowledge Expert',
    description: 'Handles general queries and information requests',
    domain: 'general',
    keywords: ['what', 'how', 'why', 'who', 'when', 'where'],
    llmProvider: cheapLLM,
    tools: [EchoTool()],
    confidence: 0.7,
    config: const AgentConfig(enableLogging: false),
  );

  final experts = [weatherExpert, mathExpert, generalExpert];

  print('Experts created:');
  for (final expert in experts) {
    print(
        '  - ${expert.name} (${expert.domain}) - confidence: ${expert.confidence}');
  }
  print('');

  // 3. Create lead agent
  final leadAgent = LeadAgent(
    id: 'lead',
    name: 'Lead Coordinator',
    description: 'Coordinates multiple expert agents',
    llmProvider: smartLLM,
    experts: experts,
    strategy: DelegationStrategy.parallel, // Try different strategies!
    maxExperts: 3,
    config: const AgentConfig(enableLogging: true),
  );

  print('Lead agent created with ${leadAgent.experts.length} experts');
  print('Delegation strategy: ${leadAgent.strategy.name}\n');

  // 4. Create coordinator in MOE mode
  final coordinator = AgentCoordinator(
    leadAgent: leadAgent,
    mode: AgentMode.moe,
    enableLogging: true,
  );

  // 5. Process queries that require multiple experts
  print('=' * 60);
  print('📝 Query 1: Weather + Math (Multiple Experts)\n');

  try {
    final results = await coordinator.processQuery(
      'What is the weather in Tokyo and what is 15 + 27?',
    );

    for (final result in results) {
      print('\n📊 Final Result:');
      print('Synthesized: ${result.synthesized}');
      print('Confidence: ${(result.confidence * 100).toStringAsFixed(0)}%');
      print('\nResponse:\n${result.content}');

      if (result.expertResponses != null &&
          result.expertResponses!.isNotEmpty) {
        print('\n🧑‍🔬 Expert Contributions:');
        for (final expert in result.expertResponses!) {
          print('\n  ${expert.expertName} (${expert.domain}):');
          print(
              '    Confidence: ${(expert.confidence * 100).toStringAsFixed(0)}%');
          print(
              '    Response: ${expert.content.substring(0, expert.content.length > 100 ? 100 : expert.content.length)}...');
        }
      }

      if (result.tokenUsage != null) {
        print('\n💰 Token Usage: ${result.tokenUsage}');
      }
    }
  } catch (e) {
    print('Error: $e');
  }

  print('\n' + '=' * 60);
  print('📝 Query 2: Single Domain Query\n');

  try {
    final results = await coordinator.processQuery(
      'Calculate the square root of 144',
    );

    for (final result in results) {
      print('\n📊 Final Result:');
      print('Response: ${result.content}');

      if (result.expertResponses != null) {
        print(
            '\nExperts consulted: ${result.expertResponses!.map((e) => e.expertName).join(", ")}');
      }
    }
  } catch (e) {
    print('Error: $e');
  }

  print('\n✅ MOE Example completed!');
  print('\n💡 Try different delegation strategies:');
  print('  - DelegationStrategy.single (best expert only)');
  print('  - DelegationStrategy.parallel (multiple experts)');
  print('  - DelegationStrategy.sequential (one after another)');
  print('  - DelegationStrategy.intelligent (LLM decides)');
}
