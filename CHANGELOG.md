# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2025-10-15

### Fixed
- Replaced all `print()` statements in library code with proper logging framework
- Created `AgenticLogger` using `dart:developer` for production-safe logging
- Resolved pub.dev static analysis warnings about `avoid_print`
- All logging now controlled by `enableLogging` flag in `AgentConfig`

### Technical Details
- Added `lib/src/core/logger.dart` with production-ready logging
- Updated 6 files to use new logger instead of print
- No breaking changes - all functionality preserved
- All 32 tests still passing

## [0.1.0] - 2025-10-11

### Added
- Initial release of Agentic Architecture package
- Core agent abstraction with `Agent` base class
- Tool system with `Tool` interface
- LLM provider abstraction with `LLMProvider` base class
- Agent coordinator for orchestrating agents
- Multiple LLM provider implementations:
  - DeepSeek
  - OpenAI
  - Claude (Anthropic)
  - Gemini (Google)
- Mixture of Experts (MOE) system:
  - Lead agent orchestration
  - Expert agent specialization
  - Intelligent expert routing
  - Response synthesis
- Delegation strategies:
  - Single expert
  - Parallel execution
  - Sequential execution
  - Intelligent (LLM-based)
- Conversation memory support
- Response formatting service
- Educational features:
  - Token tracking
  - Cost analysis
  - Logging service
- Example tools:
  - Echo tool
  - Calculator tool
  - Weather tool
- Example applications
- Comprehensive documentation

[0.1.0]: https://github.com/yourusername/agentic_architecture/releases/tag/v0.1.0

