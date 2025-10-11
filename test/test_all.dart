// Run all tests
import 'core/agent_test.dart' as agent_test;
import 'core/tool_test.dart' as tool_test;
import 'moe/expert_agent_test.dart' as expert_agent_test;

void main() {
  agent_test.main();
  tool_test.main();
  expert_agent_test.main();
}
