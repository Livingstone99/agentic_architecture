# Agentic Architecture Examples

This directory contains example applications demonstrating how to use the `agentic_architecture` package.

## Running Examples

### 1. Simple Example (Mock LLM)
Basic demonstration with mock LLM provider:

```bash
dart run example/simple_example.dart
```

Shows: LLM provider setup, tools, basic agent creation.

### 2. Simple Chat Example (Real DeepSeek)
Multi-turn conversational agent:

```bash
dart run example/simple_chat_example.dart
```

Shows: Conversation history, context awareness, natural dialogue flow.

### 3. Simple Task Agent Example (Real DeepSeek)
Specialized task-focused agents:

```bash
dart run example/simple_task_agent_example.dart
```

Shows: Custom prompts for different tasks, temperature control, data analyst/writer/problem-solver agents.

### 4. MOE Example (Mock LLM)
Basic MOE demonstration:

```bash
dart run example/moe_example.dart
```

Shows: Multiple experts, delegation strategies, response synthesis.

### 5. MOE Advanced Example (Real DeepSeek)
Production-ready MOE system:

```bash
dart run example/moe_advanced_example.dart
```

Shows: 4 specialized experts, intelligent routing, real-world multi-domain queries, comprehensive response synthesis.

## Example Structure

### Simple Mode
```
User Query
    ↓
Lead Agent + Tools
    ↓
Response
```

### MOE Mode
```
User Query
    ↓
Lead Agent
    ├→ Expert 1 (Weather) + Tools
    ├→ Expert 2 (Math) + Tools
    └→ Expert 3 (General) + Tools
    ↓
Response Synthesis
    ↓
Unified Response
```

## Using Real LLM Providers

The examples use `MockLLMProvider` for demonstration. To use real providers:

### DeepSeek
```dart
final llm = DeepSeekProvider(
  apiKey: 'your-deepseek-api-key',
);
```

### OpenAI
```dart
final llm = OpenAIProvider(
  apiKey: 'your-openai-api-key',
  model: 'gpt-4-turbo',
);
```

### Claude (Anthropic)
```dart
final llm = ClaudeProvider(
  apiKey: 'your-claude-api-key',
  model: 'claude-3-sonnet-20240229',
);
```

### Gemini (Google)
```dart
final llm = GeminiProvider(
  apiKey: 'your-gemini-api-key',
);
```

## Creating Custom Tools

```dart
class MyCustomTool extends Tool {
  @override
  String get name => 'my_tool';

  @override
  String get description => 'What this tool does';

  @override
  Map<String, dynamic> get parameterSchema => {
    'type': 'object',
    'properties': {
      'param1': {
        'type': 'string',
        'description': 'Description of param1',
      },
    },
    'required': ['param1'],
  };

  @override
  Future<ToolResult> execute(Map<String, dynamic> params) async {
    // Your tool implementation
    final param1 = params['param1'] as String;
    
    return ToolResult.success(
      toolName: name,
      data: {'result': 'something'},
    );
  }
}
```

## Delegation Strategies

Try different strategies in the MOE example:

### Single
Delegates to the best-matching expert only:
```dart
strategy: DelegationStrategy.single
```

### Parallel
Queries multiple experts simultaneously:
```dart
strategy: DelegationStrategy.parallel
```

### Sequential
Queries experts one by one:
```dart
strategy: DelegationStrategy.sequential
```

### Intelligent
Lets the LLM decide how to delegate:
```dart
strategy: DelegationStrategy.intelligent
```

## Next Steps

1. Check out the [main documentation](../README.md)
2. Read the [architecture guide](../doc/architecture.md)
3. Learn about [MOE systems](../doc/moe_guide.md)
4. Build your own custom agents and tools!

