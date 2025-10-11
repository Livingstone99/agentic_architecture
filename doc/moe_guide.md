# MOE (Mixture of Experts) Guide

The Mixture of Experts (MOE) architecture enables building sophisticated multi-agent systems where specialized experts collaborate to handle complex queries.

## What is MOE?

MOE is a system where:
1. **Multiple expert agents** specialize in different domains
2. A **lead agent** coordinates and routes queries
3. **Response synthesis** combines expert outputs
4. **Intelligent delegation** optimizes expert usage

## When to Use MOE

### ✅ Good Use Cases

- **Multi-domain queries**: "What's the weather in Tokyo and calculate 15+27?"
- **Complex problems**: Queries requiring multiple types of expertise
- **Specialized knowledge**: Different domains need different tools/models
- **Cost optimization**: Use cheaper models for simple tasks, expensive for complex
- **Quality optimization**: Use best-suited expert for each sub-task

### ❌ Not Ideal For

- **Simple queries**: Single-domain questions (use Simple mode)
- **Latency-critical**: MOE adds coordination overhead
- **Limited budget**: Multiple LLM calls increase costs
- **Single expertise needed**: When one agent can handle everything

## Creating Expert Agents

### 1. Define Domain and Keywords

```dart
final weatherExpert = ExpertAgent(
  id: 'weather_expert',
  name: 'Weather Specialist',
  description: 'Expert in meteorological data and forecasts',
  domain: 'weather',
  keywords: [
    'weather',
    'temperature',
    'forecast',
    'rain',
    'sunny',
    'cloudy',
    'humidity',
  ],
  llmProvider: cheapLLM,
  tools: [WeatherTool()],
  confidence: 0.9,
);
```

**Tips**:
- Choose **specific, non-overlapping keywords**
- Include **variations and synonyms**
- Set **appropriate confidence** (0.0-1.0)
- Use **domain-specific tools**

### 2. Select Appropriate LLM

Different experts can use different LLMs:

```dart
// Weather expert - simple task, use cheap model
final weatherExpert = ExpertAgent(
  llmProvider: DeepSeekProvider(apiKey: key),
  // ...
);

// Code expert - complex task, use powerful model
final codeExpert = ExpertAgent(
  llmProvider: OpenAIProvider(apiKey: key, model: 'gpt-4'),
  // ...
);

// Math expert - medium complexity
final mathExpert = ExpertAgent(
  llmProvider: ClaudeProvider(apiKey: key, model: 'claude-3-haiku'),
  // ...
);
```

### 3. Configure Expert Behavior

```dart
final expert = ExpertAgent(
  // ... basic config ...
  config: AgentConfig(
    maxToolRounds: 3,
    temperature: 0.7,
    systemPrompt: '''
      You are a ${domain} expert.
      Focus on providing accurate, specific information.
      Use tools when appropriate.
    ''',
    enableLogging: false, // Reduce noise from individual experts
  ),
);
```

## Creating a Lead Agent

### Basic Setup

```dart
final leadAgent = LeadAgent(
  id: 'lead',
  name: 'Lead Coordinator',
  description: 'Orchestrates multiple expert agents',
  llmProvider: smartLLM, // Use good model for coordination
  experts: [
    weatherExpert,
    mathExpert,
    codeExpert,
  ],
  strategy: DelegationStrategy.intelligent,
  maxExperts: 3,
);
```

### Delegation Strategies

#### 1. Single Expert
**When**: Query clearly belongs to one domain
```dart
strategy: DelegationStrategy.single
```
- Fastest (one expert only)
- Lowest cost
- Best for well-defined queries

#### 2. Parallel Experts
**When**: Query spans multiple domains
```dart
strategy: DelegationStrategy.parallel
```
- Moderate speed (experts run simultaneously)
- Higher cost (multiple LLM calls)
- Good for multi-domain queries

#### 3. Sequential Experts
**When**: Later experts need context from earlier ones
```dart
strategy: DelegationStrategy.sequential
```
- Slowest (experts run one by one)
- Highest cost
- Best for multi-step problems

#### 4. Intelligent Routing
**When**: Let LLM decide the best approach
```dart
strategy: DelegationStrategy.intelligent
```
- Variable speed/cost
- Most flexible
- Requires good lead LLM

## Expert Routing

### Keyword-Based Routing

```dart
// Automatic based on expert keywords
final selectedExperts = router.selectExperts(
  query: 'What is the weather?',
  experts: allExperts,
  strategy: DelegationStrategy.single,
);
// Returns [weatherExpert] based on keyword match
```

**Relevance Score**:
```
score = (matched_keywords / total_keywords) * 0.7 + 
        expert_confidence * 0.3
```

### LLM-Based Routing

```dart
final selectedExperts = router.selectExperts(
  query: query,
  experts: allExperts,
  strategy: DelegationStrategy.intelligent,
  leadLLM: leadAgent.llmProvider,
);
// LLM analyzes query and expert descriptions to select
```

## Response Synthesis

### LLM-Based Synthesis

When lead agent has an LLM provider:

```dart
// Automatically uses LLM to synthesize
final response = await synthesizer.synthesize(
  originalQuery: query,
  expertResponses: [expert1Response, expert2Response],
  leadLLM: leadAgent.llmProvider,
);
```

**Synthesis Process**:
1. Collect all expert responses with metadata
2. Build synthesis prompt with:
   - Original query
   - Expert responses
   - Confidence levels
   - Tool results
3. LLM creates unified response
4. Combines token usage and costs

### Simple Concatenation

Without LLM (fallback):

```dart
final response = await synthesizer.synthesize(
  originalQuery: query,
  expertResponses: [expert1Response, expert2Response],
  leadLLM: null, // No LLM = simple concat
);
```

## Complete MOE Example

```dart
Future<void> moeExample() async {
  // 1. Create LLM providers
  final cheapLLM = DeepSeekProvider(apiKey: 'key1');
  final smartLLM = OpenAIProvider(apiKey: 'key2', model: 'gpt-4');

  // 2. Create expert agents
  final experts = [
    ExpertAgent(
      id: 'weather',
      name: 'Weather Expert',
      description: 'Provides weather information',
      domain: 'weather',
      keywords: ['weather', 'temperature', 'forecast'],
      llmProvider: cheapLLM,
      tools: [WeatherTool()],
      confidence: 0.9,
    ),
    ExpertAgent(
      id: 'math',
      name: 'Math Expert',
      description: 'Solves mathematical problems',
      domain: 'mathematics',
      keywords: ['calculate', 'math', 'number'],
      llmProvider: cheapLLM,
      tools: [CalculatorTool()],
      confidence: 0.95,
    ),
  ];

  // 3. Create lead agent
  final leadAgent = LeadAgent(
    id: 'lead',
    name: 'Lead Agent',
    llmProvider: smartLLM,
    experts: experts,
    strategy: DelegationStrategy.parallel,
  );

  // 4. Create coordinator
  final coordinator = AgentCoordinator(
    leadAgent: leadAgent,
    mode: AgentMode.moe,
    enableLogging: true,
  );

  // 5. Process complex query
  final results = await coordinator.processQuery(
    'What is the weather in London and what is 25 * 4?',
  );

  // 6. Access results
  final result = results.first;
  print(result.content); // Synthesized response
  
  // Check expert contributions
  if (result.expertResponses != null) {
    for (final expert in result.expertResponses!) {
      print('${expert.expertName}: ${expert.content}');
    }
  }
}
```

## Advanced Patterns

### Dynamic Expert Management

```dart
// Add expert at runtime
leadAgent.addExpert(newExpert);

// Remove expert
leadAgent.removeExpert('expert_id');

// Get expert by ID
final expert = leadAgent.getExpert('weather_expert');

// Get experts by domain
final weatherExperts = leadAgent.getExpertsByDomain('weather');
```

### Custom Routing Logic

```dart
class CustomRouter extends ExpertRouter {
  @override
  Future<List<ExpertAgent>> selectExperts({
    required String query,
    required List<ExpertAgent> experts,
    required DelegationStrategy strategy,
    int maxExperts = 3,
    LLMProvider? leadLLM,
  }) async {
    // Your custom routing logic
    return selectedExperts;
  }
}

final leadAgent = LeadAgent(
  // ...
  router: CustomRouter(),
);
```

### Custom Synthesis

```dart
class CustomSynthesizer extends ResponseSynthesizer {
  @override
  Future<AgentResponse> synthesize({
    required String originalQuery,
    required List<ExpertResponse> expertResponses,
    String leadAgentId = 'lead',
    LLMProvider? leadLLM,
  }) async {
    // Your custom synthesis logic
    return synthesizedResponse;
  }
}

final leadAgent = LeadAgent(
  // ...
  synthesizer: CustomSynthesizer(),
);
```

## Performance Optimization

### 1. Choose Right Strategy

```dart
// Fast, cheap - use when query is single-domain
strategy: DelegationStrategy.single

// Balanced - use for multi-domain queries
strategy: DelegationStrategy.parallel

// Use intelligent when unsure
strategy: DelegationStrategy.intelligent
```

### 2. Optimize Expert Count

```dart
// Limit experts for faster response
maxExperts: 2

// More experts for comprehensive answers
maxExperts: 5
```

### 3. Use Appropriate Models

```dart
// Cheap experts for simple tasks
final simpleExpert = ExpertAgent(
  llmProvider: DeepSeekProvider(apiKey: key),
  // ...
);

// Expensive experts for complex tasks
final complexExpert = ExpertAgent(
  llmProvider: OpenAIProvider(apiKey: key, model: 'gpt-4'),
  // ...
);

// Smart lead for good coordination
final lead = LeadAgent(
  llmProvider: OpenAIProvider(apiKey: key, model: 'gpt-4'),
  // ...
);
```

## Cost Management

### Track Costs

```dart
final results = await coordinator.processQuery(query);
final result = results.first;

if (result.tokenUsage != null) {
  print('Total cost: \$${result.tokenUsage!.cost}');
  
  // Check individual experts
  if (result.expertResponses != null) {
    for (final expert in result.expertResponses!) {
      if (expert.tokenUsage != null) {
        print('${expert.expertName}: \$${expert.tokenUsage!.cost}');
      }
    }
  }
}
```

### Cost-Saving Strategies

1. **Use cheaper models for simple experts**
2. **Limit maxExperts**
3. **Use single strategy when possible**
4. **Optimize tool rounds**
5. **Cache expert responses when appropriate**

## Debugging MOE Systems

### Enable Logging

```dart
final coordinator = AgentCoordinator(
  leadAgent: leadAgent,
  mode: AgentMode.moe,
  enableLogging: true, // Enable coordinator logs
);

final leadAgent = LeadAgent(
  // ...
  config: AgentConfig(
    enableLogging: true, // Enable lead agent logs
  ),
);
```

### Inspect Results

```dart
final result = results.first;

print('Synthesized: ${result.synthesized}');
print('Confidence: ${result.confidence}');
print('Experts used: ${result.expertResponses?.length}');

if (result.expertResponses != null) {
  for (final expert in result.expertResponses!) {
    print('\n${expert.expertName}:');
    print('  Domain: ${expert.domain}');
    print('  Confidence: ${expert.confidence}');
    print('  Response: ${expert.content}');
    print('  Tools: ${expert.toolResults.map((t) => t.toolName).join(", ")}');
  }
}
```

## Best Practices

1. **Clear domain boundaries**: Experts should have distinct specializations
2. **Good keywords**: Choose specific, relevant keywords
3. **Appropriate confidence**: Reflect true expert reliability
4. **Right LLMs**: Match model capability to expert complexity
5. **Synthesis quality**: Use good LLM for synthesis
6. **Monitor costs**: Track and optimize token usage
7. **Test routing**: Verify experts are selected correctly
8. **Handle failures**: Experts should fail gracefully

## Common Pitfalls

❌ **Overlapping domains**: Experts compete, routing becomes unclear
✅ **Solution**: Define distinct domains and keywords

❌ **Too many experts**: Increased cost, slower response
✅ **Solution**: Limit maxExperts, use targeted experts

❌ **Weak lead LLM**: Poor routing and synthesis
✅ **Solution**: Use capable model for lead agent

❌ **No fallbacks**: System fails if expert fails
✅ **Solution**: Handle errors gracefully, continue with other experts

❌ **Ignoring costs**: Multiple LLM calls add up
✅ **Solution**: Monitor costs, optimize model selection

## Troubleshooting

### "No experts selected"
- Check keywords match query terms
- Verify expert confidence > 0
- Try DelegationStrategy.parallel

### "Poor synthesis quality"
- Use better LLM for lead agent
- Provide clearer expert responses
- Check expertdescriptions

### "High costs"
- Use cheaper models for simple experts
- Reduce maxExperts
- Use single strategy when possible

### "Slow responses"
- Use parallel instead of sequential
- Reduce maxExperts
- Optimize tool execution

## Next Steps

- Try the [MOE example](../example/moe_example.dart)
- Read [Architecture Guide](architecture.md)
- Explore [Custom LLM Providers](custom_llm.md)

