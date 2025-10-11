import '../core/agent.dart';
import '../core/message.dart';
import '../core/result.dart';

/// A specialized expert agent that handles queries in a specific domain.
///
/// Expert agents are sub-agents that focus on particular types of queries
/// or domains (e.g., weather, code, mathematics). They are used in MOE mode
/// where a lead agent coordinates multiple experts.
class ExpertAgent extends Agent {
  /// The domain this expert specializes in.
  ///
  /// Examples: 'weather', 'navigation', 'code', 'mathematics'
  final String domain;

  /// Keywords that indicate this expert should handle a query.
  ///
  /// Used for keyword-based routing when LLM routing is not available.
  final List<String> keywords;

  /// The confidence level of this expert (0.0 to 1.0).
  ///
  /// Higher confidence means this expert is more reliable in its domain.
  final double confidence;

  ExpertAgent({
    required super.id,
    required super.name,
    required super.description,
    required super.llmProvider,
    required this.domain,
    required this.keywords,
    super.tools = const [],
    super.config,
    this.confidence = 0.8,
  });

  @override
  bool canHandle(AgentRequest request) {
    // Check if query contains any of this expert's keywords
    final query = request.query.toLowerCase();
    return keywords.any((keyword) => query.contains(keyword.toLowerCase()));
  }

  @override
  Future<AgentResponse> process(AgentRequest request) async {
    // Build specialized system prompt for this expert
    final expertPrompt = config.systemPrompt ??
        '''You are a specialized ${domain} expert. Your role is to provide accurate, 
detailed information about $description.

Available tools: ${tools.map((t) => t.name).join(', ')}

Focus on providing specific, actionable answers within your domain of expertise.''';

    // Build conversation history
    final messages = <LLMMessage>[
      ...request.history,
      LLMMessage.user(request.query),
    ];

    // Initial LLM call with expert system prompt
    var response = await llmProvider.chat(
      message: request.query,
      history: request.history,
      tools: toolSchemas.isNotEmpty ? toolSchemas : null,
      temperature: request.temperature ?? config.temperature ?? 0.7,
      maxTokens: request.maxTokens ?? config.maxTokens,
      systemPrompt: expertPrompt,
    );

    var allToolResults = <ToolResult>[];
    var rounds = 0;

    // Tool execution loop
    while (response.toolCalls.isNotEmpty && rounds < config.maxToolRounds) {
      rounds++;

      if (config.enableLogging) {
        print(
            '🔧 [$name] Tool round $rounds: ${response.toolCalls.length} tools');
      }

      // Execute tools
      final toolResults = await executeTools(response.toolCalls);
      allToolResults.addAll(toolResults);

      // Add tool results to conversation
      messages.add(LLMMessage.assistant(
        response.content,
        toolCalls: response.toolCalls,
      ));

      for (var i = 0; i < toolResults.length; i++) {
        final result = toolResults[i];
        final toolCall = response.toolCalls[i];
        messages.add(LLMMessage.tool(
          content: result.success
              ? result.data.toString()
              : 'Error: ${result.error}',
          toolCallId: toolCall.id,
          name: toolCall.function.name,
        ));
      }

      // Get next response from LLM
      response = await llmProvider.chat(
        message: 'Continue based on tool results',
        history: messages,
        tools: toolSchemas.isNotEmpty ? toolSchemas : null,
        temperature: request.temperature ?? config.temperature ?? 0.7,
        maxTokens: request.maxTokens ?? config.maxTokens,
        systemPrompt: expertPrompt,
      );
    }

    // Calculate token usage with cost
    final tokenUsage = TokenUsage(
      inputTokens: response.inputTokens,
      outputTokens: response.outputTokens,
      cost: llmProvider.calculateCost(
        response.inputTokens,
        response.outputTokens,
      ),
    );

    return AgentResponse(
      agentId: id,
      content: response.content,
      toolCalls: response.toolCalls,
      toolResults: allToolResults,
      confidence: confidence,
      tokenUsage: tokenUsage,
      metadata: {
        'domain': domain,
        'rounds': rounds,
        'model': response.model,
        'provider': llmProvider.name,
      },
    );
  }

  /// Converts this expert's response to an [ExpertResponse].
  ExpertResponse toExpertResponse(AgentResponse response) {
    return ExpertResponse(
      expertId: id,
      expertName: name,
      domain: domain,
      content: response.content,
      confidence: confidence,
      toolResults: response.toolResults,
      metadata: response.metadata,
      tokenUsage: response.tokenUsage,
    );
  }

  /// Calculates a relevance score for this expert given a query.
  ///
  /// Returns a score between 0.0 and 1.0 based on keyword matching
  /// and expert confidence.
  double calculateRelevanceScore(String query) {
    final lowerQuery = query.toLowerCase();
    final matches = keywords
        .where(
          (keyword) => lowerQuery.contains(keyword.toLowerCase()),
        )
        .length;

    if (matches == 0) return 0.0;

    // Combine keyword matches with expert confidence
    final keywordScore = matches / keywords.length;
    return (keywordScore * 0.7) + (confidence * 0.3);
  }

  @override
  String toString() {
    return 'ExpertAgent($id: $name, domain: $domain, confidence: $confidence)';
  }
}
