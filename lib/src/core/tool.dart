import 'dart:convert';

import 'exceptions.dart';
import 'message.dart';
import 'result.dart';

/// Base interface for all tools that agents can use.
///
/// Tools are functions that agents can call to interact with external systems,
/// perform computations, or retrieve information.
abstract class Tool {
  /// The unique name of this tool.
  ///
  /// This name is used by the LLM to identify and call the tool.
  String get name;

  /// A description of what this tool does.
  ///
  /// This description helps the LLM understand when and how to use the tool.
  String get description;

  /// The JSON Schema defining the parameters this tool accepts.
  ///
  /// This schema is used by the LLM to understand what parameters to provide
  /// when calling the tool.
  Map<String, dynamic> get parameterSchema;

  /// Executes the tool with the given parameters.
  ///
  /// Returns a [ToolResult] containing the execution result or error.
  Future<ToolResult> execute(Map<String, dynamic> params);

  /// Whether this tool can handle the given query.
  ///
  /// This is used for keyword-based tool selection when LLM is not available.
  /// Default implementation returns true for all queries.
  bool canHandle(String query) => true;

  /// Converts this tool to a [ToolSchema] for LLM function calling.
  ToolSchema toSchema() {
    return ToolSchema.function(
      FunctionDefinition(
        name: name,
        description: description,
        parameters: parameterSchema,
      ),
    );
  }

  /// Validates the parameters before execution.
  ///
  /// Throws [ToolException] if validation fails.
  /// Override this method to add custom validation logic.
  void validateParams(Map<String, dynamic> params) {
    // Check required parameters
    final required = parameterSchema['required'] as List<dynamic>?;
    if (required != null) {
      for (final param in required) {
        if (!params.containsKey(param)) {
          throw ToolException(
            'Missing required parameter: $param',
            toolName: name,
          );
        }
      }
    }
  }

  /// Parses tool call arguments from JSON string.
  ///
  /// This is a helper method for handling tool calls from LLMs.
  Map<String, dynamic> parseArguments(String argumentsJson) {
    try {
      return json.decode(argumentsJson) as Map<String, dynamic>;
    } catch (e) {
      throw ToolException(
        'Failed to parse tool arguments: $e',
        toolName: name,
        details: argumentsJson,
      );
    }
  }

  /// Executes the tool from a [ToolCall].
  ///
  /// This is a convenience method that combines argument parsing and execution.
  Future<ToolResult> executeFromCall(ToolCall toolCall) async {
    try {
      final params = parseArguments(toolCall.function.arguments);
      validateParams(params);
      final result = await execute(params);
      return ToolResult(
        toolName: name,
        success: result.success,
        data: result.data,
        error: result.error,
        metadata: result.metadata,
        toolCallId: toolCall.id,
      );
    } catch (e, stackTrace) {
      return ToolResult.failure(
        toolName: name,
        error: e.toString(),
        metadata: {'stackTrace': stackTrace.toString()},
        toolCallId: toolCall.id,
      );
    }
  }

  @override
  String toString() => 'Tool($name)';
}

/// A collection of tools that can be used together.
class ToolRegistry {
  final Map<String, Tool> _tools = {};

  /// Registers a tool.
  void register(Tool tool) {
    _tools[tool.name] = tool;
  }

  /// Registers multiple tools.
  void registerAll(Iterable<Tool> tools) {
    for (final tool in tools) {
      register(tool);
    }
  }

  /// Gets a tool by name.
  Tool? get(String name) => _tools[name];

  /// Gets all registered tools.
  List<Tool> get tools => _tools.values.toList();

  /// Gets all tool schemas for LLM function calling.
  List<ToolSchema> get schemas => tools.map((t) => t.toSchema()).toList();

  /// Finds tools that can handle the given query.
  List<Tool> findToolsForQuery(String query) {
    return tools.where((tool) => tool.canHandle(query)).toList();
  }

  /// Executes a tool call.
  Future<ToolResult> executeCall(ToolCall toolCall) async {
    final tool = get(toolCall.function.name);
    if (tool == null) {
      return ToolResult.failure(
        toolName: toolCall.function.name,
        error: 'Tool not found: ${toolCall.function.name}',
        toolCallId: toolCall.id,
      );
    }

    return await tool.executeFromCall(toolCall);
  }

  /// Executes multiple tool calls in parallel.
  Future<List<ToolResult>> executeCallsParallel(
    List<ToolCall> toolCalls,
  ) async {
    return await Future.wait(
      toolCalls.map((call) => executeCall(call)),
    );
  }

  /// Executes multiple tool calls sequentially.
  Future<List<ToolResult>> executeCallsSequential(
    List<ToolCall> toolCalls,
  ) async {
    final results = <ToolResult>[];
    for (final call in toolCalls) {
      results.add(await executeCall(call));
    }
    return results;
  }

  /// Checks if a tool is registered.
  bool has(String name) => _tools.containsKey(name);

  /// Gets the number of registered tools.
  int get count => _tools.length;

  /// Clears all registered tools.
  void clear() => _tools.clear();

  @override
  String toString() => 'ToolRegistry(${_tools.length} tools)';
}
