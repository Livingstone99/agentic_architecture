# Contributing to Agentic Architecture

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Getting Started

1. **Fork the repository**
2. **Clone your fork**:
   ```bash
   git clone https://github.com/yourusername/agentic_architecture.git
   cd agentic_architecture
   ```
3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

## Development Setup

### Prerequisites

- Dart SDK >=3.0.0
- Flutter >=3.10.0

### Running Tests

```bash
# Run all tests
dart test

# Run specific test file
dart test test/core/agent_test.dart

# Run with coverage
dart test --coverage
```

### Running Examples

```bash
# Simple agent example
dart run example/simple_example.dart

# MOE example
dart run example/moe_example.dart
```

## Code Style

### Dart Style Guide

Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart):

- Use `dartfmt` for formatting
- Follow naming conventions
- Write clear, descriptive comments
- Keep functions focused and small

### Linting

The project uses `flutter_lints`. Check for issues:

```bash
dart analyze
```

Fix auto-fixable issues:

```bash
dart fix --apply
```

## Making Changes

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Your Changes

- Write clear, concise code
- Add tests for new features
- Update documentation
- Follow existing patterns

### 3. Write Tests

All new features must include tests:

```dart
import 'package:test/test.dart';
import 'package:agentic_architecture/agentic_architecture.dart';

void main() {
  group('YourFeature', () {
    test('does what it should', () {
      // Test implementation
    });
  });
}
```

### 4. Update Documentation

- Update README if adding major features
- Add/update doc comments
- Update relevant guides in `doc/`
- Add examples if helpful

### 5. Commit Your Changes

Use clear, descriptive commit messages:

```bash
git add .
git commit -m "feat: add custom tool support"
```

**Commit message format**:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation
- `test:` for tests
- `refactor:` for code refactoring
- `chore:` for maintenance

### 6. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a pull request on GitHub.

## Pull Request Guidelines

### PR Checklist

- [ ] Code follows style guidelines
- [ ] Tests pass locally
- [ ] New tests added for new features
- [ ] Documentation updated
- [ ] No breaking changes (or clearly documented)
- [ ] PR description clearly explains changes

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe testing performed

## Checklist
- [ ] Tests pass
- [ ] Code follows style guide
- [ ] Documentation updated
```

## Areas for Contribution

### High Priority

1. **Additional LLM Providers**
   - Mistral AI
   - Cohere
   - Local models (Ollama, LMStudio)

2. **More Example Tools**
   - Web search
   - Database queries
   - File operations
   - API integrations

3. **UI Components**
   - Flutter widgets for agent interfaces
   - Chat UI
   - Tool execution visualization

4. **Testing**
   - More unit tests
   - Integration tests
   - Performance tests

### Medium Priority

1. **Documentation**
   - More examples
   - Tutorial videos
   - Best practices guide

2. **Performance**
   - Caching strategies
   - Parallel execution optimization
   - Token usage optimization

3. **Features**
   - Memory persistence
   - Conversation history management
   - Advanced routing algorithms

### Nice to Have

1. **DevTools**
   - Agent debugging tools
   - Cost tracking dashboard
   - Performance profiling

2. **Integrations**
   - Langchain compatibility
   - OpenAI Assistant API support
   - Vector database integration

## Code Organization

### Directory Structure

```
lib/
├── src/
│   ├── core/          # Core abstractions
│   ├── providers/     # LLM provider implementations
│   ├── moe/           # MOE system
│   └── examples/      # Example implementations
├── agentic_architecture.dart  # Main export
```

### Adding a New LLM Provider

1. Create file in `lib/src/providers/`
2. Extend `LLMProvider` or `HttpLLMProvider`
3. Implement required methods
4. Add tests in `test/providers/`
5. Add example usage
6. Update main export file
7. Update documentation

### Adding a New Tool

1. Create file in `lib/src/examples/tools/` or your own package
2. Extend `Tool` base class
3. Implement required methods
4. Add tests
5. Add usage example
6. Document in appropriate guide

## Testing Guidelines

### Unit Tests

Test individual components in isolation:

```dart
test('component does X', () {
  final component = MyComponent();
  expect(component.doSomething(), equals(expected));
});
```

### Integration Tests

Test component interactions:

```dart
test('agent uses tool correctly', () async {
  final agent = SimpleAgent(/*...*/);
  final result = await agent.process(request);
  expect(result.toolResults, isNotEmpty);
});
```

### Mocking

Use `MockLLMProvider` for testing without real API calls:

```dart
final mockLLM = MockLLMProvider(
  responses: ['Mock response'],
);
```

## Documentation

### Code Comments

```dart
/// Brief description of what this does.
///
/// More detailed explanation if needed.
///
/// Example:
/// ```dart
/// final thing = MyThing();
/// thing.doSomething();
/// ```
class MyThing {
  /// What this method does.
  void doSomething() {
    // Implementation
  }
}
```

### Markdown Documentation

- Use clear headings
- Include code examples
- Add diagrams when helpful
- Link to related docs

## Review Process

1. **Automated Checks**
   - Tests must pass
   - Linter must pass
   - Coverage should not decrease

2. **Manual Review**
   - Code quality
   - Architecture fit
   - Documentation quality
   - Test coverage

3. **Feedback**
   - Address review comments
   - Update PR as needed
   - Re-request review

## Community

### Getting Help

- [GitHub Discussions](https://github.com/yourusername/agentic_architecture/discussions)
- [GitHub Issues](https://github.com/yourusername/agentic_architecture/issues)

### Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Assume good intentions

## Release Process

(For maintainers)

1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md`
3. Create git tag
4. Publish to pub.dev
5. Create GitHub release

## Questions?

Feel free to:
- Open an issue for bugs
- Start a discussion for questions
- Submit a PR for contributions

Thank you for contributing! 🎉

