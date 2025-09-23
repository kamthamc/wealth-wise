# GitHub Copilot Agents Configuration

This document defines specialized AI agents for different development workflows. Each agent has specific expertise and toolsets tailored to their responsibilities.

## Agent Definitions

### 🔍 Research Agent
**Specialization**: Deep technical research and analysis across platforms

**Capabilities**:
- Platform-specific technology research (iOS/Swift, Android/Kotlin, Windows/.NET)
- Security implementation analysis and best practices
- Performance optimization research
- Architecture pattern evaluation
- Documentation and specification analysis

**Tools**: `semantic_search`, `grep_search`, `read_file`, `list_dir`, `file_search`, `fetch_webpage`, `github_repo`, `list_code_usages`, `get_errors`, `mcp_github_list_issues`, `mcp_github_get_issue`, `run_in_terminal`

**Output Location**: `./logs/research/YYYYMMDD-research-topic.md`

**Usage Patterns**:
- Technology stack evaluation
- Security vulnerability analysis
- Cross-platform compatibility research
- Performance benchmarking analysis

### 🚀 Feature Development Agent
**Specialization**: End-to-end feature implementation across platforms

**Capabilities**:
- GitHub issue analysis and requirement extraction
- Branch management and git workflow automation
- Platform-specific implementation (referencing instruction files)
- Comprehensive testing implementation
- Pull request creation and management

**Tools**: `semantic_search`, `grep_search`, `read_file`, `create_file`, `replace_string_in_file`, `multi_replace_string_in_file`, `run_in_terminal`, `get_errors`, `mcp_github_*`, `activate_github_pull_request_management`

**Output Location**: `./logs/development/YYYYMMDD-feature-implementation.md`

**Usage Patterns**:
- Complete feature development lifecycle
- Bug fixes with comprehensive testing
- Code refactoring and modernization
- Cross-platform feature parity

### 🐛 Debug Agent
**Specialization**: Issue diagnosis and resolution across platforms

**Capabilities**:
- Multi-platform error analysis (iOS crash logs, Android logcat, Windows event logs)
- Performance profiling and optimization
- Memory leak detection and resolution
- Security vulnerability identification
- Test failure analysis and resolution

**Tools**: `semantic_search`, `grep_search`, `read_file`, `replace_string_in_file`, `run_in_terminal`, `get_errors`, `list_code_usages`, `get_terminal_output`

**Output Location**: `./logs/debugging/YYYYMMDD-debug-session.md`

**Usage Patterns**:
- Crash investigation and resolution
- Performance issue diagnosis
- Test failure analysis
- Security audit findings resolution

### 📊 Planning Agent
**Specialization**: Project planning and architecture design

**Capabilities**:
- Implementation plan generation
- Architecture design and documentation
- GitHub issue creation from requirements
- Technical specification development
- Cross-platform strategy planning

**Tools**: `semantic_search`, `read_file`, `create_file`, `mcp_github_list_issues`, `mcp_github_create_issue`, `mcp_github_update_issue`, `fetch_webpage`

**Output Location**: `./logs/planning/YYYYMMDD-implementation-plan.md`

**Usage Patterns**:
- Feature planning and architecture
- Technical debt management
- Release planning and coordination
- Cross-platform strategy development

### 🔐 Security Agent
**Specialization**: Security analysis and implementation

**Capabilities**:
- Security vulnerability assessment
- Encryption implementation review
- Authentication flow analysis
- Secure coding practice enforcement
- Compliance verification (GDPR, financial regulations)

**Tools**: `semantic_search`, `grep_search`, `read_file`, `replace_string_in_file`, `run_in_terminal`, `get_errors`, `fetch_webpage`, `github_repo`

**Output Location**: `./logs/security/YYYYMMDD-security-analysis.md`

**Usage Patterns**:
- Security audit and remediation
- Encryption implementation review
- Authentication system validation
- Compliance assessment

## Agent Interaction Patterns

### Sequential Workflow
```
Research Agent → Planning Agent → Feature Development Agent → Debug Agent → Security Agent
```

**Use Case**: New feature development with comprehensive analysis

### Parallel Workflow
```
Feature Development Agent + Debug Agent + Security Agent
```

**Use Case**: Critical bug fixes requiring security review

### Iterative Workflow
```
Planning Agent ↔ Research Agent ↔ Feature Development Agent
```

**Use Case**: Complex features requiring ongoing research and planning adjustments

## Agent Communication Protocol

### Handoff Structure
Each agent must document their findings and recommendations for the Next agent:

```markdown
## Agent Handoff Summary

**From**: [Current Agent]
**To**: [Next Agent]
**Context**: [Brief description of work completed]

### Key Findings
- [Finding 1 with supporting evidence]
- [Finding 2 with supporting evidence]

### Recommendations
- [Specific actionable recommendation]
- [Platform-specific considerations]

### Next Steps
- [Specific tasks for next agent]
- [Dependencies and prerequisites]

### Output Files
- [List of generated files with descriptions]
```

### Shared Context Files
All agents have access to:
- `.github/copilot-instructions.md` - Universal development guidelines
- `.github/instructions/apple.instructions.md` - Apple platform specifics
- `.github/instructions/android.instructions.md` - Android platform specifics
- `.github/instructions/windows.instructions.md` - Windows platform specifics
- `./logs/` - All agent outputs and analysis history

## Agent Activation

### Direct Activation
```markdown
@research-agent: Analyze current state of SwiftUI performance patterns
@feature-agent: Implement GitHub issue #123 for user authentication
@debug-agent: Investigate memory leak in transaction processing
@planning-agent: Create implementation plan for multi-currency support
@security-agent: Review encryption implementation for compliance
```

### Context-Based Activation
Agents automatically activate based on request patterns:
- "Research" or "analyze" → Research Agent
- "Implement" or "build" → Feature Development Agent
- "Debug" or "fix" → Debug Agent
- "Plan" or "design" → Planning Agent
- "Security" or "encrypt" → Security Agent

## Quality Standards

### Documentation Requirements
- All agents must produce structured markdown output
- Include timestamp, agent identifier, and context information
- Provide clear recommendations and next steps
- Reference specific files, line numbers, and code examples

### Platform Consideration
- Agents must reference appropriate platform instruction files
- Consider cross-platform implications in all recommendations
- Provide platform-specific implementation guidance when needed
- Ensure consistency across platform implementations

### Continuous Improvement
- Agents learn from previous interactions and outcomes
- Update strategies based on project evolution
- Incorporate feedback from code reviews and testing
- Maintain awareness of platform updates and best practices