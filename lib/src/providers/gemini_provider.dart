import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/exceptions.dart';
import '../core/llm_provider.dart';
import '../core/message.dart';
import '../core/result.dart';

/// LLM provider for Google's Gemini API.
///
/// Supports Gemini Pro and other Gemini models.
/// Pricing: https://ai.google.dev/pricing
class GeminiProvider extends LLMProvider {
  /// The API key for authentication.
  final String apiKey;

  /// The base URL for the API.
  final String baseUrl;

  /// The model to use.
  final String? model;

  GeminiProvider({
    required this.apiKey,
    this.baseUrl = 'https://generativelanguage.googleapis.com',
    this.model = 'gemini-pro',
  });

  @override
  String get name => 'gemini';

  @override
  bool get supportsToolCalling => true;

  @override
  bool get supportsStreaming => true;

  @override
  String? get defaultModel => 'gemini-pro';

  void _validateConfiguration() {
    if (apiKey.isEmpty) {
      throw ConfigurationException(
        'API key is required for Gemini provider',
      );
    }
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
    _validateConfiguration();

    try {
      // Build contents array (Gemini format)
      final contents = <Map<String, dynamic>>[];

      // Add history
      if (history != null) {
        for (final msg in history) {
          contents.add(_convertMessage(msg));
        }
      }

      // Add current message
      contents.add({
        'role': 'user',
        'parts': [
          {'text': message}
        ],
      });

      // Build request body
      final requestBody = <String, dynamic>{
        'contents': contents,
        'generationConfig': {
          'temperature': temperature,
        },
      };

      if (maxTokens != null) {
        requestBody['generationConfig']['maxOutputTokens'] = maxTokens;
      }

      // Add system instruction if provided
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        requestBody['systemInstruction'] = {
          'parts': [
            {'text': systemPrompt}
          ],
        };
      }

      // Add tools if provided
      if (tools != null && tools.isNotEmpty) {
        requestBody['tools'] = [
          {
            'functionDeclarations': tools.map((t) => _convertTool(t)).toList(),
          }
        ];
      }

      final currentModel = model ?? defaultModel;

      // Make API request
      final response = await http.post(
        Uri.parse(
          '$baseUrl/v1/models/$currentModel:generateContent?key=$apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode != 200) {
        throw _handleError(response);
      }

      // Parse response
      final responseBody = json.decode(response.body) as Map<String, dynamic>;

      final candidates = responseBody['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw LLMProviderException(
          'No candidates in Gemini response',
          providerName: name,
          details: responseBody,
        );
      }

      final candidate = candidates[0] as Map<String, dynamic>;
      final content = _extractContent(candidate);
      final toolCalls = _parseToolCalls(candidate);

      // Parse token usage
      final usageMetadata =
          responseBody['usageMetadata'] as Map<String, dynamic>?;
      final inputTokens = usageMetadata?['promptTokenCount'] as int? ?? 0;
      final outputTokens = usageMetadata?['candidatesTokenCount'] as int? ?? 0;

      return LLMResponse(
        content: content,
        toolCalls: toolCalls,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        model: currentModel,
        metadata: {
          'usage': usageMetadata,
        },
      );
    } catch (e, stackTrace) {
      if (e is LLMProviderException) rethrow;

      throw LLMProviderException(
        'Gemini API request failed: $e',
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
    _validateConfiguration();

    try {
      // Build contents array
      final contents = <Map<String, dynamic>>[];

      // Add history
      if (history != null) {
        for (final msg in history) {
          contents.add(_convertMessage(msg));
        }
      }

      // Add current message
      contents.add({
        'role': 'user',
        'parts': [
          {'text': message}
        ],
      });

      // Build request body
      final requestBody = <String, dynamic>{
        'contents': contents,
        'generationConfig': {
          'temperature': temperature,
        },
      };

      if (maxTokens != null) {
        requestBody['generationConfig']['maxOutputTokens'] = maxTokens;
      }

      // Add system instruction if provided
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        requestBody['systemInstruction'] = {
          'parts': [
            {'text': systemPrompt}
          ],
        };
      }

      final currentModel = model ?? defaultModel;

      // Make streaming request
      final request = http.Request(
        'POST',
        Uri.parse(
          '$baseUrl/v1/models/$currentModel:streamGenerateContent?key=$apiKey',
        ),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = json.encode(requestBody);

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        throw LLMProviderException(
          'Gemini streaming request failed: ${streamedResponse.statusCode}',
          providerName: name,
          statusCode: streamedResponse.statusCode,
        );
      }

      // Parse stream
      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        try {
          final json = jsonDecode(chunk) as Map<String, dynamic>;
          final candidates = json['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final candidate = candidates[0] as Map<String, dynamic>;
            final text = _extractContent(candidate);
            if (text.isNotEmpty) {
              yield text;
            }
          }
        } catch (_) {
          // Skip malformed chunks
        }
      }
    } catch (e, stackTrace) {
      if (e is LLMProviderException) rethrow;

      throw LLMProviderException(
        'Gemini streaming failed: $e',
        providerName: name,
        details: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  double calculateCost(int inputTokens, int outputTokens) {
    // Gemini Pro pricing (under 128k context):
    // $0.50 per 1M input tokens
    // $1.50 per 1M output tokens
    const inputCostPerMillion = 0.5;
    const outputCostPerMillion = 1.5;

    return ((inputTokens / 1000000) * inputCostPerMillion) +
        ((outputTokens / 1000000) * outputCostPerMillion);
  }

  Map<String, dynamic> _convertMessage(LLMMessage message) {
    final role =
        message.role == MessageRole.assistant ? 'model' : message.role.name;

    return {
      'role': role,
      'parts': [
        {'text': message.content}
      ],
    };
  }

  Map<String, dynamic> _convertTool(ToolSchema schema) {
    return {
      'name': schema.function.name,
      'description': schema.function.description,
      'parameters': schema.function.parameters,
    };
  }

  String _extractContent(Map<String, dynamic> candidate) {
    final content = candidate['content'] as Map<String, dynamic>?;
    if (content == null) return '';

    final parts = content['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return '';

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map<String, dynamic>) {
        final text = part['text'] as String?;
        if (text != null) {
          buffer.write(text);
        }
      }
    }

    return buffer.toString();
  }

  List<ToolCall> _parseToolCalls(Map<String, dynamic> candidate) {
    final content = candidate['content'] as Map<String, dynamic>?;
    if (content == null) return [];

    final parts = content['parts'] as List<dynamic>?;
    if (parts == null) return [];

    final toolCalls = <ToolCall>[];
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part is Map<String, dynamic>) {
        final functionCall = part['functionCall'] as Map<String, dynamic>?;
        if (functionCall != null) {
          toolCalls.add(ToolCall(
            id: 'call_$i',
            type: 'function',
            function: ToolFunction(
              name: functionCall['name'] as String,
              arguments: json.encode(functionCall['args']),
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
        final status = error['status'] as String?;

        if (status == 'UNAUTHENTICATED' ||
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
      'Gemini API error: ${response.statusCode}',
      providerName: name,
      statusCode: response.statusCode,
      details: response.body,
    );
  }
}
