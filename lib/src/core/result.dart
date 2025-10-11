import 'message.dart';

/// Represents the result of an agent processing a request.
class AgentResult {
  /// The ID of the agent that produced this result.
  final String agentId;

  /// The name of the agent.
  final String agentName;

  /// The main content/response.
  final String content;

  /// Whether this result was synthesized from multiple experts.
  final bool synthesized;

  /// The confidence level (0.0 to 1.0).
  final double confidence;

  /// Tool execution results, if any.
  final List<ToolResult> toolResults;

  /// Expert responses (for MOE mode).
  final List<ExpertResponse>? expertResponses;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  /// Token usage information.
  final TokenUsage? tokenUsage;

  /// Timestamp when this result was created.
  final DateTime timestamp;

  AgentResult({
    required this.agentId,
    required this.agentName,
    required this.content,
    this.synthesized = false,
    this.confidence = 1.0,
    this.toolResults = const [],
    this.expertResponses,
    this.metadata = const {},
    this.tokenUsage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'AgentResult(agentId: $agentId, content: $content, confidence: $confidence)';
  }

  /// Converts this result to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'agentName': agentName,
      'content': content,
      'synthesized': synthesized,
      'confidence': confidence,
      'toolResults': toolResults.map((t) => t.toJson()).toList(),
      'expertResponses': expertResponses?.map((e) => e.toJson()).toList(),
      'metadata': metadata,
      'tokenUsage': tokenUsage?.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Represents the response from an agent.
class AgentResponse {
  /// The ID of the agent that produced this response.
  final String agentId;

  /// The main content/response.
  final String content;

  /// Tool calls requested by the LLM.
  final List<ToolCall> toolCalls;

  /// Tool execution results.
  final List<ToolResult> toolResults;

  /// The confidence level (0.0 to 1.0).
  final double confidence;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  /// Expert responses (for lead agents in MOE mode).
  final List<ExpertResponse>? expertResponses;

  /// Whether this response was synthesized.
  final bool synthesized;

  /// Token usage for this response.
  final TokenUsage? tokenUsage;

  const AgentResponse({
    required this.agentId,
    required this.content,
    this.toolCalls = const [],
    this.toolResults = const [],
    this.confidence = 1.0,
    this.metadata = const {},
    this.expertResponses,
    this.synthesized = false,
    this.tokenUsage,
  });

  @override
  String toString() {
    return 'AgentResponse(agentId: $agentId, content: $content)';
  }

  /// Converts this response to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'content': content,
      'toolCalls': toolCalls.map((t) => t.toJson()).toList(),
      'toolResults': toolResults.map((t) => t.toJson()).toList(),
      'confidence': confidence,
      'metadata': metadata,
      'expertResponses': expertResponses?.map((e) => e.toJson()).toList(),
      'synthesized': synthesized,
      'tokenUsage': tokenUsage?.toJson(),
    };
  }
}

/// Represents an expert agent's response in MOE mode.
class ExpertResponse {
  /// The ID of the expert agent.
  final String expertId;

  /// The name of the expert agent.
  final String expertName;

  /// The expert's domain.
  final String domain;

  /// The expert's response content.
  final String content;

  /// The confidence level (0.0 to 1.0).
  final double confidence;

  /// Tool execution results from this expert.
  final List<ToolResult> toolResults;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  /// Token usage for this expert's response.
  final TokenUsage? tokenUsage;

  const ExpertResponse({
    required this.expertId,
    required this.expertName,
    required this.domain,
    required this.content,
    this.confidence = 1.0,
    this.toolResults = const [],
    this.metadata = const {},
    this.tokenUsage,
  });

  @override
  String toString() {
    return 'ExpertResponse(expertName: $expertName, domain: $domain, confidence: $confidence)';
  }

  /// Converts this response to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'expertId': expertId,
      'expertName': expertName,
      'domain': domain,
      'content': content,
      'confidence': confidence,
      'toolResults': toolResults.map((t) => t.toJson()).toList(),
      'metadata': metadata,
      'tokenUsage': tokenUsage?.toJson(),
    };
  }
}

/// Represents the result of executing a tool.
class ToolResult {
  /// The name of the tool that was executed.
  final String toolName;

  /// Whether the tool execution was successful.
  final bool success;

  /// The result data.
  final dynamic data;

  /// Error message if execution failed.
  final String? error;

  /// Additional metadata about the execution.
  final Map<String, dynamic> metadata;

  /// Timestamp when the tool was executed.
  final DateTime timestamp;

  /// The tool call ID this result corresponds to.
  final String? toolCallId;

  ToolResult({
    required this.toolName,
    required this.success,
    this.data,
    this.error,
    this.metadata = const {},
    DateTime? timestamp,
    this.toolCallId,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a successful tool result.
  factory ToolResult.success({
    required String toolName,
    required dynamic data,
    Map<String, dynamic> metadata = const {},
    String? toolCallId,
  }) {
    return ToolResult(
      toolName: toolName,
      success: true,
      data: data,
      metadata: metadata,
      toolCallId: toolCallId,
    );
  }

  /// Creates a failed tool result.
  factory ToolResult.failure({
    required String toolName,
    required String error,
    Map<String, dynamic> metadata = const {},
    String? toolCallId,
  }) {
    return ToolResult(
      toolName: toolName,
      success: false,
      error: error,
      metadata: metadata,
      toolCallId: toolCallId,
    );
  }

  @override
  String toString() {
    return 'ToolResult(toolName: $toolName, success: $success)';
  }

  /// Converts this result to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'toolName': toolName,
      'success': success,
      'data': data,
      'error': error,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'toolCallId': toolCallId,
    };
  }

  /// Creates a result from a JSON map.
  factory ToolResult.fromJson(Map<String, dynamic> json) {
    return ToolResult(
      toolName: json['toolName'] as String,
      success: json['success'] as bool,
      data: json['data'],
      error: json['error'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      timestamp: DateTime.parse(json['timestamp'] as String),
      toolCallId: json['toolCallId'] as String?,
    );
  }
}

/// Represents the response from an LLM provider.
class LLMResponse {
  /// The main content of the response.
  final String content;

  /// Tool calls requested by the LLM.
  final List<ToolCall> toolCalls;

  /// Input tokens used.
  final int inputTokens;

  /// Output tokens generated.
  final int outputTokens;

  /// The model used.
  final String? model;

  /// Additional metadata from the provider.
  final Map<String, dynamic> metadata;

  const LLMResponse({
    required this.content,
    this.toolCalls = const [],
    required this.inputTokens,
    required this.outputTokens,
    this.model,
    this.metadata = const {},
  });

  /// Total tokens used.
  int get totalTokens => inputTokens + outputTokens;

  @override
  String toString() {
    return 'LLMResponse(content: $content, tokens: $totalTokens)';
  }

  /// Converts this response to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'toolCalls': toolCalls.map((t) => t.toJson()).toList(),
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'model': model,
      'metadata': metadata,
    };
  }
}

/// Represents token usage information.
class TokenUsage {
  /// Input tokens used.
  final int inputTokens;

  /// Output tokens generated.
  final int outputTokens;

  /// Total tokens used.
  int get totalTokens => inputTokens + outputTokens;

  /// Cost in USD (if calculable).
  final double? cost;

  const TokenUsage({
    required this.inputTokens,
    required this.outputTokens,
    this.cost,
  });

  @override
  String toString() {
    final costStr = cost != null ? ', cost: \$$cost' : '';
    return 'TokenUsage(input: $inputTokens, output: $outputTokens$costStr)';
  }

  /// Converts this usage to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'totalTokens': totalTokens,
      'cost': cost,
    };
  }

  /// Creates usage from a JSON map.
  factory TokenUsage.fromJson(Map<String, dynamic> json) {
    return TokenUsage(
      inputTokens: json['inputTokens'] as int,
      outputTokens: json['outputTokens'] as int,
      cost: json['cost'] as double?,
    );
  }

  /// Combines multiple token usages.
  static TokenUsage combine(List<TokenUsage> usages) {
    if (usages.isEmpty) {
      return const TokenUsage(inputTokens: 0, outputTokens: 0);
    }

    final totalInput = usages.fold<int>(0, (sum, u) => sum + u.inputTokens);
    final totalOutput = usages.fold<int>(0, (sum, u) => sum + u.outputTokens);
    final totalCost = usages.every((u) => u.cost != null)
        ? usages.fold<double>(0, (sum, u) => sum + u.cost!)
        : null;

    return TokenUsage(
      inputTokens: totalInput,
      outputTokens: totalOutput,
      cost: totalCost,
    );
  }
}

/// Represents a request to an agent.
class AgentRequest {
  /// The query/message to process.
  final String query;

  /// Conversation history.
  final List<LLMMessage> history;

  /// Additional context.
  final Map<String, dynamic> context;

  /// Maximum tokens for the response.
  final int? maxTokens;

  /// Temperature for LLM generation.
  final double? temperature;

  const AgentRequest({
    required this.query,
    this.history = const [],
    this.context = const {},
    this.maxTokens,
    this.temperature,
  });

  @override
  String toString() {
    return 'AgentRequest(query: $query, historyLength: ${history.length})';
  }
}
