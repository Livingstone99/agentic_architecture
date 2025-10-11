/// Represents a message in a conversation.
class LLMMessage {
  /// The role of the message sender.
  final MessageRole role;

  /// The content of the message.
  final String content;

  /// Optional tool calls made in this message.
  final List<ToolCall>? toolCalls;

  /// Optional tool results in this message.
  final String? toolCallId;

  /// Optional name (for function/tool messages).
  final String? name;

  const LLMMessage({
    required this.role,
    required this.content,
    this.toolCalls,
    this.toolCallId,
    this.name,
  });

  /// Creates a user message.
  factory LLMMessage.user(String content) {
    return LLMMessage(
      role: MessageRole.user,
      content: content,
    );
  }

  /// Creates an assistant message.
  factory LLMMessage.assistant(
    String content, {
    List<ToolCall>? toolCalls,
  }) {
    return LLMMessage(
      role: MessageRole.assistant,
      content: content,
      toolCalls: toolCalls,
    );
  }

  /// Creates a system message.
  factory LLMMessage.system(String content) {
    return LLMMessage(
      role: MessageRole.system,
      content: content,
    );
  }

  /// Creates a tool/function message.
  factory LLMMessage.tool({
    required String content,
    required String toolCallId,
    String? name,
  }) {
    return LLMMessage(
      role: MessageRole.tool,
      content: content,
      toolCallId: toolCallId,
      name: name,
    );
  }

  /// Converts this message to a JSON map.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'role': role.name,
      'content': content,
    };

    if (toolCalls != null && toolCalls!.isNotEmpty) {
      json['tool_calls'] = toolCalls!.map((t) => t.toJson()).toList();
    }

    if (toolCallId != null) {
      json['tool_call_id'] = toolCallId;
    }

    if (name != null) {
      json['name'] = name;
    }

    return json;
  }

  /// Creates a message from a JSON map.
  factory LLMMessage.fromJson(Map<String, dynamic> json) {
    return LLMMessage(
      role: MessageRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => MessageRole.user,
      ),
      content: json['content'] as String? ?? '',
      toolCalls: json['tool_calls'] != null
          ? (json['tool_calls'] as List)
              .map((t) => ToolCall.fromJson(t as Map<String, dynamic>))
              .toList()
          : null,
      toolCallId: json['tool_call_id'] as String?,
      name: json['name'] as String?,
    );
  }

  @override
  String toString() {
    return 'LLMMessage(role: ${role.name}, content: $content)';
  }
}

/// The role of a message sender.
enum MessageRole {
  /// System message (instructions, context).
  system,

  /// User message (human input).
  user,

  /// Assistant message (AI response).
  assistant,

  /// Tool/function message (tool execution result).
  tool,
}

/// Represents a tool call request from the LLM.
class ToolCall {
  /// Unique identifier for this tool call.
  final String id;

  /// The type of tool call (usually 'function').
  final String type;

  /// The function details.
  final ToolFunction function;

  const ToolCall({
    required this.id,
    required this.type,
    required this.function,
  });

  /// Converts this tool call to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'function': function.toJson(),
    };
  }

  /// Creates a tool call from a JSON map.
  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'function',
      function: ToolFunction.fromJson(json['function'] as Map<String, dynamic>),
    );
  }

  @override
  String toString() {
    return 'ToolCall(id: $id, function: ${function.name})';
  }
}

/// Represents a function call within a tool call.
class ToolFunction {
  /// The name of the function to call.
  final String name;

  /// The arguments as a JSON string.
  final String arguments;

  const ToolFunction({
    required this.name,
    required this.arguments,
  });

  /// Converts this function to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'arguments': arguments,
    };
  }

  /// Creates a function from a JSON map.
  factory ToolFunction.fromJson(Map<String, dynamic> json) {
    return ToolFunction(
      name: json['name'] as String,
      arguments: json['arguments'] as String,
    );
  }

  @override
  String toString() {
    return 'ToolFunction(name: $name, arguments: $arguments)';
  }
}

/// Represents a tool schema for LLM function calling.
class ToolSchema {
  /// The type of tool (usually 'function').
  final String type;

  /// The function definition.
  final FunctionDefinition function;

  const ToolSchema({
    required this.type,
    required this.function,
  });

  /// Creates a tool schema with default type.
  factory ToolSchema.function(FunctionDefinition function) {
    return ToolSchema(
      type: 'function',
      function: function,
    );
  }

  /// Converts this schema to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'function': function.toJson(),
    };
  }

  /// Creates a schema from a JSON map.
  factory ToolSchema.fromJson(Map<String, dynamic> json) {
    return ToolSchema(
      type: json['type'] as String? ?? 'function',
      function: FunctionDefinition.fromJson(
        json['function'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Represents a function definition for tool schemas.
class FunctionDefinition {
  /// The name of the function.
  final String name;

  /// Description of what the function does.
  final String description;

  /// JSON Schema of the function parameters.
  final Map<String, dynamic> parameters;

  const FunctionDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  /// Converts this definition to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'parameters': parameters,
    };
  }

  /// Creates a definition from a JSON map.
  factory FunctionDefinition.fromJson(Map<String, dynamic> json) {
    return FunctionDefinition(
      name: json['name'] as String,
      description: json['description'] as String,
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
    );
  }
}
