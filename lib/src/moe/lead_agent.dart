import '../core/agent.dart';
import '../core/exceptions.dart';
import '../core/message.dart';
import '../core/result.dart';
import 'delegation_strategy.dart';
import 'expert_agent.dart';
import 'expert_router.dart';
import 'response_synthesizer.dart';

/// A lead agent that orchestrates multiple expert agents in MOE mode.
///
/// The lead agent:
/// 1. Analyzes incoming queries
/// 2. Routes them to appropriate expert(s)
/// 3. Manages expert execution (parallel, sequential, etc.)
/// 4. Synthesizes expert responses into a final answer
class LeadAgent extends Agent {
  /// The expert agents this lead can delegate to.
  final List<ExpertAgent> experts;

  /// The router for selecting experts.
  final ExpertRouter router;

  /// The synthesizer for combining expert responses.
  final ResponseSynthesizer synthesizer;

  /// The delegation strategy to use.
  final DelegationStrategy strategy;

  /// Maximum number of experts to use in parallel/sequential modes.
  final int maxExperts;

  LeadAgent({
    required super.id,
    required super.name,
    required super.llmProvider,
    required this.experts,
    super.description = '',
    super.tools = const [],
    super.config,
    ExpertRouter? router,
    ResponseSynthesizer? synthesizer,
    this.strategy = DelegationStrategy.intelligent,
    this.maxExperts = 3,
  })  : router = router ??
            ExpertRouter(enableLogging: config?.enableLogging ?? false),
        synthesizer = synthesizer ??
            ResponseSynthesizer(enableLogging: config?.enableLogging ?? false) {
    if (experts.isEmpty) {
      throw ConfigurationException(
        'LeadAgent requires at least one expert agent',
      );
    }
  }

  @override
  bool canHandle(AgentRequest request) {
    // Lead agent can handle if any expert can handle the request
    return experts.any((expert) => expert.canHandle(request));
  }

  @override
  Future<AgentResponse> process(AgentRequest request) async {
    try {
      if (config.enableLogging) {
        print('🎯 Lead agent processing query with ${strategy.name} strategy');
        print('📋 Available experts: ${experts.map((e) => e.name).join(", ")}');
      }

      // Step 1: Analyze query and select expert(s)
      final selectedExperts = await router.selectExperts(
        query: request.query,
        experts: experts,
        strategy: strategy,
        maxExperts: maxExperts,
        leadLLM: llmProvider,
      );

      if (selectedExperts.isEmpty) {
        throw RoutingException(
          'No suitable experts found for query',
          details: request.query,
        );
      }

      // Step 2: Execute based on delegation strategy
      List<ExpertResponse> expertResponses;

      switch (strategy) {
        case DelegationStrategy.single:
          expertResponses = await _executeSingle(selectedExperts, request);
          break;

        case DelegationStrategy.parallel:
          expertResponses = await _executeParallel(selectedExperts, request);
          break;

        case DelegationStrategy.sequential:
          expertResponses = await _executeSequential(selectedExperts, request);
          break;

        case DelegationStrategy.intelligent:
          // For intelligent mode, the router has already selected the best approach
          // Use parallel execution as default
          expertResponses = await _executeParallel(selectedExperts, request);
          break;
      }

      // Step 3: Synthesize responses
      final synthesizedResponse = await synthesizer.synthesize(
        originalQuery: request.query,
        expertResponses: expertResponses,
        leadAgentId: id,
        leadLLM: llmProvider,
      );

      return synthesizedResponse;
    } catch (e, stackTrace) {
      if (e is AgenticException) rethrow;

      throw AgentException(
        'Lead agent failed to process request: $e',
        agentId: id,
        details: request.query,
        stackTrace: stackTrace,
      );
    }
  }

  /// Executes with a single expert.
  Future<List<ExpertResponse>> _executeSingle(
    List<ExpertAgent> experts,
    AgentRequest request,
  ) async {
    final expert = experts.first;

    if (config.enableLogging) {
      print('👤 Executing single expert: ${expert.name}');
    }

    final response = await expert.process(request);
    return [expert.toExpertResponse(response)];
  }

  /// Executes multiple experts in parallel.
  Future<List<ExpertResponse>> _executeParallel(
    List<ExpertAgent> experts,
    AgentRequest request,
  ) async {
    if (config.enableLogging) {
      print('⚡ Executing ${experts.length} experts in parallel');
    }

    final responses = await Future.wait(
      experts.map((expert) async {
        try {
          final response = await expert.process(request);
          return expert.toExpertResponse(response);
        } catch (e) {
          if (config.enableLogging) {
            print('⚠️ Expert ${expert.name} failed: $e');
          }
          // Return a failed response instead of throwing
          return ExpertResponse(
            expertId: expert.id,
            expertName: expert.name,
            domain: expert.domain,
            content: 'Expert encountered an error: $e',
            confidence: 0.0,
            metadata: {'error': e.toString()},
          );
        }
      }),
    );

    // Filter out failed responses
    return responses.where((r) => r.confidence > 0.0).toList();
  }

  /// Executes experts sequentially.
  Future<List<ExpertResponse>> _executeSequential(
    List<ExpertAgent> experts,
    AgentRequest request,
  ) async {
    if (config.enableLogging) {
      print('🔄 Executing ${experts.length} experts sequentially');
    }

    final responses = <ExpertResponse>[];
    final contextHistory = <LLMMessage>[...request.history];

    for (final expert in experts) {
      try {
        if (config.enableLogging) {
          print('  → Querying ${expert.name}');
        }

        // Each expert gets context from previous experts
        final expertRequest = AgentRequest(
          query: request.query,
          history: contextHistory,
          context: request.context,
          maxTokens: request.maxTokens,
          temperature: request.temperature,
        );

        final response = await expert.process(expertRequest);
        final expertResponse = expert.toExpertResponse(response);
        responses.add(expertResponse);

        // Add this expert's response to context for next expert
        contextHistory.add(LLMMessage.assistant(response.content));
      } catch (e) {
        if (config.enableLogging) {
          print('⚠️ Expert ${expert.name} failed: $e');
        }
        // Continue with other experts
      }
    }

    return responses;
  }

  /// Adds a new expert to this lead agent.
  void addExpert(ExpertAgent expert) {
    if (!experts.contains(expert)) {
      experts.add(expert);
    }
  }

  /// Removes an expert from this lead agent.
  void removeExpert(String expertId) {
    experts.removeWhere((e) => e.id == expertId);
  }

  /// Gets an expert by ID.
  ExpertAgent? getExpert(String expertId) {
    try {
      return experts.firstWhere((e) => e.id == expertId);
    } catch (_) {
      return null;
    }
  }

  /// Gets experts for a specific domain.
  List<ExpertAgent> getExpertsByDomain(String domain) {
    return experts.where((e) => e.domain == domain).toList();
  }

  @override
  String toString() {
    return 'LeadAgent($id: $name, ${experts.length} experts, strategy: ${strategy.name})';
  }
}
