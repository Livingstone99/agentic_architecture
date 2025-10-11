/// A production-ready Flutter package for building intelligent agent-based applications.
///
/// Supports:
/// - Single lead agent with tools (simple mode)
/// - Mixture of Experts (MOE) with multiple specialized sub-agents
/// - Pluggable LLM providers (OpenAI, DeepSeek, Claude, Gemini, custom)
/// - Each agent can use different LLM providers
/// - Optional UI widgets and educational features
library agentic_architecture;

// Core abstractions
export 'src/core/agent.dart';
export 'src/core/agent_coordinator.dart';
export 'src/core/exceptions.dart';
export 'src/core/llm_provider.dart';
export 'src/core/message.dart';
export 'src/core/result.dart';
export 'src/core/tool.dart';

// LLM Providers
export 'src/providers/claude_provider.dart';
export 'src/providers/deepseek_provider.dart';
export 'src/providers/gemini_provider.dart';
export 'src/providers/openai_provider.dart';

// MOE System
export 'src/moe/delegation_strategy.dart';
export 'src/moe/expert_agent.dart';
export 'src/moe/expert_router.dart';
export 'src/moe/lead_agent.dart';
export 'src/moe/response_synthesizer.dart';

// Example Tools (for reference and testing)
export 'src/examples/tools/calculator_tool.dart';
export 'src/examples/tools/echo_tool.dart';
export 'src/examples/tools/weather_tool.dart';
