---
description: 'Universal feature development mode: analyze GitHub issues → create branch → implement → test → PR → merge (works for iOS, Android, Windows)'
tools: ['edit', 'search', 'runCommands', 'runTasks', 'github/*', 'playwright/*', 'vscodeAPI', 'problems', 'changes', 'testFailure', 'openSimpleBrowser', 'fetch', 'githubRepo']
---

# Universal Feature Development Mode

You are in feature development mode. Your objective is to implement complete features following the universal development workflow that works across all platforms (iOS/Swift, Android/Kotlin, Windows/.NET).

## Universal Development Workflow

```
📋 Issue Analysis → 🌟 Branch Creation → 💻 Implementation → 🧪 Testing → 📝 Commit → 🔄 Pull Request → ✅ Merge
```

## Phase 1: Issue Analysis & Planning

1. **Analyze GitHub Issue**
   - Use `mcp_github_get_issue` to understand requirements
   - Identify dependencies and acceptance criteria
   - Assess security and performance implications
   - Determine platform-specific considerations

2. **Technical Planning**
   - Choose appropriate architecture patterns for target platform
   - Plan data models, services, and UI components
   - Consider testing strategy and validation approach
   - Estimate implementation complexity
   - Provide summary of the approach in readable format

## Phase 2: Environment Setup

1. **Branch Management** (Universal Pattern)
   ```bash
   # Pull latest changes
   git checkout main && git pull origin main
   
   # Create feature branch
   git checkout -b feature/issue-{number}-{short-title}
   
   # Verify clean state
   git status
   ```

2. **Workspace Preparation**
   - Verify build tools and dependencies
   - Check existing codebase structure
   - Identify integration points

## Phase 3: Implementation

### Platform-Specific Implementation

Refer to the appropriate platform-specific instruction file:
- **Apple (iOS/macOS)**: `.github/instructions/apple.instructions.md`
- **Android**: `.github/instructions/android.instructions.md`  
- **Windows**: `.github/instructions/windows.instructions.md`

Each platform file contains detailed patterns, frameworks, and best practices.

### Universal Implementation Principles

1. **Security First**
   - Encrypt sensitive data at rest
   - Validate all user inputs
   - Use platform-specific secure storage (Keychain, EncryptedSharedPreferences, Windows Credential Manager)

2. **Clean Architecture**
   - Separate business logic from UI
   - Use dependency injection
   - Implement repository patterns
   - Follow platform-specific conventions

3. **Comprehensive Testing**
   - Unit tests for business logic
   - Integration tests for critical flows
   - UI/UX testing for user interactions
   - Security testing for sensitive operations

## Phase 4: Quality Assurance

1. **Code Quality Checks**
   - Run platform-specific linters and formatters
   - Perform static code analysis
   - Check for security vulnerabilities
   - Verify performance benchmarks

2. **Testing Execution**
   - Run all unit tests
   - Execute integration tests
   - Perform manual testing of new features
   - Validate accessibility compliance

## Phase 5: Documentation & Commit

1. **Documentation Updates**
   - Update relevant code documentation
   - Add API examples for complex features
   - Document platform-specific considerations
   - Update user-facing documentation if needed

2. **Git Operations** (Universal Pattern)
   ```bash
   # Stage all changes
   git add .
   
   # Commit with descriptive message
   git commit -m "feat: implement {feature-name}
   
   - Key implementation detail 1
   - Key implementation detail 2
   - Key implementation detail 3
   
   Fixes #{issue-number}"
   
   # Push feature branch
   git push origin feature/issue-{number}-{short-description}
   ```

## Phase 6: Pull Request & Integration

1. **Create Pull Request**
   - Use `activate_github_pull_request_management` 
   - Link to original issue with `Fixes #{issue-number}`
   - Include comprehensive description of changes
   - Add screenshots/videos for UI changes

2. **Code Review Process**
   - Address reviewer feedback
   - Update tests based on review comments
   - Ensure CI/CD pipeline passes
   - Maintain clean commit history

3. **Merge & Cleanup**
   ```bash
   # After PR approval and merge
   git checkout main
   git pull origin main
   git branch -d feature/issue-{number}-{short-description}
   ```

## Platform-Specific Considerations

### iOS/Swift Specific
- Use `@available` annotations for OS version compatibility
- Implement proper memory management with ARC
- Follow iOS Human Interface Guidelines
- Use Instruments for performance profiling

### Android/Kotlin Specific
- Handle different screen densities and sizes
- Implement proper lifecycle management
- Follow Material Design principles
- Use Android Studio profilers for optimization

### Windows/.NET Specific
- Handle different Windows versions and form factors
- Implement proper MVVM patterns
- Follow Fluent Design principles
- Use Visual Studio diagnostic tools

## Issue Management Integration

### Update Issue Progress
```
Use mcp_github_add_issue_comment to:
- Document implementation approach
- Share progress updates
- Link to related commits/PRs
- Note any scope changes
```

### Issue Completion
```
Use mcp_github_update_issue to:
- Close issue when feature is complete
- Link final PR
- Document final implementation notes
```

## Success Criteria

- [ ] Feature fully implemented according to acceptance criteria
- [ ] All tests pass (unit, integration, UI)
- [ ] Code review completed and approved
- [ ] Documentation updated appropriately
- [ ] Performance benchmarks met
- [ ] Security requirements satisfied
- [ ] Platform-specific guidelines followed
- [ ] Issue properly closed with links to implementation

This universal workflow ensures consistent, high-quality feature development across all platforms while respecting platform-specific best practices and conventions.