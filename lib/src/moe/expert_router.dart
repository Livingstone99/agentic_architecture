import '../core/exceptions.dart';
import '../core/llm_provider.dart';
import 'delegation_strategy.dart';
import 'expert_agent.dart';

/// Routes queries to the most appropriate expert agent(s).
///
/// The router analyzes queries and selects which expert(s) should handle them
/// based on the delegation strategy.
class ExpertRouter {
  /// Whether to enable verbose logging.
  final bool enableLogging;

  ExpertRouter({
    this.enableLogging = false,
  });

  /// Selects experts to handle a query based on the delegation strategy.
  Future<List<ExpertAgent>> selectExperts({
    required String query,
    required List<ExpertAgent> experts,
    required DelegationStrategy strategy,
    int maxExperts = 3,
    LLMProvider? leadLLM,
  }) async {
    if (experts.isEmpty) {
      throw RoutingException('No experts available for routing');
    }

    if (enableLogging) {
      print('🧭 Routing query with ${strategy.name} strategy');
    }

    List<ExpertAgent> selected;

    switch (strategy) {
      case DelegationStrategy.single:
        selected = [_findBestExpert(query, experts)];
        break;

      case DelegationStrategy.parallel:
        selected = _findTopExperts(query, experts, maxExperts);
        break;

      case DelegationStrategy.sequential:
        selected = _findSequentialExperts(query, experts, maxExperts);
        break;

      case DelegationStrategy.intelligent:
        if (leadLLM == null) {
          if (enableLogging) {
            print(
                '⚠️ No LLM provided for intelligent routing, falling back to parallel');
          }
          selected = _findTopExperts(query, experts, maxExperts);
        } else {
          selected =
              await _llmSelectExperts(query, experts, leadLLM, maxExperts);
        }
        break;
    }

    if (enableLogging) {
      print(
          '✅ Selected ${selected.length} expert(s): ${selected.map((e) => e.name).join(", ")}');
    }

    return selected;
  }

  /// Finds the single best expert for the query using keyword matching.
  ExpertAgent _findBestExpert(String query, List<ExpertAgent> experts) {
    return experts.reduce((best, current) {
      final bestScore = best.calculateRelevanceScore(query);
      final currentScore = current.calculateRelevanceScore(query);
      return currentScore > bestScore ? current : best;
    });
  }

  /// Finds the top N experts for parallel execution.
  List<ExpertAgent> _findTopExperts(
    String query,
    List<ExpertAgent> experts,
    int maxExperts,
  ) {
    // Score all experts
    final scoredExperts = experts.map((expert) {
      return _ScoredExpert(
        expert: expert,
        score: expert.calculateRelevanceScore(query),
      );
    }).toList();

    // Sort by score descending
    scoredExperts.sort((a, b) => b.score.compareTo(a.score));

    // Take top N with non-zero scores
    return scoredExperts
        .where((se) => se.score > 0.0)
        .take(maxExperts)
        .map((se) => se.expert)
        .toList();
  }

  /// Finds experts for sequential execution.
  ///
  /// Returns experts in order of relevance for sequential querying.
  List<ExpertAgent> _findSequentialExperts(
    String query,
    List<ExpertAgent> experts,
    int maxExperts,
  ) {
    // For now, use the same logic as parallel
    // In a more advanced implementation, this could consider dependencies
    // between experts or multi-step task planning
    return _findTopExperts(query, experts, maxExperts);
  }

  /// Uses LLM to intelligently select experts.
  Future<List<ExpertAgent>> _llmSelectExperts(
    String query,
    List<ExpertAgent> experts,
    LLMProvider llm,
    int maxExperts,
  ) async {
    try {
      // Build prompt for LLM
      final expertsDescription = experts
          .map((e) => '- ${e.name} (${e.domain}): ${e.description}')
          .join('\n');

      final prompt =
          '''Given the following query and available experts, select which expert(s) 
should handle this query. You can select 1-$maxExperts experts.

Query: "$query"

Available Experts:
$expertsDescription

Analyze the query and respond with ONLY the names of the expert(s) that should handle it, 
one per line. Consider:
1. Domain relevance
2. Required expertise
3. Whether multiple experts are needed

Response format (just the names):
Expert Name 1
Expert Name 2
...''';

      final response = await llm.chat(
        message: prompt,
        temperature: 0.3, // Lower temperature for more consistent routing
      );

      // Parse expert names from response
      final selectedNames = response.content
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      // Find matching experts
      final selected = <ExpertAgent>[];
      for (final name in selectedNames) {
        final matching = experts.where(
          (e) => e.name.toLowerCase() == name.toLowerCase(),
        );

        if (matching.isNotEmpty) {
          selected.add(matching.first);
        }
      }

      // Fallback to keyword-based if LLM selection failed
      if (selected.isEmpty) {
        if (enableLogging) {
          print('⚠️ LLM routing failed, falling back to keyword matching');
        }
        return _findTopExperts(query, experts, maxExperts);
      }

      return selected.take(maxExperts).toList();
    } catch (e) {
      if (enableLogging) {
        print('⚠️ LLM routing error: $e, falling back to keyword matching');
      }
      // Fallback to keyword-based routing
      return _findTopExperts(query, experts, maxExperts);
    }
  }
}

/// Internal class for scoring experts.
class _ScoredExpert {
  final ExpertAgent expert;
  final double score;

  _ScoredExpert({
    required this.expert,
    required this.score,
  });
}
