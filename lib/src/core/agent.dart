import 'exceptions.dart';
import 'llm_provider.dart';
import 'logger.dart';
import 'message.dart';
import 'result.dart';
import 'tool.dart';

/// Abstract base class for all agents.
///
/// An agent is an autonomous entity that can process queries using an LLM
/// and optionally execute tools to accomplish tasks.
abstract class Agent {
  /// Unique identifier for this agent.
  final String id;

  /// Human-readable name of this agent.
  final String name;

  /// Description of this agent's capabilities and purpose.
  final String description;

  /// The LLM provider this agent uses.
  final LLMProvider llmProvider;

  /// Tools available to this agent.
  final List<Tool> tools;

  /// Optional configuration for the agent.
  final AgentConfig config;

  Agent({
    required this.id,
    required this.name,
    required this.description,
    required this.llmProvider,
    this.tools = const [],
    AgentConfig? config,
  }) : config = config ?? const AgentConfig();

  /// Processes a request and returns a response.
  ///
  /// This is the main method that agents implement to handle queries.
  Future<AgentResponse> process(AgentRequest request);

  /// Determines if this agent can handle the given request.
  ///
  /// This is used by coordinators and routers to decide which agent(s)
  /// to use for a given query.
  bool canHandle(AgentRequest request);

  /// Gets the tool schemas for this agent's tools.
  List<ToolSchema> get toolSchemas {
    return tools.map((t) => t.toSchema()).toList();
  }

  /// Executes tool calls returned by the LLM.
  Future<List<ToolResult>> executeTools(List<ToolCall> toolCalls) async {
    if (toolCalls.isEmpty) return [];

    final results = <ToolResult>[];
    for (final toolCall in toolCalls) {
      try {
        final tool = tools.firstWhere(
          (t) => t.name == toolCall.function.name,
          orElse: () => throw ToolException(
            'Tool not found: ${toolCall.function.name}',
            toolName: toolCall.function.name,
          ),
        );

        final result = await tool.executeFromCall(toolCall);
        results.add(result);
      } catch (e, stackTrace) {
        results.add(ToolResult.failure(
          toolName: toolCall.function.name,
          error: e.toString(),
          metadata: {'stackTrace': stackTrace.toString()},
          toolCallId: toolCall.id,
        ));
      }
    }

    return results;
  }

  @override
  String toString() => 'Agent($id: $name)';
}

/// Configuration for an agent.
class AgentConfig {
  /// Maximum number of tool execution rounds.
  ///
  /// This prevents infinite loops when the LLM keeps calling tools.
  final int maxToolRounds;

  /// Default temperature for LLM requests.
  final double? temperature;

  /// Default maximum tokens for responses.
  final int? maxTokens;

  /// System prompt to guide the agent's behavior.
  final String? systemPrompt;

  /// Whether to enable verbose logging.
  final bool enableLogging;

  /// Additional configuration options.
  final Map<String, dynamic> extra;

  const AgentConfig({
    this.maxToolRounds = 5,
    this.temperature,
    this.maxTokens,
    this.systemPrompt,
    this.enableLogging = false,
    this.extra = const {},
  });

  /// Creates a copy of this config with updated fields.
  AgentConfig copyWith({
    int? maxToolRounds,
    double? temperature,
    int? maxTokens,
    String? systemPrompt,
    bool? enableLogging,
    Map<String, dynamic>? extra,
  }) {
    return AgentConfig(
      maxToolRounds: maxToolRounds ?? this.maxToolRounds,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      enableLogging: enableLogging ?? this.enableLogging,
      extra: extra ?? this.extra,
    );
  }
}

/// A simple agent that uses a single LLM with tools.
class SimpleAgent extends Agent {
  SimpleAgent({
    required super.id,
    required super.name,
    required super.llmProvider,
    super.description = '',
    super.tools,
    super.config,
  });

  @override
  bool canHandle(AgentRequest request) {
    // Simple agents can handle any request
    return true;
  }

  @override
  Future<AgentResponse> process(AgentRequest request) async {
    try {
      // Build conversation history
      final messages = <LLMMessage>[
        ...request.history,
        LLMMessage.user(request.query),
      ];

      // Initial LLM call
      var response = await llmProvider.chat(
        message: request.query,
        history: request.history,
        tools: toolSchemas.isNotEmpty ? toolSchemas : null,
        temperature: request.temperature ?? config.temperature ?? 0.7,
        maxTokens: request.maxTokens ?? config.maxTokens,
        systemPrompt: config.systemPrompt,
      );

      var allToolResults = <ToolResult>[];
      var rounds = 0;

      // Tool execution loop
      while (response.toolCalls.isNotEmpty && rounds < config.maxToolRounds) {
        rounds++;

        final logger =
            AgenticLogger(name: 'SimpleAgent', enabled: config.enableLogging);
        logger
            .debug('🔧 Tool round $rounds: ${response.toolCalls.length} tools');

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
          systemPrompt: config.systemPrompt,
        );
      }

      // Calculate total token usage
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
        tokenUsage: tokenUsage,
        metadata: {
          'rounds': rounds,
          'model': response.model,
        },
      );
    } catch (e, stackTrace) {
      throw AgentException(
        'Failed to process request: $e',
        agentId: id,
        details: request.query,
        stackTrace: stackTrace,
      );
    }
  }
}
