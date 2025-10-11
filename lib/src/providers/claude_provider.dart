import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/exceptions.dart';
import '../core/llm_provider.dart';
import '../core/message.dart';
import '../core/result.dart';

/// LLM provider for Anthropic's Claude API.
///
/// Supports Claude 3 (Opus, Sonnet, Haiku) and Claude 2 models.
/// Pricing varies by model - see https://www.anthropic.com/pricing
class ClaudeProvider extends HttpLLMProvider {
  @override
  final String apiKey;

  @override
  final String baseUrl;

  @override
  final String? model;

  /// API version to use.
  final String apiVersion;

  ClaudeProvider({
    required this.apiKey,
    this.baseUrl = 'https://api.anthropic.com',
    this.model = 'claude-3-sonnet-20240229',
    this.apiVersion = '2023-06-01',
  });

  @override
  String get name => 'claude';

  @override
  bool get supportsToolCalling => true;

  @override
  bool get supportsStreaming => true;

  @override
  String? get defaultModel => 'claude-3-sonnet-20240229';

  @override
  Map<String, String> get commonHeaders {
    return {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': apiVersion,
    };
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
      // Build messages array (Claude format is similar to OpenAI)
      final messages = <Map<String, dynamic>>[];

      // Add history
      if (history != null) {
        for (final msg in history) {
          // Skip system messages in history (will be added separately)
          if (msg.role != MessageRole.system) {
            messages.add(_convertMessage(msg));
          }
        }
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
        'max_tokens': maxTokens ?? 1024,
        'temperature': temperature,
      };

      // Add system prompt if provided
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        requestBody['system'] = systemPrompt;
      }

      // Add tools if provided
      if (tools != null && tools.isNotEmpty) {
        requestBody['tools'] = tools.map((t) => _convertTool(t)).toList();
      }

      // Make API request
      final response = await http.post(
        Uri.parse('$baseUrl/v1/messages'),
        headers: commonHeaders,
        body: json.encode(requestBody),
      );

      if (response.statusCode != 200) {
        throw _handleError(response);
      }

      // Parse response
      final responseBody = json.decode(response.body) as Map<String, dynamic>;

      final content = _extractContent(responseBody);
      final toolCalls = _parseToolCalls(responseBody);
      final usage = responseBody['usage'] as Map<String, dynamic>;

      return LLMResponse(
        content: content,
        toolCalls: toolCalls,
        inputTokens: usage['input_tokens'] as int,
        outputTokens: usage['output_tokens'] as int,
        model: responseBody['model'] as String?,
        metadata: {
          'stop_reason': responseBody['stop_reason'],
          'usage': usage,
        },
      );
    } catch (e, stackTrace) {
      if (e is LLMProviderException) rethrow;

      throw LLMProviderException(
        'Claude API request failed: $e',
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

      // Add history
      if (history != null) {
        for (final msg in history) {
          if (msg.role != MessageRole.system) {
            messages.add(_convertMessage(msg));
          }
        }
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
        'max_tokens': maxTokens ?? 1024,
        'temperature': temperature,
        'stream': true,
      };

      // Add system prompt if provided
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        requestBody['system'] = systemPrompt;
      }

      // Make streaming request
      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl/v1/messages'),
      );
      request.headers.addAll(commonHeaders);
      request.body = json.encode(requestBody);

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        throw LLMProviderException(
          'Claude streaming request failed: ${streamedResponse.statusCode}',
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

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final type = json['type'] as String?;

              if (type == 'content_block_delta') {
                final delta = json['delta'] as Map<String, dynamic>;
                final text = delta['text'] as String?;
                if (text != null) {
                  yield text;
                }
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
        'Claude streaming failed: $e',
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

    if (currentModel.contains('opus')) {
      // Claude 3 Opus: $15/1M input, $75/1M output
      return ((inputTokens / 1000000) * 15.0) +
          ((outputTokens / 1000000) * 75.0);
    } else if (currentModel.contains('sonnet')) {
      // Claude 3 Sonnet: $3/1M input, $15/1M output
      return ((inputTokens / 1000000) * 3.0) +
          ((outputTokens / 1000000) * 15.0);
    } else if (currentModel.contains('haiku')) {
      // Claude 3 Haiku: $0.25/1M input, $1.25/1M output
      return ((inputTokens / 1000000) * 0.25) +
          ((outputTokens / 1000000) * 1.25);
    }

    // Default pricing (Sonnet)
    return ((inputTokens / 1000000) * 3.0) + ((outputTokens / 1000000) * 15.0);
  }

  Map<String, dynamic> _convertMessage(LLMMessage message) {
    return {
      'role': message.role == MessageRole.assistant ? 'assistant' : 'user',
      'content': message.content,
    };
  }

  Map<String, dynamic> _convertTool(ToolSchema schema) {
    return {
      'name': schema.function.name,
      'description': schema.function.description,
      'input_schema': schema.function.parameters,
    };
  }

  String _extractContent(Map<String, dynamic> response) {
    final content = response['content'] as List<dynamic>?;
    if (content == null || content.isEmpty) return '';

    final buffer = StringBuffer();
    for (final block in content) {
      if (block is Map<String, dynamic>) {
        final type = block['type'] as String?;
        if (type == 'text') {
          buffer.write(block['text'] as String? ?? '');
        }
      }
    }

    return buffer.toString();
  }

  List<ToolCall> _parseToolCalls(Map<String, dynamic> response) {
    final content = response['content'] as List<dynamic>?;
    if (content == null) return [];

    final toolCalls = <ToolCall>[];
    for (final block in content) {
      if (block is Map<String, dynamic>) {
        final type = block['type'] as String?;
        if (type == 'tool_use') {
          toolCalls.add(ToolCall(
            id: block['id'] as String,
            type: 'function',
            function: ToolFunction(
              name: block['name'] as String,
              arguments: json.encode(block['input']),
            ),
          ));
        }
      }
    }

    return toolCalls;
  }

  LLMProviderException _handleError(http.Response response) {
    try {
      final errorBody = json.decode(response.body) as Map<String, dynamic>;
      final error = errorBody['error'] as Map<String, dynamic>?;

      if (error != null) {
        final message = error['message'] as String? ?? 'Unknown error';
        final type = error['type'] as String?;

        if (type == 'authentication_error' ||
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
      'Claude API error: ${response.statusCode}',
      providerName: name,
      statusCode: response.statusCode,
      details: response.body,
    );
  }
}
