import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/exceptions.dart';
import '../core/llm_provider.dart';
import '../core/message.dart';
import '../core/result.dart';

/// LLM provider for OpenAI API.
///
/// Supports GPT-3.5, GPT-4, and other OpenAI models.
/// Pricing varies by model - see https://openai.com/pricing
class OpenAIProvider extends HttpLLMProvider {
  @override
  final String apiKey;

  @override
  final String baseUrl;

  @override
  final String? model;

  /// Optional organization ID.
  final String? organizationId;

  OpenAIProvider({
    required this.apiKey,
    this.baseUrl = 'https://api.openai.com',
    this.model = 'gpt-4-turbo',
    this.organizationId,
  });

  @override
  String get name => 'openai';

  @override
  bool get supportsToolCalling => true;

  @override
  bool get supportsStreaming => true;

  @override
  String? get defaultModel => 'gpt-4-turbo';

  @override
  Map<String, String> get commonHeaders {
    final headers = super.commonHeaders;
    if (organizationId != null) {
      headers['OpenAI-Organization'] = organizationId!;
    }
    return headers;
  }

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
      // Build messages array
      final messages = <Map<String, dynamic>>[];

      // Add system prompt if provided
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }

      // Add history
      if (history != null) {
        messages.addAll(history.map((m) => m.toJson()));
      }

      // Add current message
      messages.add({
        'role': 'user',
        'content': message,
      });

      // Build request body
      final requestBody = <String, dynamic>{
        'model': model ?? defaultModel,
        'messages': messages,
        'temperature': temperature,
      };

      if (maxTokens != null) {
        requestBody['max_tokens'] = maxTokens;
      }

      // Add tools if provided
      if (tools != null && tools.isNotEmpty) {
        requestBody['tools'] = tools.map((t) => t.toJson()).toList();
        requestBody['tool_choice'] = 'auto';
      }

      // Make API request
      final response = await http.post(
        Uri.parse('$baseUrl/v1/chat/completions'),
        headers: commonHeaders,
        body: json.encode(requestBody),
      );

      if (response.statusCode != 200) {
        throw _handleError(response);
      }

      // Parse response
      final responseBody = json.decode(response.body) as Map<String, dynamic>;

      final choice = responseBody['choices'][0] as Map<String, dynamic>;
      final messageContent = choice['message'] as Map<String, dynamic>;
      final usage = responseBody['usage'] as Map<String, dynamic>;

      final content = messageContent['content'] as String? ?? '';
      final toolCalls = _parseToolCalls(messageContent);

      return LLMResponse(
        content: content,
        toolCalls: toolCalls,
        inputTokens: usage['prompt_tokens'] as int,
        outputTokens: usage['completion_tokens'] as int,
        model: responseBody['model'] as String?,
        metadata: {
          'finish_reason': choice['finish_reason'],
          'usage': usage,
        },
      );
    } catch (e, stackTrace) {
      if (e is LLMProviderException) rethrow;

      throw LLMProviderException(
        'OpenAI API request failed: $e',
        providerName: name,
        details: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Stream<String> chatStream({
    required String message,
    List<LLMMessage>? history,
    double temperature = 0.7,
    int? maxTokens,
    String? systemPrompt,
  }) async* {
    try {
      // Build messages array
      final messages = <Map<String, dynamic>>[];

      // Add system prompt if provided
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }

      // Add history
      if (history != null) {
        messages.addAll(history.map((m) => m.toJson()));
      }

      // Add current message
      messages.add({
        'role': 'user',
        'content': message,
      });

      // Build request body
      final requestBody = <String, dynamic>{
        'model': model ?? defaultModel,
        'messages': messages,
        'temperature': temperature,
        'stream': true,
      };

      if (maxTokens != null) {
        requestBody['max_tokens'] = maxTokens;
      }

      // Make streaming request
      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl/v1/chat/completions'),
      );
      request.headers.addAll(commonHeaders);
      request.body = json.encode(requestBody);

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        throw LLMProviderException(
          'OpenAI streaming request failed: ${streamedResponse.statusCode}',
          providerName: name,
          statusCode: streamedResponse.statusCode,
        );
      }

      // Parse SSE stream
      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') continue;

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final delta = json['choices'][0]['delta'] as Map<String, dynamic>;
              final content = delta['content'] as String?;
              if (content != null) {
                yield content;
              }
            } catch (_) {
              // Skip malformed chunks
            }
          }
        }
      }
    } catch (e, stackTrace) {
      if (e is LLMProviderException) rethrow;

      throw LLMProviderException(
        'OpenAI streaming failed: $e',
        providerName: name,
        details: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  double calculateCost(int inputTokens, int outputTokens) {
    // Pricing varies by model
    final currentModel = model ?? defaultModel ?? '';

    if (currentModel.startsWith('gpt-4-turbo')) {
      // GPT-4 Turbo: $10/1M input, $30/1M output
      return ((inputTokens / 1000000) * 10.0) +
          ((outputTokens / 1000000) * 30.0);
    } else if (currentModel.startsWith('gpt-4')) {
      // GPT-4: $30/1M input, $60/1M output
      return ((inputTokens / 1000000) * 30.0) +
          ((outputTokens / 1000000) * 60.0);
    } else if (currentModel.startsWith('gpt-3.5-turbo')) {
      // GPT-3.5 Turbo: $0.50/1M input, $1.50/1M output
      return ((inputTokens / 1000000) * 0.5) + ((outputTokens / 1000000) * 1.5);
    }

    // Default pricing (GPT-4 Turbo)
    return ((inputTokens / 1000000) * 10.0) + ((outputTokens / 1000000) * 30.0);
  }

  List<ToolCall> _parseToolCalls(Map<String, dynamic> message) {
    final toolCallsJson = message['tool_calls'] as List<dynamic>?;
    if (toolCallsJson == null) return [];

    return toolCallsJson
        .map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
        .toList();
  }

  LLMProviderException _handleError(http.Response response) {
    try {
      final errorBody = json.decode(response.body) as Map<String, dynamic>;
      final error = errorBody['error'] as Map<String, dynamic>?;

      if (error != null) {
        final message = error['message'] as String? ?? 'Unknown error';
        final type = error['type'] as String?;

        if (type == 'invalid_api_key' ||
            response.statusCode == 401 ||
            response.statusCode == 403) {
          return AuthenticationException(
            message,
            providerName: name,
            details: error,
          );
        }

        if (response.statusCode == 429) {
          return RateLimitException(
            message,
            providerName: name,
            details: error,
          );
        }

        return LLMProviderException(
          message,
          providerName: name,
          statusCode: response.statusCode,
          details: error,
        );
      }
    } catch (_) {
      // Failed to parse error, return generic error
    }

    return LLMProviderException(
      'OpenAI API error: ${response.statusCode}',
      providerName: name,
      statusCode: response.statusCode,
      details: response.body,
    );
  }
}
