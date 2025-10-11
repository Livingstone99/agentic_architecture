# Creating Custom LLM Providers

This guide explains how to integrate custom LLM providers into the `agentic_architecture` package.

## Overview

The package uses an abstract `LLMProvider` interface that you can implement to add support for any LLM API.

## LLMProvider Interface

```dart
abstract class LLMProvider {
  /// The name of this provider
  String get name;

  /// Main chat method
  Future<LLMResponse> chat({
    required String message,
    List<LLMMessage>? history,
    List<ToolSchema>? tools,
    double temperature = 0.7,
    int? maxTokens,
    String? systemPrompt,
  });

  /// Streaming chat (optional)
  Stream<String> chatStream({
    required String message,
    List<LLMMessage>? history,
    double temperature = 0.7,
    int? maxTokens,
    String? systemPrompt,
  });

  /// Calculate cost in USD
  double calculateCost(int inputTokens, int outputTokens);

  /// Feature flags
  bool get supportsStreaming;
  bool get supportsToolCalling;
  String? get defaultModel;
}
```

## Basic Implementation

### Step 1: Create Provider Class

```dart
import 'package:agentic_architecture/agentic_architecture.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyCustomProvider extends LLMProvider {
  final String apiKey;
  final String baseUrl;
  final String model;

  MyCustomProvider({
    required this.apiKey,
    required this.baseUrl,
    this.model = 'my-model-v1',
  });

  @override
  String get name => 'my_custom_provider';

  @override
  String? get defaultModel => 'my-model-v1';

  @override
  bool get supportsToolCalling => true;

  @override
  bool get supportsStreaming => false;

  @override
  Future<LLMResponse> chat({
    required String message,
    List<LLMMessage>? history,
    List<ToolSchema>? tools,
    double temperature = 0.7,
    int? maxTokens,
    String? systemPrompt,
  }) async {
    // Implementation here
  }

  @override
  double calculateCost(int inputTokens, int outputTokens) {
    // Your pricing logic
    return (inputTokens * 0.0001) + (outputTokens * 0.0002);
  }
}
```

### Step 2: Implement Chat Method

```dart
@override
Future<LLMResponse> chat({
  required String message,
  List<LLMMessage>? history,
  List<ToolSchema>? tools,
  double temperature = 0.7,
  int? maxTokens,
  String? systemPrompt,
}) async {
  try {
    // 1. Build messages array
    final messages = <Map<String, dynamic>>[];

    if (systemPrompt != null) {
      messages.add({
        'role': 'system',
        'content': systemPrompt,
      });
    }

    if (history != null) {
      messages.addAll(history.map((m) => m.toJson()));
    }

    messages.add({
      'role': 'user',
      'content': message,
    });

    // 2. Build request body
    final requestBody = {
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens ?? 1024,
    };

    if (tools != null && tools.isNotEmpty) {
      requestBody['tools'] = tools.map((t) => t.toJson()).toList();
    }

    // 3. Make HTTP request
    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: json.encode(requestBody),
    );

    // 4. Handle errors
    if (response.statusCode != 200) {
      throw LLMProviderException(
        'API request failed: ${response.statusCode}',
        providerName: name,
        statusCode: response.statusCode,
      );
    }

    // 5. Parse response
    final responseData = json.decode(response.body);
    final choice = responseData['choices'][0];
    final messageData = choice['message'];
    final usage = responseData['usage'];

    return LLMResponse(
      content: messageData['content'] ?? '',
      toolCalls: _parseToolCalls(messageData),
      inputTokens: usage['prompt_tokens'] ?? 0,
      outputTokens: usage['completion_tokens'] ?? 0,
      model: model,
    );
  } catch (e, stackTrace) {
    throw LLMProviderException(
      'Request failed: $e',
      providerName: name,
      details: e,
      stackTrace: stackTrace,
    );
  }
}

List<ToolCall> _parseToolCalls(Map<String, dynamic> message) {
  final toolCalls = message['tool_calls'] as List?;
  if (toolCalls == null) return [];

  return toolCalls
      .map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
      .toList();
}
```

### Step 3: Implement Cost Calculation

```dart
@override
double calculateCost(int inputTokens, int outputTokens) {
  // Example pricing:
  // $0.50 per 1M input tokens
  // $1.50 per 1M output tokens
  
  const inputCostPerMillion = 0.50;
  const outputCostPerMillion = 1.50;

  return ((inputTokens / 1000000) * inputCostPerMillion) +
         ((outputTokens / 1000000) * outputCostPerMillion);
}
```

## Advanced Features

### Streaming Support

```dart
@override
bool get supportsStreaming => true;

@override
Stream<String> chatStream({
  required String message,
  List<LLMMessage>? history,
  double temperature = 0.7,
  int? maxTokens,
  String? systemPrompt,
}) async* {
  // Build request similar to chat()
  final requestBody = {
    // ... same as chat()
    'stream': true,
  };

  final request = http.Request('POST', Uri.parse('$baseUrl/chat/completions'));
  request.headers.addAll({
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  });
  request.body = json.encode(requestBody);

  final streamedResponse = await request.send();

  await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
    // Parse Server-Sent Events (SSE)
    final lines = chunk.split('\n');
    for (final line in lines) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6);
        if (data == '[DONE]') continue;

        try {
          final json = jsonDecode(data);
          final delta = json['choices'][0]['delta'];
          final content = delta['content'];
          if (content != null) {
            yield content as String;
          }
        } catch (_) {
          // Skip malformed chunks
        }
      }
    }
  }
}
```

### Error Handling

```dart
LLMProviderException _handleError(http.Response response) {
  try {
    final errorData = json.decode(response.body);
    final error = errorData['error'];

    if (error != null) {
      final message = error['message'] ?? 'Unknown error';

      // Authentication errors
      if (response.statusCode == 401 || response.statusCode == 403) {
        return AuthenticationException(
          message,
          providerName: name,
        );
      }

      // Rate limit errors
      if (response.statusCode == 429) {
        return RateLimitException(
          message,
          providerName: name,
        );
      }

      return LLMProviderException(
        message,
        providerName: name,
        statusCode: response.statusCode,
      );
    }
  } catch (_) {
    // Failed to parse error
  }

  return LLMProviderException(
    'Request failed: ${response.statusCode}',
    providerName: name,
    statusCode: response.statusCode,
  );
}
```

### Configuration Validation

```dart
@override
void validateConfiguration() {
  if (apiKey.isEmpty) {
    throw ConfigurationException(
      'API key is required for $name provider',
    );
  }

  if (baseUrl.isEmpty) {
    throw ConfigurationException(
      'Base URL is required for $name provider',
    );
  }
}
```

## Using HTTP Base Class

For HTTP-based providers, extend `HttpLLMProvider`:

```dart
class MyProvider extends HttpLLMProvider {
  @override
  final String apiKey;

  @override
  final String baseUrl;

  @override
  final String? model;

  MyProvider({
    required this.apiKey,
    required this.baseUrl,
    this.model,
  });

  @override
  String get name => 'my_provider';

  @override
  Map<String, String> get commonHeaders {
    return {
      ...super.commonHeaders,
      'X-Custom-Header': 'value',
    };
  }

  // Implement chat() and calculateCost()
}
```

## Testing Your Provider

### Unit Tests

```dart
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('MyCustomProvider', () {
    test('chat returns valid response', () async {
      final provider = MyCustomProvider(
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com',
      );

      final response = await provider.chat(
        message: 'Hello',
      );

      expect(response.content, isNotEmpty);
      expect(response.inputTokens, greaterThan(0));
      expect(response.outputTokens, greaterThan(0));
    });

    test('calculateCost returns correct value', () {
      final provider = MyCustomProvider(
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com',
      );

      final cost = provider.calculateCost(1000, 500);
      expect(cost, greaterThan(0));
    });

    test('throws on invalid API key', () {
      final provider = MyCustomProvider(
        apiKey: '',
        baseUrl: 'https://api.example.com',
      );

      expect(
        () => provider.validateConfiguration(),
        throwsA(isA<ConfigurationException>()),
      );
    });
  });
}
```

### Integration Tests

```dart
void main() {
  group('Integration Tests', () {
    test('works with SimpleAgent', () async {
      final provider = MyCustomProvider(
        apiKey: Platform.environment['MY_API_KEY']!,
        baseUrl: 'https://api.example.com',
      );

      final agent = SimpleAgent(
        id: 'test',
        name: 'Test Agent',
        llmProvider: provider,
        tools: [EchoTool()],
      );

      final coordinator = AgentCoordinator(
        leadAgent: agent,
        mode: AgentMode.simple,
      );

      final results = await coordinator.processQuery('Hello');
      expect(results, isNotEmpty);
    });
  });
}
```

## Complete Example

```dart
import 'package:agentic_architecture/agentic_architecture.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Custom provider for Example AI API
class ExampleAIProvider extends HttpLLMProvider {
  @override
  final String apiKey;

  @override
  final String baseUrl;

  @override
  final String? model;

  ExampleAIProvider({
    required this.apiKey,
    this.baseUrl = 'https://api.example-ai.com',
    this.model = 'example-v1',
  });

  @override
  String get name => 'example_ai';

  @override
  bool get supportsToolCalling => true;

  @override
  bool get supportsStreaming => true;

  @override
  String? get defaultModel => 'example-v1';

  @override
  Future<LLMResponse> chat({
    required String message,
    List<LLMMessage>? history,
    List<ToolSchema>? tools,
    double temperature = 0.7,
    int? maxTokens,
    String? systemPrompt,
  }) async {
    try {
      validateConfiguration();

      final messages = _buildMessages(message, history, systemPrompt);
      final requestBody = _buildRequestBody(
        messages,
        tools,
        temperature,
        maxTokens,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/v1/chat/completions'),
        headers: commonHeaders,
        body: json.encode(requestBody),
      );

      if (response.statusCode != 200) {
        throw _handleError(response);
      }

      return _parseResponse(response);
    } catch (e, stackTrace) {
      if (e is LLMProviderException) rethrow;

      throw LLMProviderException(
        'Chat request failed: $e',
        providerName: name,
        details: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  double calculateCost(int inputTokens, int outputTokens) {
    // $1.00 per 1M input, $2.00 per 1M output
    return ((inputTokens / 1000000) * 1.0) +
           ((outputTokens / 1000000) * 2.0);
  }

  List<Map<String, dynamic>> _buildMessages(
    String message,
    List<LLMMessage>? history,
    String? systemPrompt,
  ) {
    final messages = <Map<String, dynamic>>[];

    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    if (history != null) {
      messages.addAll(history.map((m) => m.toJson()));
    }

    messages.add({'role': 'user', 'content': message});

    return messages;
  }

  Map<String, dynamic> _buildRequestBody(
    List<Map<String, dynamic>> messages,
    List<ToolSchema>? tools,
    double temperature,
    int? maxTokens,
  ) {
    final body = {
      'model': model ?? defaultModel,
      'messages': messages,
      'temperature': temperature,
    };

    if (maxTokens != null) {
      body['max_tokens'] = maxTokens;
    }

    if (tools != null && tools.isNotEmpty) {
      body['tools'] = tools.map((t) => t.toJson()).toList();
      body['tool_choice'] = 'auto';
    }

    return body;
  }

  LLMResponse _parseResponse(http.Response response) {
    final data = json.decode(response.body);
    final choice = data['choices'][0];
    final message = choice['message'];
    final usage = data['usage'];

    return LLMResponse(
      content: message['content'] ?? '',
      toolCalls: _parseToolCalls(message),
      inputTokens: usage['prompt_tokens'],
      outputTokens: usage['completion_tokens'],
      model: data['model'],
    );
  }

  List<ToolCall> _parseToolCalls(Map<String, dynamic> message) {
    final toolCalls = message['tool_calls'] as List?;
    if (toolCalls == null) return [];

    return toolCalls
        .map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
        .toList();
  }

  LLMProviderException _handleError(http.Response response) {
    // Custom error handling logic
    return LLMProviderException(
      'Request failed: ${response.statusCode}',
      providerName: name,
      statusCode: response.statusCode,
      details: response.body,
    );
  }
}

// Usage
void main() async {
  final provider = ExampleAIProvider(
    apiKey: 'your-api-key',
  );

  final agent = SimpleAgent(
    id: 'agent',
    name: 'My Agent',
    llmProvider: provider,
    tools: [CalculatorTool()],
  );

  final coordinator = AgentCoordinator(
    leadAgent: agent,
    mode: AgentMode.simple,
  );

  final results = await coordinator.processQuery('What is 2+2?');
  print(results.first.content);
}
```

## Best Practices

1. **Validate configuration** in constructor or validateConfiguration()
2. **Handle all error cases** appropriately
3. **Parse responses carefully** - handle missing fields
4. **Calculate costs accurately** - check provider pricing
5. **Support UTF-8** encoding for non-English text
6. **Add retry logic** for transient failures
7. **Rate limit handling** - implement exponential backoff
8. **Test thoroughly** with real API calls

## Common Patterns

### Retry Logic

```dart
Future<LLMResponse> _retryRequest(
  Future<LLMResponse> Function() request,
  {int maxRetries = 3}
) async {
  for (var i = 0; i < maxRetries; i++) {
    try {
      return await request();
    } on RateLimitException {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(Duration(seconds: 2 << i)); // Exponential backoff
    }
  }
  throw Exception('Max retries exceeded');
}
```

### Request Timeout

```dart
final response = await http.post(url, headers: headers, body: body)
    .timeout(Duration(seconds: 30));
```

### Custom Headers

```dart
@override
Map<String, String> get commonHeaders {
  return {
    ...super.commonHeaders,
    'X-API-Version': '2024-01',
    'X-Request-ID': Uuid().v4(),
  };
}
```

## Next Steps

- Review [built-in providers](../lib/src/providers/)
- Test with [examples](../example/)
- Read [architecture guide](architecture.md)
- Check [API reference](https://pub.dev/documentation/agentic_architecture/latest/)

