

# Architecture Overview

This document provides an in-depth look at the `agentic_architecture` package architecture.

## System Design

```
┌─────────────────────────────────────────────────────────────┐
│                     User Application                         │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                  Agent Coordinator                           │
│  • Manages agent lifecycle                                   │
│  • Handles query routing                                     │
│  • Controls execution mode (Simple/MOE)                      │
└───────────────────────┬─────────────────────────────────────┘
                        │
        ┌───────────────┴───────────────┐
        ▼                               ▼
┌──────────────────┐          ┌──────────────────┐
│   Simple Mode    │          │    MOE Mode      │
│                  │          │                  │
│  Lead Agent      │          │   Lead Agent     │
│  + Tools         │          │   + Experts      │
│  ↓               │          │   ↓              │
│  Response        │          │   Synthesis      │
└──────────────────┘          └──────────────────┘
                                      │
                        ┌─────────────┴─────────────┐
                        ▼                           ▼
                ┌──────────────┐          ┌──────────────┐
                │   Expert 1   │          │   Expert N   │
                │   + Tools    │   ...    │   + Tools    │
                └──────────────┘          └──────────────┘
```

## Core Components

### 1. Agent

**Purpose**: Autonomous entity that processes queries using an LLM and tools.

**Key Methods**:
- `process(AgentRequest)`: Main processing method
- `canHandle(AgentRequest)`: Determines if agent can handle a query
- `executeTools(List<ToolCall>)`: Executes LLM-requested tools

**Implementations**:
- `SimpleAgent`: Basic agent with LLM and tools
- `ExpertAgent`: Specialized agent for MOE mode
- `LeadAgent`: Coordinator agent in MOE mode

### 2. Tool

**Purpose**: Extends agent capabilities by providing access to external functions.

**Key Methods**:
- `execute(Map<String, dynamic>)`: Performs the tool's function
- `toSchema()`: Converts to LLM-compatible schema
- `canHandle(String)`: Keyword-based routing

**Example Tools**:
- `CalculatorTool`: Mathematical operations
- `WeatherTool`: Weather information
- `EchoTool`: Simple echo for testing

### 3. LLM Provider

**Purpose**: Abstracts different LLM APIs for flexibility and interchangeability.

**Key Methods**:
- `chat()`: Synchronous chat completion
- `chatStream()`: Streaming chat completion
- `calculateCost()`: Token cost calculation

**Implementations**:
- `DeepSeekProvider`: DeepSeek API
- `OpenAIProvider`: OpenAI API
- `ClaudeProvider`: Anthropic Claude API
- `GeminiProvider`: Google Gemini API
- `MockLLMProvider`: Testing mock

### 4. Agent Coordinator

**Purpose**: Entry point for query processing, manages agent lifecycle.

**Responsibilities**:
- Route queries to appropriate agents
- Handle simple vs MOE mode
- Manage conversation context
- Track metrics and logging

### 5. MOE System

#### Expert Router
Routes queries to appropriate expert(s) based on:
- Keyword matching
- Relevance scoring
- LLM-based routing (intelligent mode)
- Delegation strategy

#### Response Synthesizer
Combines expert responses into unified answers:
- LLM-based synthesis (intelligent)
- Simple concatenation (fallback)
- Handles confidence weighting

#### Delegation Strategies
- **Single**: One best expert
- **Parallel**: Multiple experts simultaneously
- **Sequential**: Experts in order
- **Intelligent**: LLM decides

## Data Flow

### Simple Mode Flow

```
1. User Query
    ↓
2. Agent Coordinator
    ↓
3. Lead Agent
    ↓
4. LLM Provider (chat)
    ↓
5. Tool Calls? ──No──→ 8. Return Response
    ↓ Yes
6. Execute Tools
    ↓
7. LLM Provider (with tool results)
    ↓
8. Return Response
    ↓
9. Agent Coordinator
    ↓
10. User Application
```

### MOE Mode Flow

```
1. User Query
    ↓
2. Agent Coordinator (MOE mode)
    ↓
3. Lead Agent
    ↓
4. Expert Router (select experts)
    ↓
5. Execute Delegation Strategy
    │
    ├─→ Single: Best Expert
    │
    ├─→ Parallel: Expert 1 ──┐
    │            Expert 2 ──┤
    │            Expert N ──┘
    │
    └─→ Sequential: Expert 1 → Expert 2 → Expert N
    ↓
6. Collect Expert Responses
    ↓
7. Response Synthesizer
    ↓
8. Unified Response
    ↓
9. Agent Coordinator
    ↓
10. User Application
```

## Message Types

### LLMMessage
Represents a message in a conversation:
```dart
class LLMMessage {
  final MessageRole role;       // user, assistant, system, tool
  final String content;
  final List<ToolCall>? toolCalls;
  final String? toolCallId;
}
```

### AgentRequest
Input to agent processing:
```dart
class AgentRequest {
  final String query;
  final List<LLMMessage> history;
  final Map<String, dynamic> context;
  final int? maxTokens;
  final double? temperature;
}
```

### AgentResponse
Output from agent processing:
```dart
class AgentResponse {
  final String agentId;
  final String content;
  final List<ToolCall> toolCalls;
  final List<ToolResult> toolResults;
  final double confidence;
  final List<ExpertResponse>? expertResponses;
  final bool synthesized;
  final TokenUsage? tokenUsage;
}
```

### AgentResult
Final result returned to user:
```dart
class AgentResult {
  final String agentId;
  final String agentName;
  final String content;
  final bool synthesized;
  final double confidence;
  final List<ToolResult> toolResults;
  final List<ExpertResponse>? expertResponses;
  final TokenUsage? tokenUsage;
}
```

## Tool Execution

### Tool Call Flow

```
1. LLM returns tool calls
    ↓
2. Agent validates tool exists
    ↓
3. Parse tool arguments (JSON)
    ↓
4. Validate parameters against schema
    ↓
5. Execute tool
    ↓
6. Return ToolResult (success/failure)
    ↓
7. Add to conversation history
    ↓
8. LLM processes tool results
```

### Tool Result

```dart
class ToolResult {
  final String toolName;
  final bool success;
  final dynamic data;
  final String? error;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
}
```

## Agent Lifecycle

### 1. Initialization
```dart
final agent = SimpleAgent(
  id: 'agent_1',
  name: 'Assistant',
  llmProvider: provider,
  tools: tools,
  config: config,
);
```

### 2. Request Processing
```dart
final request = AgentRequest(
  query: 'What is 2+2?',
  history: conversationHistory,
);

final response = await agent.process(request);
```

### 3. Tool Execution Loop
```
while (hasToolCalls && rounds < maxRounds) {
  1. Execute tools
  2. Add results to history
  3. Query LLM with results
  4. Check for more tool calls
}
```

### 4. Response Assembly
```dart
return AgentResponse(
  agentId: id,
  content: llmResponse.content,
  toolResults: allToolResults,
  tokenUsage: usage,
);
```

## MOE Expert Selection

### Keyword-Based Scoring

```dart
score = (matched_keywords / total_keywords) * 0.7 + 
        expert_confidence * 0.3
```

### LLM-Based Selection

```
1. Build prompt with:
   - Query
   - Expert descriptions
   - Selection criteria
   
2. LLM analyzes and selects experts

3. Parse expert names from response

4. Fallback to keyword-based if LLM fails
```

## Response Synthesis

### LLM-Based Synthesis

```
1. Collect all expert responses

2. Build synthesis prompt:
   - Original query
   - Expert responses with confidence
   - Synthesis instructions

3. LLM generates unified response

4. Combine token usage and metadata
```

### Simple Concatenation

```
1. Format each expert response:
   **Expert Name (Domain)**:
   Response content

2. Combine all formatted responses

3. Return concatenated result
```

## Error Handling

### Exception Hierarchy

```
AgenticException (base)
├── AgentException
├── ToolException
├── LLMProviderException
│   ├── AuthenticationException
│   └── RateLimitException
├── CoordinationException
├── RoutingException
└── ConfigurationException
```

### Error Recovery

1. **Tool Failures**: Continue with other tools, report errors
2. **Expert Failures**: Exclude failed expert, continue with others
3. **LLM Failures**: Return error with context
4. **Synthesis Failures**: Fallback to simple concatenation

## Performance Considerations

### Parallel Execution
- Tools can execute in parallel
- Experts execute in parallel (parallel strategy)
- Reduces total latency

### Token Optimization
- Track token usage per agent
- Calculate costs per provider
- Monitor and optimize prompts

### Caching
- LLM responses (provider-dependent)
- Tool results (when appropriate)
- Expert routing decisions

### Rate Limiting
- Handle provider rate limits gracefully
- Implement exponential backoff
- Use different providers for different experts

## Security

### API Key Management
- Never hardcode API keys
- Use environment variables
- Rotate keys regularly

### Input Validation
- Validate all tool parameters
- Sanitize user queries
- Limit query length

### Output Filtering
- Filter sensitive information
- Validate tool outputs
- Monitor for prompt injection

## Testing Strategy

### Unit Tests
- Individual tools
- Agent logic
- Expert routing
- Response synthesis

### Integration Tests
- End-to-end flows
- Multi-agent coordination
- Error handling

### Mock Providers
```dart
final mockLLM = MockLLMProvider(
  responses: ['Mock response'],
);
```

## Extension Points

### Custom Tools
Extend `Tool` base class:
```dart
class CustomTool extends Tool {
  // Implement required methods
}
```

### Custom LLM Providers
Extend `LLMProvider`:
```dart
class CustomProvider extends LLMProvider {
  // Implement required methods
}
```

### Custom Agents
Extend `Agent` base class:
```dart
class CustomAgent extends Agent {
  // Implement processing logic
}
```

## Best Practices

1. **Use appropriate models**
   - DeepSeek for cost-effective operations
   - GPT-4 for complex reasoning
   - Claude for long context

2. **Optimize prompts**
   - Clear, concise system prompts
   - Provide examples when needed
   - Test and iterate

3. **Handle errors gracefully**
   - Always use try-catch
   - Provide fallbacks
   - Log errors appropriately

4. **Monitor costs**
   - Track token usage
   - Set budgets and alerts
   - Optimize expensive operations

5. **Design good tools**
   - Single responsibility
   - Clear parameter schemas
   - Robust error handling

6. **Structure experts well**
   - Clear domain boundaries
   - Relevant keywords
   - Appropriate confidence levels

## Future Enhancements

- Memory persistence
- Streaming support for MOE
- Advanced routing algorithms
- Tool result caching
- Multi-turn planning
- Agent introspection
- Performance profiling
- Cost optimization

