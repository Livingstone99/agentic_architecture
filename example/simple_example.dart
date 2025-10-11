// ignore_for_file: avoid_print

import 'package:agentic_architecture/agentic_architecture.dart';

/// Simple example demonstrating a basic agent with tools.
///
/// This example shows:
/// 1. Creating an LLM provider (using mock for demonstration)
/// 2. Setting up tools
/// 3. Creating a simple agent
/// 4. Processing queries
Future<void> main() async {
  print('🤖 Simple Agent Example\n');

  // 1. Create LLM provider (using mock for demonstration)
  // In production, use real providers:
  // final llm = DeepSeekProvider(apiKey: 'your-api-key');
  // final llm = OpenAIProvider(apiKey: 'your-api-key', model: 'gpt-4');
  final llm = MockLLMProvider(
    responses: [
      'I\'ll calculate that for you using the calculator tool.',
    ],
  );

  // 2. Create tools
  final tools = [
    EchoTool(),
    CalculatorTool(),
    WeatherTool(),
  ];

  print('📋 Available tools:');
  for (final tool in tools) {
    print('  - ${tool.name}: ${tool.description}');
  }
  print('');

  // 3. Create simple agent
  final agent = SimpleAgent(
    id: 'assistant',
    name: 'My Assistant',
    description: 'A helpful assistant with access to various tools',
    llmProvider: llm,
    tools: tools,
    config: const AgentConfig(
      enableLogging: true,
      maxToolRounds: 3,
    ),
  );

  // 4. Create coordinator
  final coordinator = AgentCoordinator(
    leadAgent: agent,
    mode: AgentMode.simple,
    enableLogging: true,
  );

  // 5. Process some queries
  print('📝 Query 1: Calculate 25 * 4\n');
  try {
    final results = await coordinator.processQuery('What is 25 * 4?');
    for (final result in results) {
      print('Agent: ${result.agentName}');
      print('Response: ${result.content}');
      if (result.toolResults.isNotEmpty) {
        print('\nTool Results:');
        for (final toolResult in result.toolResults) {
          print('  - ${toolResult.toolName}: ${toolResult.data}');
        }
      }
      if (result.tokenUsage != null) {
        print('\nToken Usage: ${result.tokenUsage}');
      }
    }
  } catch (e) {
    print('Error: $e');
  }

  print('\n' + '=' * 60 + '\n');

  print('📝 Query 2: Get weather for London\n');
  try {
    final results =
        await coordinator.processQuery('What\'s the weather like in London?');
    for (final result in results) {
      print('Agent: ${result.agentName}');
      print('Response: ${result.content}');
      if (result.toolResults.isNotEmpty) {
        print('\nTool Results:');
        for (final toolResult in result.toolResults) {
          final data = toolResult.data as Map<String, dynamic>;
          print('  Location: ${data['location']}');
          print(
              '  Temperature: ${data['temperature']}°${data['units'] == 'celsius' ? 'C' : 'F'}');
          print('  Condition: ${data['condition']}');
          print('  Humidity: ${data['humidity']}');
          print('  Wind: ${data['wind_speed']}');
        }
      }
    }
  } catch (e) {
    print('Error: $e');
  }

  print('\n✅ Example completed!');
}
