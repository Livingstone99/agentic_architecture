import '../../core/result.dart';
import '../../core/tool.dart';

/// A simple echo tool that returns the input message.
///
/// This is the simplest possible tool implementation, useful for:
/// - Testing the tool system
/// - Understanding the tool interface
/// - Debugging agent-tool interactions
class EchoTool extends Tool {
  @override
  String get name => 'echo';

  @override
  String get description =>
      'Echoes back the provided message. Useful for testing and verification.';

  @override
  Map<String, dynamic> get parameterSchema => {
        'type': 'object',
        'properties': {
          'message': {
            'type': 'string',
            'description': 'The message to echo back',
          },
        },
        'required': ['message'],
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> params) async {
    try {
      final message = params['message'] as String?;

      if (message == null || message.isEmpty) {
        return ToolResult.failure(
          toolName: name,
          error: 'Message parameter is required and cannot be empty',
        );
      }

      return ToolResult.success(
        toolName: name,
        data: message,
        metadata: {
          'message_length': message.length,
          'echoed_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      return ToolResult.failure(
        toolName: name,
        error: 'Failed to echo message: $e',
      );
    }
  }

  @override
  bool canHandle(String query) {
    // This tool can handle queries that mention echoing or repeating
    final lowerQuery = query.toLowerCase();
    return lowerQuery.contains('echo') ||
        lowerQuery.contains('repeat') ||
        lowerQuery.contains('say back');
  }
}
