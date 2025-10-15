import '../core/llm_provider.dart';
import '../core/logger.dart';
import '../core/result.dart';

/// Synthesizes responses from multiple expert agents into a single coherent answer.
///
/// When multiple experts are consulted, their responses need to be combined
/// into a unified answer. The synthesizer can do this with or without an LLM.
class ResponseSynthesizer {
  /// Whether to enable verbose logging.
  final bool enableLogging;

  ResponseSynthesizer({
    this.enableLogging = false,
  });

  /// Synthesizes multiple expert responses into a single agent response.
  ///
  /// If only one expert response is provided, returns it directly.
  /// If multiple responses are provided:
  /// - With [leadLLM]: Uses LLM to synthesize a coherent response
  /// - Without [leadLLM]: Concatenates responses with expert labels
  Future<AgentResponse> synthesize({
    required String originalQuery,
    required List<ExpertResponse> expertResponses,
    String leadAgentId = 'lead',
    LLMProvider? leadLLM,
  }) async {
    if (expertResponses.isEmpty) {
      return AgentResponse(
        agentId: leadAgentId,
        content: 'No expert responses available.',
        confidence: 0.0,
      );
    }

    // Single expert - return directly
    if (expertResponses.length == 1) {
      final expert = expertResponses.first;
      return AgentResponse(
        agentId: leadAgentId,
        content: expert.content,
        toolResults: expert.toolResults,
        confidence: expert.confidence,
        expertResponses: expertResponses,
        synthesized: false,
        tokenUsage: expert.tokenUsage,
        metadata: {'single_expert': expert.expertName},
      );
    }

    // Multiple experts - synthesize
    final logger = AgenticLogger(name: 'ResponseSynthesizer', enabled: enableLogging);
    logger.info('🔄 Synthesizing ${expertResponses.length} expert responses');

    if (leadLLM != null) {
      return await _synthesizeWithLLM(
        originalQuery: originalQuery,
        expertResponses: expertResponses,
        leadAgentId: leadAgentId,
        leadLLM: leadLLM,
      );
    } else {
      return _synthesizeSimple(
        originalQuery: originalQuery,
        expertResponses: expertResponses,
        leadAgentId: leadAgentId,
      );
    }
  }

  /// Synthesizes responses using an LLM.
  Future<AgentResponse> _synthesizeWithLLM({
    required String originalQuery,
    required List<ExpertResponse> expertResponses,
    required String leadAgentId,
    required LLMProvider leadLLM,
  }) async {
    // Build synthesis prompt
    final expertSummaries = expertResponses.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final expert = entry.value;
      return '''
Expert $index: ${expert.expertName} (${expert.domain})
Confidence: ${(expert.confidence * 100).toStringAsFixed(0)}%
Response: ${expert.content}
${expert.toolResults.isNotEmpty ? 'Tools used: ${expert.toolResults.map((t) => t.toolName).join(", ")}' : ''}
''';
    }).join('\n---\n');

    final synthesisPrompt =
        '''You are synthesizing responses from multiple expert agents into a single, coherent answer.

Original Query: "$originalQuery"

Expert Responses:
$expertSummaries

---

Your task: Create a unified, comprehensive response that:
1. Combines insights from all experts
2. Resolves any conflicts or contradictions (favor higher confidence experts)
3. Maintains a natural, conversational tone
4. Provides a complete answer to the original query
5. Credits experts when appropriate

Synthesized Response:''';

    try {
      final response = await leadLLM.chat(
        message: synthesisPrompt,
        temperature: 0.7,
      );

      // Combine token usage from experts and synthesis
      final expertTokenUsage = expertResponses
          .where((e) => e.tokenUsage != null)
          .map((e) => e.tokenUsage!)
          .toList();

      final synthesisTokenUsage = TokenUsage(
        inputTokens: response.inputTokens,
        outputTokens: response.outputTokens,
        cost: leadLLM.calculateCost(
          response.inputTokens,
          response.outputTokens,
        ),
      );

      final totalTokenUsage = TokenUsage.combine([
        ...expertTokenUsage,
        synthesisTokenUsage,
      ]);

      // Combine all tool results
      final allToolResults =
          expertResponses.expand((e) => e.toolResults).toList();

      // Calculate average confidence
      final avgConfidence = expertResponses.fold<double>(
            0.0,
            (sum, e) => sum + e.confidence,
          ) /
          expertResponses.length;

      return AgentResponse(
        agentId: leadAgentId,
        content: response.content,
        toolResults: allToolResults,
        confidence: avgConfidence,
        expertResponses: expertResponses,
        synthesized: true,
        tokenUsage: totalTokenUsage,
        metadata: {
          'num_experts': expertResponses.length,
          'synthesis_model': response.model,
          'expert_domains': expertResponses.map((e) => e.domain).toList(),
        },
      );
    } catch (e) {
      final logger = AgenticLogger(name: 'ResponseSynthesizer', enabled: enableLogging);
      logger.warning('⚠️ LLM synthesis failed: $e, falling back to simple synthesis');
      return _synthesizeSimple(
        originalQuery: originalQuery,
        expertResponses: expertResponses,
        leadAgentId: leadAgentId,
      );
    }
  }

  /// Synthesizes responses by concatenating them with labels.
  AgentResponse _synthesizeSimple({
    required String originalQuery,
    required List<ExpertResponse> expertResponses,
    required String leadAgentId,
  }) {
    final buffer = StringBuffer();

    if (expertResponses.length > 1) {
      buffer.writeln(
          'I consulted ${expertResponses.length} experts to answer your query:\n');
    }

    for (var i = 0; i < expertResponses.length; i++) {
      final expert = expertResponses[i];

      if (expertResponses.length > 1) {
        buffer.writeln('**${expert.expertName}** (${expert.domain}):');
      }

      buffer.writeln(expert.content);

      if (i < expertResponses.length - 1) {
        buffer.writeln();
      }
    }

    // Combine token usage
    final expertTokenUsage = expertResponses
        .where((e) => e.tokenUsage != null)
        .map((e) => e.tokenUsage!)
        .toList();

    final totalTokenUsage = expertTokenUsage.isNotEmpty
        ? TokenUsage.combine(expertTokenUsage)
        : null;

    // Combine all tool results
    final allToolResults =
        expertResponses.expand((e) => e.toolResults).toList();

    // Calculate average confidence
    final avgConfidence = expertResponses.fold<double>(
          0.0,
          (sum, e) => sum + e.confidence,
        ) /
        expertResponses.length;

    return AgentResponse(
      agentId: leadAgentId,
      content: buffer.toString(),
      toolResults: allToolResults,
      confidence: avgConfidence,
      expertResponses: expertResponses,
      synthesized: true,
      tokenUsage: totalTokenUsage,
      metadata: {
        'num_experts': expertResponses.length,
        'synthesis_method': 'simple_concat',
        'expert_domains': expertResponses.map((e) => e.domain).toList(),
      },
    );
  }
}
