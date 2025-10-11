// ignore_for_file: avoid_print

import 'package:agentic_architecture/agentic_architecture.dart';

/// Task-focused agent example with DeepSeek.
///
/// This example demonstrates:
/// 1. Creating specialized task agents with custom prompts
/// 2. Using different agents for different tasks
/// 3. Controlling LLM behavior with temperature and prompts
/// 4. Practical real-world use cases
Future<void> main() async {
  print('🎯 Task-Focused Agent Examples\n');

  // Create DeepSeek provider
  // Replace 'your-deepseek-api-key' with your actual API key
  final llm = DeepSeekProvider(
    apiKey: 'your-deepseek-api-key',
  );

  // Example 1: Data Analysis Agent
  print('=' * 70);
  print('📊 Example 1: Data Analysis Agent');
  print('=' * 70);
  await runDataAnalystAgent(llm);

  print('\n\n');

  // Example 2: Technical Writer Agent
  print('=' * 70);
  print('📝 Example 2: Technical Writer Agent');
  print('=' * 70);
  await runTechnicalWriterAgent(llm);

  print('\n\n');

  // Example 3: Problem-Solving Agent
  print('=' * 70);
  print('💡 Example 3: Problem-Solving Agent');
  print('=' * 70);
  await runProblemSolvingAgent(llm);

  print('\n✅ All task examples completed!');
}

/// Data Analyst Agent - Low temperature, analytical
Future<void> runDataAnalystAgent(DeepSeekProvider llm) async {
  final agent = SimpleAgent(
    id: 'data_analyst',
    name: 'Data Analyst',
    description: 'Analyzes data and provides insights',
    llmProvider: llm,
    tools: [CalculatorTool()],
    config: const AgentConfig(
      systemPrompt: '''You are a professional data analyst.

Analysis approach:
1. Break down the problem systematically
2. Use calculations to verify findings
3. Present results clearly with numbers
4. Provide actionable insights

Format your responses:
- Start with the key finding
- Show your calculations
- End with a brief recommendation

Be precise, analytical, and data-driven.''',
      temperature: 0.3, // Low temperature for precision
      maxTokens: 400,
      enableLogging: false,
    ),
  );

  final coordinator = AgentCoordinator(
    leadAgent: agent,
    mode: AgentMode.simple,
  );

  print('\n📝 Task: Analyze sales growth\n');

  final results = await coordinator.processQuery(
    '''Our sales were \$150,000 last quarter and \$195,000 this quarter.
Calculate the growth rate and tell me if this is good growth for a B2B SaaS company.''',
  );

  print('📊 Analysis:\n${results.first.content}\n');

  if (results.first.toolResults.isNotEmpty) {
    print('🔢 Calculations performed:');
    for (final tool in results.first.toolResults) {
      if (tool.success) {
        final data = tool.data as Map<String, dynamic>;
        print('  ${data['expression']} = ${data['result']}');
      }
    }
  }

  if (results.first.tokenUsage != null) {
    print('\n💰 Cost: \$${results.first.tokenUsage!.cost?.toStringAsFixed(6)}');
  }
}

/// Technical Writer Agent - Clear, structured writing
Future<void> runTechnicalWriterAgent(DeepSeekProvider llm) async {
  final agent = SimpleAgent(
    id: 'tech_writer',
    name: 'Technical Writer',
    description: 'Creates clear technical documentation',
    llmProvider: llm,
    tools: [],
    config: const AgentConfig(
      systemPrompt:
          '''You are a senior technical writer specializing in developer documentation.

Writing principles:
- Use simple, clear language
- Break complex topics into steps
- Include practical examples
- Anticipate common questions
- Organize with clear headings

Structure:
1. Brief overview (what it is)
2. Why it matters
3. How to use it (step-by-step)
4. Common pitfalls to avoid

Tone: Professional but friendly, like a helpful colleague.''',
      temperature: 0.6, // Balanced for clarity and readability
      maxTokens: 500,
      enableLogging: false,
    ),
  );

  final coordinator = AgentCoordinator(
    leadAgent: agent,
    mode: AgentMode.simple,
  );

  print('\n📝 Task: Write documentation\n');

  final results = await coordinator.processQuery(
    'Write a brief getting started guide for using REST APIs, aimed at beginner developers.',
  );

  print('📄 Documentation:\n${results.first.content}\n');

  if (results.first.tokenUsage != null) {
    print('💰 Cost: \$${results.first.tokenUsage!.cost?.toStringAsFixed(6)}');
  }
}

/// Problem-Solving Agent - Creative, solution-oriented
Future<void> runProblemSolvingAgent(DeepSeekProvider llm) async {
  final agent = SimpleAgent(
    id: 'problem_solver',
    name: 'Problem Solver',
    description: 'Helps solve complex problems creatively',
    llmProvider: llm,
    tools: [CalculatorTool()],
    config: const AgentConfig(
      systemPrompt: '''You are a creative problem-solving consultant.

Problem-solving framework:
1. Understand the problem deeply
2. Break it into components
3. Generate multiple solution approaches
4. Evaluate pros and cons
5. Recommend the best path forward

Approach:
- Think outside the box
- Consider trade-offs
- Be practical and actionable
- Use calculations when helpful
- Explain your reasoning

Goal: Provide clear, actionable solutions that can be implemented immediately.''',
      temperature: 0.7, // Higher for creative thinking
      maxTokens: 500,
      enableLogging: false,
    ),
  );

  final coordinator = AgentCoordinator(
    leadAgent: agent,
    mode: AgentMode.simple,
  );

  print('\n📝 Task: Solve a business problem\n');

  final results = await coordinator.processQuery(
    '''We have a small team of 5 developers and need to build 3 major features in 3 months.
Each feature needs about 6 weeks of work. How should we approach this?''',
  );

  print('💡 Solution:\n${results.first.content}\n');

  if (results.first.toolResults.isNotEmpty) {
    print('🔢 Calculations:');
    for (final tool in results.first.toolResults) {
      if (tool.success) {
        print('  ${tool.toolName}: Used');
      }
    }
    print('');
  }

  if (results.first.tokenUsage != null) {
    print('💰 Cost: \$${results.first.tokenUsage!.cost?.toStringAsFixed(6)}');
  }
}
