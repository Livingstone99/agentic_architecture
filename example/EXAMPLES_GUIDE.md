# Examples Quick Reference Guide

This guide helps you choose which example to run based on what you want to learn.

## 📋 Examples Overview

| Example | LLM | Complexity | Use Case |
|---------|-----|------------|----------|
| `simple_example.dart` | Mock | ⭐ Basic | Understanding core concepts |
| `simple_chat_example.dart` | DeepSeek | ⭐⭐ Intermediate | Building conversational agents |
| `simple_task_agent_example.dart` | DeepSeek | ⭐⭐ Intermediate | Task-specific agents |
| `moe_example.dart` | Mock | ⭐⭐⭐ Advanced | MOE fundamentals |
| `moe_advanced_example.dart` | DeepSeek | ⭐⭐⭐⭐ Production | Real-world MOE systems |

## 🎯 Choose by Learning Goal

### I want to learn the basics
**Run**: `simple_example.dart`
- No API key needed (uses mock)
- Learn: Agent creation, tools, basic queries
- Time: ~1 minute

### I want to build a chatbot
**Run**: `simple_chat_example.dart`
- Uses real DeepSeek API
- Learn: Multi-turn conversations, context awareness, personality
- Cost: ~$0.0005 (very cheap)
- Time: ~30 seconds

**Example conversation flow**:
```
User: Hi! What can you help me with?
Agent: [Introduces capabilities, offers help]

User: What's the weather like in Paris?
Agent: [Uses weather tool, provides answer]

User: And what's 25 times 18?
Agent: [Remembers context, uses calculator]
```

### I want specialized agents for different tasks
**Run**: `simple_task_agent_example.dart`
- Uses real DeepSeek API
- Learn: Custom prompts, temperature control, task-specific tuning
- Cost: ~$0.0003
- Time: ~45 seconds

**Shows 3 different agents**:
1. **Data Analyst** (temp: 0.3) - Precise, analytical
2. **Technical Writer** (temp: 0.6) - Clear, structured
3. **Problem Solver** (temp: 0.7) - Creative, solution-oriented

### I want to understand MOE (Mixture of Experts)
**Run**: `moe_example.dart` first (mock), then `moe_advanced_example.dart` (real)
- Mock version: Free, quick overview
- Real version: ~$0.002, production-ready example

**Real version demonstrates**:
- 4 specialized experts (Weather, Math, Knowledge, Planning)
- Automatic expert routing
- Response synthesis
- Multi-domain queries

## 💰 Cost Breakdown

All examples use **DeepSeek** ($0.14/M input, $0.28/M output tokens):

| Example | Typical Cost | Tokens Used |
|---------|--------------|-------------|
| `simple_chat_example.dart` | $0.0005 | ~3000 |
| `simple_task_agent_example.dart` | $0.0003 | ~2000 |
| `moe_advanced_example.dart` | $0.002 | ~10000 |

**Total to run all real examples**: ~$0.003 (less than half a cent!)

## 🚀 Quick Start

### 1. Simple Chat (Recommended First)
```bash
# Most beginner-friendly with real API
dart run example/simple_chat_example.dart
```

**You'll see**:
- Multi-turn conversation
- Tool usage (weather, calculator)
- Token costs per interaction
- Natural dialogue flow

### 2. Task Agents
```bash
# See how prompts change behavior
dart run example/simple_task_agent_example.dart
```

**You'll see**:
- Same LLM, 3 different personalities
- Data analysis vs. creative writing
- How temperature affects output

### 3. MOE Advanced
```bash
# Production-ready multi-agent system
dart run example/moe_advanced_example.dart
```

**You'll see**:
- 4 experts working together
- Intelligent routing decisions
- Response synthesis
- Complex multi-domain queries

## 📖 Learning Path

### Beginner Path
1. ✅ `simple_example.dart` - Understand basics (mock, free)
2. ✅ `simple_chat_example.dart` - Build chatbot (real, $0.0005)
3. ✅ Learn about custom prompts from code
4. ✅ Experiment with your own prompts

### Intermediate Path
1. ✅ `simple_task_agent_example.dart` - See task specialization
2. ✅ Modify prompts to create your own specialized agents
3. ✅ `moe_example.dart` - Understand MOE basics (mock)
4. ✅ Study how expert routing works

### Advanced Path
1. ✅ `moe_advanced_example.dart` - Full MOE system
2. ✅ Create your own expert agents
3. ✅ Experiment with delegation strategies
4. ✅ Build production applications

## 🎓 What Each Example Teaches

### `simple_chat_example.dart`
**Key Concepts**:
- ✅ Conversation history management
- ✅ Context awareness across turns
- ✅ Natural language personality via prompts
- ✅ Tool integration in dialogue

**Best For**: Chatbots, customer support, Q&A systems

### `simple_task_agent_example.dart`
**Key Concepts**:
- ✅ Custom system prompts for different tasks
- ✅ Temperature control for creativity vs. precision
- ✅ Specialized agent behaviors
- ✅ Domain-specific optimization

**Best For**: Data analysis, content writing, problem-solving tools

### `moe_advanced_example.dart`
**Key Concepts**:
- ✅ Expert agent specialization
- ✅ Automatic routing to relevant experts
- ✅ Response synthesis from multiple sources
- ✅ Handling multi-domain queries
- ✅ Confidence scoring

**Best For**: Complex systems, enterprise apps, multi-domain services

## 💡 Pro Tips

### For Chat Agents
```dart
// Use higher temperature for personality
temperature: 0.8,

// Keep responses concise
maxTokens: 300,

// Give clear personality guidelines
systemPrompt: '''You are [Name], a [role].
Your personality: [traits]
Response style: [guidelines]'''
```

### For Task Agents
```dart
// Use lower temperature for precision
temperature: 0.3,

// Allow longer responses for analysis
maxTokens: 500,

// Provide structured frameworks
systemPrompt: '''Follow this process:
1. [Step 1]
2. [Step 2]
...'''
```

### For MOE Systems
```dart
// Give each expert clear domain
domain: 'weather',
keywords: ['weather', 'temperature', ...],

// Set appropriate confidence
confidence: 0.95, // High for specialized tools

// Use parallel for speed
strategy: DelegationStrategy.parallel,
```

## 🔧 Customization Ideas

### Easy (5 minutes)
- Change agent personality in prompts
- Modify temperature values
- Add/remove keywords from experts

### Medium (30 minutes)
- Create a new specialized agent
- Add custom tools
- Modify expert routing logic

### Hard (2+ hours)
- Build a complete MOE system for your domain
- Integrate with your backend APIs
- Create custom UI with Flutter widgets

## 📞 Getting Help

1. **Example not working?**
   - Check your API key is correct
   - Ensure you have internet connection
   - Run `flutter pub get` to update dependencies

2. **Want to understand the code?**
   - Read inline comments in example files
   - Check `/doc/` folder for detailed guides
   - Review the architecture documentation

3. **Ready to build your own?**
   - Start with `simple_chat_example.dart`
   - Modify the system prompt
   - Add your own tools
   - Experiment and iterate!

## 🎉 Next Steps

After running the examples:

1. **Read the docs**: `/doc/getting_started.md`
2. **Explore the code**: Check out `/lib/src/` 
3. **Build something**: Start with a simple chatbot
4. **Share feedback**: Let us know what you built!

Happy coding! 🚀

