/// Defines how a lead agent delegates work to expert agents.
enum DelegationStrategy {
  /// Delegate to the single best-matching expert.
  ///
  /// The lead agent analyzes the query and selects the one expert
  /// most likely to handle it well.
  single,

  /// Query all relevant experts in parallel.
  ///
  /// Multiple experts work on the query simultaneously, and their
  /// responses are synthesized into a final answer.
  parallel,

  /// Query experts one by one in sequence.
  ///
  /// Each expert's response informs the next expert's query.
  /// Useful for complex, multi-step tasks.
  sequential,

  /// Let the LLM decide how to delegate.
  ///
  /// The lead agent's LLM analyzes the query and determines
  /// the best delegation strategy dynamically.
  intelligent,
}

/// Extension methods for [DelegationStrategy].
extension DelegationStrategyExtension on DelegationStrategy {
  /// Returns a human-readable description of this strategy.
  String get description {
    switch (this) {
      case DelegationStrategy.single:
        return 'Delegate to the single best expert';
      case DelegationStrategy.parallel:
        return 'Query multiple experts in parallel';
      case DelegationStrategy.sequential:
        return 'Query experts sequentially';
      case DelegationStrategy.intelligent:
        return 'Let the LLM decide delegation strategy';
    }
  }

  /// Whether this strategy may use multiple experts.
  bool get usesMultipleExperts {
    switch (this) {
      case DelegationStrategy.single:
        return false;
      case DelegationStrategy.parallel:
      case DelegationStrategy.sequential:
      case DelegationStrategy.intelligent:
        return true;
    }
  }

  /// Whether this strategy requires LLM-based routing.
  bool get requiresLLM {
    return this == DelegationStrategy.intelligent;
  }
}
