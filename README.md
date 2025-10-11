# Agentic Architecture

A production-ready Flutter package for building intelligent agent-based applications with support for:

- 🤖 **Single Lead Agent** with tools (simple mode)
- 🧠 **Mixture of Experts (MOE)** with multiple specialized sub-agents
- 🔌 **Pluggable LLM Providers** (OpenAI, DeepSeek, Claude, Gemini, custom)
- 🎯 **Per-Agent LLM Configuration** - each agent can use different providers
- 📊 **Educational Features** - token tracking, cost analysis, and learning logs
- 🎨 **Optional UI Widgets** for Flutter apps

## Features

### Core Capabilities

- **Agent Abstraction**: Build custom agents with different LLM providers and tools
- **Tool System**: Extensible tool interface for function calling
- **Multi-Provider Support**: Switch between OpenAI, DeepSeek, Claude, Gemini, or implement your own
- **MOE Architecture**: Coordinate multiple expert agents for complex tasks
- **Intelligent Routing**: Automatically route queries to the best expert(s)
- **Response Synthesis**: Combine multiple expert responses into coherent answers

### Optional Features

- **Conversation Memory**: Multi-turn conversation support
- **Response Formatting**: Natural language formatting of tool outputs
- **Cost Tracking**: Monitor token usage and costs per provider
- **Logging & Debugging**: Verbose logging for development
- **UI Widgets**: Pre-built Flutter widgets for agent interfaces

## Quick Start

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  agentic_architecture: ^0.1.0
```

Or run:

```bash
flutter pub add agentic_architecture
```

### Simple Mode Example

```dart
import 'package:agentic_architecture/agentic_architecture.dart';

// 1. Create LLM provider
final llm = DeepSeekProvider(
  apiKey: 'your-api-key',
);

// 2. Create tools
final tools = [
  CalculatorTool(),
];

// 3. Create simple agent
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
final results = await coordinator.processQuery('What is 25 * 4?');
print(results.first.content);
```

### MOE Mode Example

```dart
import 'package:agentic_architecture/agentic_architecture.dart';

// Create different LLM providers for different experts
final cheapLLM = DeepSeekProvider(apiKey: 'key1');
final smartLLM = OpenAIProvider(apiKey: 'key2', model: 'gpt-4');

// Create expert agents
final weatherExpert = ExpertAgent(
  id: 'weather_expert',
  name: 'Weather Expert',
  domain: 'weather',
  keywords: ['weather', 'temperature', 'forecast', 'rain'],
  llmProvider: cheapLLM,
  tools: [WeatherTool()],
);

final mathExpert = ExpertAgent(
  id: 'math_expert',
  name: 'Math Expert',
  domain: 'mathematics',
  keywords: ['calculate', 'math', 'number', 'equation'],
  llmProvider: cheapLLM,
  tools: [CalculatorTool()],
);

// Create lead agent with experts
final leadAgent = LeadAgent(
  id: 'lead',
  name: 'Lead Assistant',
  llmProvider: smartLLM,
  experts: [weatherExpert, mathExpert],
  strategy: DelegationStrategy.intelligent,
);

// Create coordinator in MOE mode
final coordinator = AgentCoordinator(
  leadAgent: leadAgent,
  mode: AgentMode.moe,
  enableLogging: true,
);

// Process query - lead decides which experts to consult
final results = await coordinator.processQuery(
  'What is the weather and what is 15 + 27?'
);
```

## Custom LLM Provider

Implement your own LLM provider:

```dart
class MyCustomProvider extends LLMProvider {
  @override
  String get name => 'my_custom_llm';
  
  @override
  Future<LLMResponse> chat({
    required String message,
    List<LLMMessage>? history,
    List<ToolSchema>? tools,
    double temperature = 0.7,
    int maxTokens = 1024,
  }) async {
    // Your custom implementation
    final response = await myAPI.call(message);
    return LLMResponse(
      content: response.text,
      toolCalls: response.functions,
      inputTokens: response.usage.input,
      outputTokens: response.usage.output,
    );
  }
  
  @override
  double calculateCost(int inputTokens, int outputTokens) {
    return (inputTokens + outputTokens) * 0.0001;
  }
}
```

## Documentation

- [Getting Started Guide](doc/getting_started.md)
- [Architecture Overview](doc/architecture.md)
- [MOE Guide](doc/moe_guide.md)
- [Custom LLM Provider](doc/custom_llm.md)
- [API Reference](https://pub.dev/documentation/agentic_architecture/latest/)

## Examples

Check out the [example](example/) directory for complete working examples:

- **Simple Agent App**: Basic agent with tools
- **MOE Agent App**: Multi-expert system
- **Custom LLM App**: Implementing custom providers

## Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md) first.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.

