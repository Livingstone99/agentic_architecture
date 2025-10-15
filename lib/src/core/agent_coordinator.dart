import 'agent.dart';
import 'exceptions.dart';
import 'logger.dart';
import 'message.dart';
import 'result.dart';

/// The mode of agent operation.
enum AgentMode {
  /// Simple mode: Single lead agent with tools.
  simple,

  /// MOE mode: Lead agent with multiple expert sub-agents.
  moe,
}

/// Coordinates agent operations and manages the query processing flow.
///
/// The coordinator is the main entry point for processing queries. It manages
/// the lead agent and determines how queries are handled based on the mode.
class AgentCoordinator {
  /// The lead agent that orchestrates query processing.
  final Agent leadAgent;

  /// The operation mode (simple or MOE).
  final AgentMode mode;

  /// Whether to enable verbose logging.
  final bool enableLogging;

  /// Configuration options.
  final CoordinatorConfig config;

  AgentCoordinator({
    required this.leadAgent,
    this.mode = AgentMode.simple,
    this.enableLogging = false,
    CoordinatorConfig? config,
  }) : config = config ?? const CoordinatorConfig();

  /// Processes a query and returns the results.
  ///
  /// This is the main method for query processing. It handles the query
  /// according to the configured mode and returns a list of results.
  Future<List<AgentResult>> processQuery(
    String query, {
    List<LLMMessage>? history,
    Map<String, dynamic>? context,
  }) async {
    final logger =
        AgenticLogger(name: 'AgentCoordinator', enabled: enableLogging);

    try {
      logger.info('🤖 Processing query in ${mode.name} mode: $query');

      final request = AgentRequest(
        query: query,
        history: history ?? [],
        context: context ?? {},
      );

      // Validate that lead agent can handle the request
      if (!leadAgent.canHandle(request)) {
        throw CoordinationException(
          'Lead agent cannot handle the request',
          details: query,
        );
      }

      final startTime = DateTime.now();

      // Process with lead agent
      final response = await leadAgent.process(request);

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      logger.info('✅ Query processed in ${duration.inMilliseconds}ms');
      if (response.tokenUsage != null) {
        logger.debug('📊 Token usage: ${response.tokenUsage}');
      }

      // Convert response to result
      final result = AgentResult(
        agentId: leadAgent.id,
        agentName: leadAgent.name,
        content: response.content,
        synthesized: response.synthesized,
        confidence: response.confidence,
        toolResults: response.toolResults,
        expertResponses: response.expertResponses,
        metadata: {
          ...response.metadata,
          'mode': mode.name,
          'duration_ms': duration.inMilliseconds,
        },
        tokenUsage: response.tokenUsage,
      );

      return [result];
    } catch (e, stackTrace) {
      logger.error('❌ Error processing query: $e');

      throw CoordinationException(
        'Failed to process query: $e',
        details: query,
        stackTrace: stackTrace,
      );
    }
  }

  /// Processes multiple queries in parallel.
  Future<List<List<AgentResult>>> processQueriesParallel(
    List<String> queries, {
    List<LLMMessage>? history,
    Map<String, dynamic>? context,
  }) async {
    return await Future.wait(
      queries.map((query) => processQuery(
            query,
            history: history,
            context: context,
          )),
    );
  }

  /// Processes multiple queries sequentially.
  Future<List<List<AgentResult>>> processQueriesSequential(
    List<String> queries, {
    List<LLMMessage>? history,
    Map<String, dynamic>? context,
  }) async {
    final results = <List<AgentResult>>[];
    for (final query in queries) {
      final result = await processQuery(
        query,
        history: history,
        context: context,
      );
      results.add(result);
    }
    return results;
  }

  /// Processes a query with streaming response.
  ///
  /// This is useful for real-time UI updates. Not all agents support streaming.
  Stream<AgentResult> processQueryStream(
    String query, {
    List<LLMMessage>? history,
    Map<String, dynamic>? context,
  }) async* {
    final logger =
        AgenticLogger(name: 'AgentCoordinator', enabled: enableLogging);

    try {
      logger
          .info('🤖 Processing query (streaming) in ${mode.name} mode: $query');

      // For now, just process normally and yield the result
      // TODO: Implement true streaming when agents support it
      final results = await processQuery(
        query,
        history: history,
        context: context,
      );

      for (final result in results) {
        yield result;
      }
    } catch (e, stackTrace) {
      logger.error('❌ Error processing streaming query: $e');

      throw CoordinationException(
        'Failed to process streaming query: $e',
        details: query,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  String toString() {
    return 'AgentCoordinator(mode: ${mode.name}, leadAgent: ${leadAgent.name})';
  }
}

/// Configuration for the agent coordinator.
class CoordinatorConfig {
  /// Timeout for query processing.
  final Duration? timeout;

  /// Maximum number of retries on failure.
  final int maxRetries;

  /// Whether to collect detailed metrics.
  final bool collectMetrics;

  /// Additional configuration options.
  final Map<String, dynamic> extra;

  const CoordinatorConfig({
    this.timeout,
    this.maxRetries = 0,
    this.collectMetrics = false,
    this.extra = const {},
  });

  /// Creates a copy of this config with updated fields.
  CoordinatorConfig copyWith({
    Duration? timeout,
    int? maxRetries,
    bool? collectMetrics,
    Map<String, dynamic>? extra,
  }) {
    return CoordinatorConfig(
      timeout: timeout ?? this.timeout,
      maxRetries: maxRetries ?? this.maxRetries,
      collectMetrics: collectMetrics ?? this.collectMetrics,
      extra: extra ?? this.extra,
    );
  }
}
