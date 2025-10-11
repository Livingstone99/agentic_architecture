/// Base exception for all agentic architecture errors.
class AgenticException implements Exception {
  /// The error message.
  final String message;

  /// Optional error details.
  final dynamic details;

  /// Optional stack trace.
  final StackTrace? stackTrace;

  const AgenticException(
    this.message, {
    this.details,
    this.stackTrace,
  });

  @override
  String toString() {
    if (details != null) {
      return 'AgenticException: $message\nDetails: $details';
    }
    return 'AgenticException: $message';
  }
}

/// Exception thrown when an agent operation fails.
class AgentException extends AgenticException {
  /// The ID of the agent that failed.
  final String? agentId;

  const AgentException(
    super.message, {
    this.agentId,
    super.details,
    super.stackTrace,
  });

  @override
  String toString() {
    final agentStr = agentId != null ? ' (Agent: $agentId)' : '';
    return 'AgentException$agentStr: $message';
  }
}

/// Exception thrown when a tool operation fails.
class ToolException extends AgenticException {
  /// The name of the tool that failed.
  final String? toolName;

  const ToolException(
    super.message, {
    this.toolName,
    super.details,
    super.stackTrace,
  });

  @override
  String toString() {
    final toolStr = toolName != null ? ' (Tool: $toolName)' : '';
    return 'ToolException$toolStr: $message';
  }
}

/// Exception thrown when an LLM provider operation fails.
class LLMProviderException extends AgenticException {
  /// The name of the provider that failed.
  final String? providerName;

  /// HTTP status code if applicable.
  final int? statusCode;

  const LLMProviderException(
    super.message, {
    this.providerName,
    this.statusCode,
    super.details,
    super.stackTrace,
  });

  @override
  String toString() {
    final providerStr =
        providerName != null ? ' (Provider: $providerName)' : '';
    final statusStr = statusCode != null ? ' [HTTP $statusCode]' : '';
    return 'LLMProviderException$providerStr$statusStr: $message';
  }
}

/// Exception thrown when agent coordination fails.
class CoordinationException extends AgenticException {
  const CoordinationException(
    super.message, {
    super.details,
    super.stackTrace,
  });

  @override
  String toString() {
    return 'CoordinationException: $message';
  }
}

/// Exception thrown when expert routing fails in MOE mode.
class RoutingException extends AgenticException {
  const RoutingException(
    super.message, {
    super.details,
    super.stackTrace,
  });

  @override
  String toString() {
    return 'RoutingException: $message';
  }
}

/// Exception thrown when response synthesis fails.
class SynthesisException extends AgenticException {
  const SynthesisException(
    super.message, {
    super.details,
    super.stackTrace,
  });

  @override
  String toString() {
    return 'SynthesisException: $message';
  }
}

/// Exception thrown when configuration is invalid.
class ConfigurationException extends AgenticException {
  const ConfigurationException(
    super.message, {
    super.details,
    super.stackTrace,
  });

  @override
  String toString() {
    return 'ConfigurationException: $message';
  }
}

/// Exception thrown when a required parameter is missing.
class MissingParameterException extends AgenticException {
  /// The name of the missing parameter.
  final String parameterName;

  const MissingParameterException(
    this.parameterName, {
    super.details,
    super.stackTrace,
  }) : super('Missing required parameter: $parameterName');

  @override
  String toString() {
    return 'MissingParameterException: Missing required parameter: $parameterName';
  }
}

/// Exception thrown when a parameter has an invalid value.
class InvalidParameterException extends AgenticException {
  /// The name of the invalid parameter.
  final String parameterName;

  /// The invalid value.
  final dynamic value;

  InvalidParameterException(
    this.parameterName,
    this.value, {
    String? reason,
    super.stackTrace,
  }) : super(
          'Invalid parameter: $parameterName = $value' +
              (reason != null ? ' ($reason)' : ''),
        );

  @override
  String toString() {
    return 'InvalidParameterException: Invalid parameter: $parameterName = $value';
  }
}

/// Exception thrown when an operation times out.
class TimeoutException extends AgenticException {
  /// The operation that timed out.
  final String operation;

  /// The timeout duration.
  final Duration timeout;

  TimeoutException(
    this.operation,
    this.timeout, {
    super.stackTrace,
  }) : super('Operation timed out: $operation (timeout: $timeout)');

  @override
  String toString() {
    return 'TimeoutException: Operation timed out: $operation (timeout: $timeout)';
  }
}

/// Exception thrown when rate limiting is encountered.
class RateLimitException extends LLMProviderException {
  /// When the rate limit resets.
  final DateTime? resetAt;

  const RateLimitException(
    super.message, {
    super.providerName,
    this.resetAt,
    super.statusCode,
    super.details,
    super.stackTrace,
  });

  @override
  String toString() {
    final providerStr =
        providerName != null ? ' (Provider: $providerName)' : '';
    final resetStr = resetAt != null ? ' (Resets at: $resetAt)' : '';
    return 'RateLimitException$providerStr$resetStr: $message';
  }
}

/// Exception thrown when authentication fails.
class AuthenticationException extends LLMProviderException {
  const AuthenticationException(
    super.message, {
    super.providerName,
    super.statusCode,
    super.details,
    super.stackTrace,
  });

  @override
  String toString() {
    final providerStr =
        providerName != null ? ' (Provider: $providerName)' : '';
    return 'AuthenticationException$providerStr: $message';
  }
}
