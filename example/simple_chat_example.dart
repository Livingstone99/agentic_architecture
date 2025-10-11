// ignore_for_file: avoid_print

import 'package:agentic_architecture/agentic_architecture.dart';

/// Conversational agent example with DeepSeek.
///
/// This example demonstrates:
/// 1. Multi-turn conversations with history
/// 2. Custom system prompts for personality
/// 3. Real DeepSeek API integration
/// 4. Context-aware responses
Future<void> main() async {
  print('🤖 Conversational Chat Agent Example\n');

  // 1. Create DeepSeek provider
  // Replace 'your-deepseek-api-key' with your actual API key
  final llm = DeepSeekProvider(
    apiKey: 'your-deepseek-api-key',
  );

  // 2. Create a conversational agent with custom personality
  final agent = SimpleAgent(
    id: 'chat_assistant',
    name: 'Alex - Your AI Assistant',
    description: 'A friendly, helpful AI assistant',
    llmProvider: llm,
    tools: [
      CalculatorTool(),
      WeatherTool(),
      EchoTool(),
    ],
    config: const AgentConfig(
      systemPrompt: '''You are Alex, a friendly and helpful AI assistant.

Your personality:
- Warm, approachable, and conversational
- Patient and clear in explanations
- Enthusiastic about helping
- Use natural, casual language (but stay professional)

Guidelines:
- Keep responses concise but informative (2-3 sentences usually)
- Ask follow-up questions to better understand needs
- Use tools when you need real data
- Remember context from previous messages
- If you don't know something, admit it honestly

Conversation style: Imagine you're texting a knowledgeable friend.''',
      temperature: 0.8, // Slightly higher for natural conversation
      maxTokens: 300,
      enableLogging: true,
    ),
  );

  // 3. Create coordinator
  final coordinator = AgentCoordinator(
    leadAgent: agent,
    mode: AgentMode.simple,
    enableLogging: true,
  );

  // 4. Simulate a multi-turn conversation
  final conversationHistory = <LLMMessage>[];

  print('=' * 70);
  print('💬 Starting Conversation');
  print('=' * 70);

  // Turn 1: Greeting
  await processMessage(
    coordinator: coordinator,
    message: 'Hi! What can you help me with?',
    history: conversationHistory,
    turnNumber: 1,
  );

  // Turn 2: Request with tool use
  await processMessage(
    coordinator: coordinator,
    message: 'What\'s the weather like in Paris?',
    history: conversationHistory,
    turnNumber: 2,
  );

  // Turn 3: Follow-up question (tests context awareness)
  await processMessage(
    coordinator: coordinator,
    message: 'And what\'s 25 times 18?',
    history: conversationHistory,
    turnNumber: 3,
  );

  // Turn 4: Complex query
  await processMessage(
    coordinator: coordinator,
    message:
        'Can you calculate the square root of 144 and tell me if that\'s a good temperature in Celsius?',
    history: conversationHistory,
    turnNumber: 4,
  );

  print('\n✅ Conversation completed!');
  print('\n📊 Conversation Stats:');
  print(
      '  Total turns: ${conversationHistory.where((m) => m.role == MessageRole.user).length}');
  print('  Messages exchanged: ${conversationHistory.length}');
}

/// Helper function to process a message and update history
Future<void> processMessage({
  required AgentCoordinator coordinator,
  required String message,
  required List<LLMMessage> history,
  required int turnNumber,
}) async {
  print('\n${'─' * 70}');
  print('Turn $turnNumber');
  print('${'─' * 70}');
  print('👤 User: $message\n');

  try {
    // Process the query with history
    final results = await coordinator.processQuery(
      message,
      history: history,
    );

    final result = results.first;

    // Display response
    print('🤖 Alex: ${result.content}\n');

    // Show tool usage if any
    if (result.toolResults.isNotEmpty) {
      print('🔧 Tools Used:');
      for (final toolResult in result.toolResults) {
        if (toolResult.success) {
          print('  ✓ ${toolResult.toolName}');
        } else {
          print('  ✗ ${toolResult.toolName}: ${toolResult.error}');
        }
      }
      print('');
    }

    // Show token usage
    if (result.tokenUsage != null) {
      print('📊 Tokens: ${result.tokenUsage!.totalTokens} '
          '(in: ${result.tokenUsage!.inputTokens}, out: ${result.tokenUsage!.outputTokens}) '
          '- Cost: \$${result.tokenUsage!.cost?.toStringAsFixed(6) ?? 'N/A'}');
    }

    // Update conversation history
    history.add(LLMMessage.user(message));
    history.add(LLMMessage.assistant(result.content));
  } catch (e) {
    print('❌ Error: $e');
  }
}
