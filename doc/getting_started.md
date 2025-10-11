# Getting Started with Agentic Architecture

Welcome to Agentic Architecture! This guide will help you build your first intelligent agent-based application.

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  agentic_architecture: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Core Concepts

### 1. Agents
Agents are autonomous entities that process queries using LLMs and tools.

### 2. Tools
Tools are functions that agents can call to interact with external systems or perform computations.

### 3. LLM Providers
LLM providers abstract different language model APIs (OpenAI, DeepSeek, Claude, Gemini).

### 4. Coordinator
The coordinator orchestrates agent operations and manages query processing.

## Your First Agent

### Step 1: Choose an LLM Provider

```dart
import 'package:agentic_architecture/agentic_architecture.dart';

// Option 1: DeepSeek (cost-effective)
final llm = DeepSeekProvider(
  apiKey: 'your-api-key',
);

// Option 2: OpenAI
final llm = OpenAIProvider(
  apiKey: 'your-api-key',
  model: 'gpt-4-turbo',
);

// Option 3: Claude
final llm = ClaudeProvider(
  apiKey: 'your-api-key',
);

// Option 4: Gemini
final llm = GeminiProvider(
  apiKey: 'your-api-key',
);
```

### Step 2: Create Tools

```dart
// Use built-in example tools
final tools = [
  CalculatorTool(),
  WeatherTool(),
  EchoTool(),
];
```

### Step 3: Create an Agent

```dart
final agent = SimpleAgent(
  id: 'my_assistant',
  name: 'My Assistant',
  description: 'A helpful assistant',
  llmProvider: llm,
  tools: tools,
);
```

### Step 4: Create a Coordinator

```dart
final coordinator = AgentCoordinator(
  leadAgent: agent,
  mode: AgentMode.simple,
);
```

### Step 5: Process Queries

```dart
final results = await coordinator.processQuery('What is 25 * 4?');

for (final result in results) {
  print(result.content);
}
```

## Complete Example

```dart
import 'package:agentic_architecture/agentic_architecture.dart';

Future<void> main() async {
  // 1. Create LLM provider
  final llm = DeepSeekProvider(apiKey: 'your-api-key');

  // 2. Create tools
  final tools = [
    CalculatorTool(),
    WeatherTool(),
  ];

  // 3. Create agent
  final agent = SimpleAgent(
    id: 'assistant',
    name: 'My Assistant',
    llmProvider: llm,
    tools: tools,
  );

  // 4. Create coordinator
  final coordinator = AgentCoordinator(
    leadAgent: agent,
    mode: AgentMode.simple,
  );

  // 5. Process query
  final results = await coordinator.processQuery(
    'What is the weather in London and what is 15 + 27?'
  );

  print(results.first.content);
}
```

## Creating Your First Tool

Tools extend the `Tool` base class:

```dart
class MyTool extends Tool {
  @override
  String get name => 'my_tool';

  @override
  String get description => 'Describes what my tool does';

  @override
  Map<String, dynamic> get parameterSchema => {
    'type': 'object',
    'properties': {
      'input': {
        'type': 'string',
        'description': 'The input parameter',
      },
    },
    'required': ['input'],
  };

  @override
  Future<ToolResult> execute(Map<String, dynamic> params) async {
    final input = params['input'] as String;
    
    // Your tool logic here
    final output = input.toUpperCase();
    
    return ToolResult.success(
      toolName: name,
      data: output,
    );
  }
}
```

## Agent Configuration

Customize agent behavior with `AgentConfig`:

```dart
final agent = SimpleAgent(
  id: 'assistant',
  name: 'My Assistant',
  llmProvider: llm,
  tools: tools,
  config: AgentConfig(
    maxToolRounds: 5,           // Max tool execution rounds
    temperature: 0.7,            // LLM temperature
    maxTokens: 2048,             // Max response tokens
    enableLogging: true,         // Enable verbose logs
    systemPrompt: 'You are...', // Custom system prompt
  ),
);
```

## Error Handling

```dart
try {
  final results = await coordinator.processQuery(query);
  print(results.first.content);
} on AgentException catch (e) {
  print('Agent error: ${e.message}');
} on ToolException catch (e) {
  print('Tool error: ${e.message}');
} on LLMProviderException catch (e) {
  print('LLM provider error: ${e.message}');
}
```

## Next Steps

- [Learn about the architecture](architecture.md)
- [Explore MOE mode](moe_guide.md)
- [Create custom LLM providers](custom_llm.md)
- [Check out examples](../example/README.md)

## Common Patterns

### Conversational Agent

```dart
final history = <LLMMessage>[];

// First query
var results = await coordinator.processQuery(
  'Hello!',
  history: history,
);

// Add to history
history.add(LLMMessage.user('Hello!'));
history.add(LLMMessage.assistant(results.first.content));

// Follow-up query
results = await coordinator.processQuery(
  'What can you help me with?',
  history: history,
);
```

### Monitoring Token Usage

```dart
final results = await coordinator.processQuery(query);
final result = results.first;

if (result.tokenUsage != null) {
  print('Input tokens: ${result.tokenUsage!.inputTokens}');
  print('Output tokens: ${result.tokenUsage!.outputTokens}');
  print('Total tokens: ${result.tokenUsage!.totalTokens}');
  print('Cost: \$${result.tokenUsage!.cost}');
}
```

### Tool Results

```dart
final results = await coordinator.processQuery(query);

for (final toolResult in results.first.toolResults) {
  if (toolResult.success) {
    print('${toolResult.toolName}: ${toolResult.data}');
  } else {
    print('${toolResult.toolName} failed: ${toolResult.error}');
  }
}
```

## Tips

1. **Start simple**: Begin with a single agent and a few tools
2. **Use appropriate models**: DeepSeek for cost, GPT-4 for quality
3. **Handle errors**: Always wrap API calls in try-catch
4. **Monitor costs**: Track token usage in production
5. **Test tools**: Verify tools work before connecting to agents
6. **System prompts**: Craft clear system prompts for better results

## Troubleshooting

### "Invalid API key"
- Check your API key is correct
- Ensure the key has appropriate permissions
- Verify you're using the correct provider

### "Tool execution failed"
- Check tool parameter schemas match LLM's function calls
- Verify tool logic handles edge cases
- Add error handling in tool execution

### "No experts found"
- Ensure expert keywords match query terms
- Check expert confidence levels
- Verify experts are added to lead agent

## Support

- [GitHub Issues](https://github.com/yourusername/agentic_architecture/issues)
- [Documentation](https://pub.dev/documentation/agentic_architecture/latest/)
- [Examples](../example/README.md)

