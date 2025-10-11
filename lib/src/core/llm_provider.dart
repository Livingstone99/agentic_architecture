import 'exceptions.dart';
import 'message.dart';
import 'result.dart';

/// Abstract base class for all LLM providers.
///
/// Implement this class to add support for new LLM providers like OpenAI,
/// Claude, DeepSeek, Gemini, or custom providers.
abstract class LLMProvider {
  /// The name of this provider (e.g., 'openai', 'deepseek', 'claude').
  String get name;

  /// Sends a chat message to the LLM and returns the response.
  ///
  /// Parameters:
  /// - [message]: The user message to send
  /// - [history]: Previous conversation messages for context
  /// - [tools]: Available tools the LLM can call
  /// - [temperature]: Controls randomness (0.0 = deterministic, 1.0 = creative)
  /// - [maxTokens]: Maximum tokens to generate in the response
  /// - [systemPrompt]: Optional system prompt to guide the LLM's behavior
  ///
  /// Returns an [LLMResponse] containing the generated text and any tool calls.
  Future<LLMResponse> chat({
    required String message,
    List<LLMMessage>? history,
    List<ToolSchema>? tools,
    double temperature = 0.7,
    int? maxTokens,
    String? systemPrompt,
  });

  /// Sends a chat message and streams the response.
  ///
  /// This is useful for real-time UI updates as the response is generated.
  /// Not all providers support streaming.
  ///
  /// Returns a [Stream] of text chunks as they are generated.
  Stream<String> chatStream({
    required String message,
    List<LLMMessage>? history,
    double temperature = 0.7,
    int? maxTokens,
    String? systemPrompt,
  }) {
    throw LLMProviderException(
      'Streaming not supported by this provider',
      providerName: name,
    );
  }

  /// Calculates the cost of a request in USD based on token usage.
  ///
  /// Different providers and models have different pricing.
  /// Returns 0.0 if pricing information is not available.
  double calculateCost(int inputTokens, int outputTokens);

  /// Checks if this provider supports streaming responses.
  bool get supportsStreaming => false;

  /// Checks if this provider supports function/tool calling.
  bool get supportsToolCalling => false;

  /// The default model name used by this provider.
  String? get defaultModel => null;

  /// Validates the configuration of this provider.
  ///
  /// Throws [ConfigurationException] if the configuration is invalid.
  void validateConfiguration() {
    // Override in subclasses to add validation
  }

  @override
  String toString() => 'LLMProvider($name)';
}

/// Base class for HTTP-based LLM providers.
///
/// Provides common functionality for providers that use HTTP APIs.
abstract class HttpLLMProvider extends LLMProvider {
  /// The base URL for the API.
  String get baseUrl;

  /// The API key for authentication.
  String get apiKey;

  /// The model to use for requests.
  String? get model;

  /// Common headers to include in all requests.
  Map<String, String> get commonHeaders {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $apiKey',
    };
  }

  @override
  void validateConfiguration() {
    if (apiKey.isEmpty) {
      throw ConfigurationException(
        'API key is required for $name provider',
      );
    }
  }
}

/// Configuration for an LLM provider.
class LLMConfig {
  /// The model to use.
  final String? model;

  /// Default temperature for requests.
  final double? temperature;

  /// Default maximum tokens for responses.
  final int? maxTokens;

  /// Default system prompt.
  final String? systemPrompt;

  /// Additional provider-specific configuration.
  final Map<String, dynamic> extra;

  const LLMConfig({
    this.model,
    this.temperature,
    this.maxTokens,
    this.systemPrompt,
    this.extra = const {},
  });

  /// Creates a copy of this config with updated fields.
  LLMConfig copyWith({
    String? model,
    double? temperature,
    int? maxTokens,
    String? systemPrompt,
    Map<String, dynamic>? extra,
  }) {
    return LLMConfig(
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      extra: extra ?? this.extra,
    );
  }

  /// Converts this config to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'systemPrompt': systemPrompt,
      'extra': extra,
    };
  }

  /// Creates a config from a JSON map.
  factory LLMConfig.fromJson(Map<String, dynamic> json) {
    return LLMConfig(
      model: json['model'] as String?,
      temperature: json['temperature'] as double?,
      maxTokens: json['maxTokens'] as int?,
      systemPrompt: json['systemPrompt'] as String?,
      extra: json['extra'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// A mock LLM provider for testing.
class MockLLMProvider extends LLMProvider {
  final String _name;
  final List<String> _responses;
  int _responseIndex = 0;

  MockLLMProvider({
    String name = 'mock',
    List<String> responses = const ['Mock response'],
  })  : _name = name,
        _responses = responses;

  @override
  String get name => _name;

  @override
  Future<LLMResponse> chat({
    required String message,
    List<LLMMessage>? history,
    List<ToolSchema>? tools,
    double temperature = 0.7,
    int? maxTokens,
    String? systemPrompt,
  }) async {
    final response = _responses[_responseIndex % _responses.length];
    _responseIndex++;

    return LLMResponse(
      content: response,
      inputTokens: message.length ~/ 4,
      outputTokens: response.length ~/ 4,
      model: 'mock-model',
    );
  }

  @override
  double calculateCost(int inputTokens, int outputTokens) {
    return 0.0; // Mock provider is free
  }

  @override
  bool get supportsToolCalling => true;

  @override
  String? get defaultModel => 'mock-model';
}
