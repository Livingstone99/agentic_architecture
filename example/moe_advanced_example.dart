// ignore_for_file: avoid_print

import 'package:agentic_architecture/agentic_architecture.dart';

/// Advanced MOE (Mixture of Experts) example with DeepSeek.
///
/// This example demonstrates:
/// 1. Multiple specialized expert agents
/// 2. Intelligent routing between experts
/// 3. Different delegation strategies
/// 4. Response synthesis from multiple experts
/// 5. Real-world multi-domain queries
Future<void> main() async {
  print('🧠 Advanced Mixture of Experts (MOE) System\n');

  // Create DeepSeek provider (same for all to keep costs low)
  // Replace 'your-deepseek-api-key' with your actual API key
  final llm = DeepSeekProvider(
    apiKey: 'your-deepseek-api-key',
  );

  // Create specialized expert agents
  print('👥 Creating Expert Team...\n');

  // 1. Weather & Environment Expert
  final weatherExpert = ExpertAgent(
    id: 'weather_expert',
    name: 'Dr. Climate',
    description: 'Meteorology and environmental data specialist',
    domain: 'weather',
    keywords: [
      'weather',
      'temperature',
      'forecast',
      'rain',
      'sunny',
      'cloudy',
      'climate',
      'humidity',
      'wind',
    ],
    llmProvider: llm,
    tools: [WeatherTool()],
    confidence: 0.95,
    config: const AgentConfig(
      systemPrompt: '''You are Dr. Climate, a meteorology expert.

Expertise:
- Weather patterns and forecasts
- Temperature analysis
- Climate conditions
- Environmental factors

Response style:
- Provide specific measurements
- Include relevant context (humidity, wind, etc.)
- Mention any notable weather patterns
- Be concise but informative

Always use the weather tool to get current data.''',
      temperature: 0.5,
      enableLogging: false,
    ),
  );

  // 2. Mathematics & Analytics Expert
  final mathExpert = ExpertAgent(
    id: 'math_expert',
    name: 'Professor Numbers',
    description: 'Mathematics and computational analysis specialist',
    domain: 'mathematics',
    keywords: [
      'calculate',
      'math',
      'number',
      'equation',
      'compute',
      'sum',
      'multiply',
      'divide',
      'percentage',
      'average',
    ],
    llmProvider: llm,
    tools: [CalculatorTool()],
    confidence: 0.98,
    config: const AgentConfig(
      systemPrompt: '''You are Professor Numbers, a mathematics expert.

Expertise:
- Mathematical calculations
- Statistical analysis
- Problem-solving
- Numerical reasoning

Response style:
- Show your work step-by-step
- Explain the reasoning
- Provide the final answer clearly
- Mention any assumptions

Use the calculator tool for precision.''',
      temperature: 0.3,
      enableLogging: false,
    ),
  );

  // 3. General Knowledge Expert
  final knowledgeExpert = ExpertAgent(
    id: 'knowledge_expert',
    name: 'Professor Know-It-All',
    description: 'General knowledge and information specialist',
    domain: 'general_knowledge',
    keywords: [
      'what',
      'who',
      'where',
      'when',
      'why',
      'how',
      'explain',
      'tell me',
      'information',
    ],
    llmProvider: llm,
    tools: [EchoTool()],
    confidence: 0.80,
    config: const AgentConfig(
      systemPrompt:
          '''You are Professor Know-It-All, a general knowledge expert.

Expertise:
- Broad general knowledge
- Explanations and definitions
- Historical and factual information
- Conceptual understanding

Response style:
- Clear and educational
- Provide context
- Make complex topics accessible
- Be accurate and factual

If you don't know something, say so honestly.''',
      temperature: 0.6,
      enableLogging: false,
    ),
  );

  // 4. Planning & Strategy Expert
  final planningExpert = ExpertAgent(
    id: 'planning_expert',
    name: 'Strategic Advisor',
    description: 'Planning, organization, and strategy specialist',
    domain: 'planning',
    keywords: [
      'plan',
      'organize',
      'schedule',
      'strategy',
      'approach',
      'method',
      'prepare',
      'coordinate',
    ],
    llmProvider: llm,
    tools: [],
    confidence: 0.85,
    config: const AgentConfig(
      systemPrompt: '''You are Strategic Advisor, a planning expert.

Expertise:
- Strategic planning
- Organization and coordination
- Resource allocation
- Timeline management

Response style:
- Provide structured plans
- Break down into actionable steps
- Consider constraints and resources
- Be practical and realistic

Focus on clear, implementable strategies.''',
      temperature: 0.7,
      enableLogging: false,
    ),
  );

  final experts = [weatherExpert, mathExpert, knowledgeExpert, planningExpert];

  print('Experts created:');
  for (final expert in experts) {
    print(
        '  ✓ ${expert.name} (${expert.domain}) - Confidence: ${(expert.confidence * 100).toInt()}%');
  }
  print('');

  // Create lead agent to coordinate experts
  final leadAgent = LeadAgent(
    id: 'lead_coordinator',
    name: 'Lead Coordinator',
    description: 'Coordinates expert agents and synthesizes responses',
    llmProvider: llm,
    experts: experts,
    strategy:
        DelegationStrategy.parallel, // Query multiple experts simultaneously
    maxExperts: 3,
    config: const AgentConfig(
      systemPrompt: '''You are the Lead Coordinator managing a team of experts.

Your role:
- Understand user queries
- Identify which experts can help
- Synthesize expert responses into coherent answers
- Ensure completeness and accuracy

When synthesizing:
- Combine insights naturally
- Resolve any contradictions
- Maintain expert attribution when relevant
- Provide a unified, helpful response''',
      enableLogging: false,
    ),
  );

  print('🎯 Lead Coordinator: ${leadAgent.name}');
  print('📋 Strategy: ${leadAgent.strategy.name}');
  print('👥 Max experts per query: ${leadAgent.maxExperts}\n');

  // Create coordinator in MOE mode
  final coordinator = AgentCoordinator(
    leadAgent: leadAgent,
    mode: AgentMode.moe,
    enableLogging: true,
  );

  // Test different types of queries
  print('=' * 70);
  print('🧪 Testing MOE System with Various Queries');
  print('=' * 70);

  // Query 1: Multi-domain query (weather + math)
  await runQuery(
    coordinator: coordinator,
    query:
        'What is the weather in London, and if it\'s 15°C, what is that in Fahrenheit? Use the formula: F = (C × 9/5) + 32',
    queryNumber: 1,
    description: 'Multi-domain: Weather + Mathematics',
  );

  // Query 2: Single domain (math only)
  await runQuery(
    coordinator: coordinator,
    query: 'Calculate the average of these numbers: 45, 67, 89, 23, 56, and 78',
    queryNumber: 2,
    description: 'Single domain: Mathematics',
  );

  // Query 3: Complex multi-domain (planning + math + weather)
  await runQuery(
    coordinator: coordinator,
    query:
        'I need to plan a 3-day outdoor event. Check the weather in Paris, calculate the budget if we have \$5000 and need to split it equally across 3 days, and suggest how to organize it.',
    queryNumber: 3,
    description: 'Complex multi-domain: Planning + Math + Weather',
  );

  // Query 4: Knowledge query
  await runQuery(
    coordinator: coordinator,
    query: 'What is machine learning and why is it important?',
    queryNumber: 4,
    description: 'Single domain: General Knowledge',
  );

  print('\n✅ All MOE examples completed!');
  print('\n💡 Key Takeaway:');
  print('   The MOE system automatically routes queries to the right experts');
  print('   and combines their responses into comprehensive answers!');
}

/// Helper function to run a query and display results
Future<void> runQuery({
  required AgentCoordinator coordinator,
  required String query,
  required int queryNumber,
  required String description,
}) async {
  print('\n${'─' * 70}');
  print('Query $queryNumber: $description');
  print('${'─' * 70}');
  print('❓ Question: $query\n');

  try {
    final results = await coordinator.processQuery(query);
    final result = results.first;

    // Show which experts were consulted
    if (result.expertResponses != null && result.expertResponses!.isNotEmpty) {
      print('👥 Experts Consulted:');
      for (final expert in result.expertResponses!) {
        print('   • ${expert.expertName} (${expert.domain}) - '
            'Confidence: ${(expert.confidence * 100).toInt()}%');
      }
      print('');
    }

    // Show synthesized response
    print('💬 Response:');
    print(result.content);
    print('');

    // Show tool usage
    if (result.toolResults.isNotEmpty) {
      print('🔧 Tools Used:');
      for (final tool in result.toolResults) {
        print('   ✓ ${tool.toolName}');
      }
      print('');
    }

    // Show token usage and cost
    if (result.tokenUsage != null) {
      print('📊 Resources:');
      print('   Tokens: ${result.tokenUsage!.totalTokens} '
          '(in: ${result.tokenUsage!.inputTokens}, out: ${result.tokenUsage!.outputTokens})');
      print(
          '   Cost: \$${result.tokenUsage!.cost?.toStringAsFixed(6) ?? 'N/A'}');
      print('   Synthesized: ${result.synthesized ? 'Yes' : 'No'}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
