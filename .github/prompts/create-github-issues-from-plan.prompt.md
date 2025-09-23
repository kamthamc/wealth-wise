---
mode: 'agent'
description: 'Create GitHub Issues from cross-platform implementation plan phases with comprehensive requirements'
tools: ['semantic_search', 'read_file', 'mcp_github_list_issues', 'mcp_github_get_issue', 'mcp_github_create_issue', 'mcp_github_update_issue', 'mcp_github_add_issue_comment']
---

# Create Cross-Platform GitHub Issues from Implementation Plan

Create comprehensive GitHub Issues for the cross-platform implementation plan at `${file}`.

## Cross-Platform Context

This prompt creates GitHub issues for cross-platform development, supporting:
- Security-first implementation with platform-appropriate encryption
- Modern language features and concurrency patterns
- Data accuracy with precise calculation requirements
- Platform-specific optimizations and native integrations
- Advanced UI effects and accessibility compliance

## Process

1. **Analyze Implementation Plan**: Read the plan file to identify security, financial, UI, and testing phases
2. **Check Existing Issues**: Use `mcp_github_list_issues` to avoid duplicates
3. **Create Security Issues**: Prioritize encryption, authentication, and key management issues
4. **Create Financial Issues**: Add issues for Core Data models, Decimal calculations, and financial services
5. **Create UI Issues**: Include SwiftUI components with accessibility and platform features
6. **Create Testing Issues**: Comprehensive testing for security, accuracy, and platform compatibility

## Cross-Platform Requirements

- One issue per implementation phase with appropriate priority
- Security issues marked as high priority with `security` label
- Data accuracy issues marked as critical with `accuracy` label
- Clear, structured titles including platform requirements
- Include modern language features and platform version requirements in descriptions
- Verify against existing issues before creation using GitHub MCP tools

## Issue Creation Strategy

### Security Phase Issues
- **Priority**: High
- **Labels**: `security`, `encryption`, `swift6`, `high-priority`
- **Template**: Security implementation with encryption requirements

### Financial Phase Issues  
- **Priority**: Critical
- **Labels**: `financial`, `core-data`, `decimal`, `critical`
- **Template**: Financial data modeling with accuracy requirements

### UI Phase Issues
- **Priority**: Medium
- **Labels**: `ui`, `swiftui`, `accessibility`, `ios`, `macos`
- **Template**: User interface implementation with platform features

### Testing Phase Issues
- **Priority**: High  
- **Labels**: `testing`, `security-testing`, `financial-testing`, `qa`
- **Template**: Comprehensive testing strategy

## Issue Content Structure

### Title Format
- Security: `[Security] Implement [Feature] with platform-appropriate encryption`
- Data: `[Data] Create [Model] with precise calculations and encryption`
- UI: `[UI] Build [Component] with modern platform features and accessibility`
- Testing: `[Testing] Add [Test Type] for [Component] security and accuracy`

### Description Template
```markdown
## Overview
[Brief description of the feature/phase with business value]

## Security Requirements
- [ ] Platform-appropriate encryption for sensitive data
- [ ] Biometric authentication integration
- [ ] Secure storage implementation
- [ ] Key rotation mechanism

## Data Requirements
- [ ] Precise arithmetic for calculations
- [ ] Cultural/regional support requirements
- [ ] Multi-format handling with proper precision
- [ ] Data categorization with privacy

## Platform Requirements
- [ ] Latest platform compatibility with modern frameworks
- [ ] Native integration patterns
- [ ] Advanced effects where supported
- [ ] Full accessibility compliance

## Modern Language Requirements
- [ ] Modern concurrency patterns enabled
- [ ] Appropriate isolation for services
- [ ] Comprehensive error handling
- [ ] Type safety compliance

## Implementation Tasks
[Specific tasks from the implementation plan phase]

## Acceptance Criteria
- [ ] All security tests pass
- [ ] Financial calculations accurate to 2 decimal places
- [ ] UI works on both iOS and macOS
- [ ] Accessibility features functional
- [ ] Performance benchmarks met

## Testing Requirements
- [ ] Unit tests for core functionality
- [ ] Security penetration testing
- [ ] Financial accuracy validation
- [ ] Platform compatibility testing
- [ ] Accessibility compliance verification

## Related Issues
[Links to dependent or related issues]

## Documentation
- [ ] Code documentation updated
- [ ] Security implications documented
- [ ] API examples provided
- [ ] Platform-specific notes added
```

## Execution Steps

1. **Read Implementation Plan**
   ```
   Use read_file to analyze the plan structure and identify phases
   Extract security, financial, UI, and testing requirements
   Note Swift 6 and platform-specific requirements
   ```

2. **Query Existing Issues**
   ```
   Use mcp_github_list_issues to get current open issues
   Use mcp_github_get_issue for detailed analysis of related issues
   Identify gaps and avoid duplicates
   ```

3. **Create Phase Issues**
   ```
   Use mcp_github_create_issue for each implementation phase
   Set appropriate labels based on issue type and priority
   Include comprehensive requirements and acceptance criteria
   ```

4. **Link Related Issues**
   ```
   Use mcp_github_add_issue_comment to link dependent issues
   Create parent-child relationships for complex features
   Reference existing issues where appropriate
   ```

5. **Update Issue Metadata**
   ```
   Use mcp_github_update_issue to set assignees and milestones
   Add appropriate labels for filtering and organization
   Set priority based on security and financial criticality
   ```

## Issue Labels Strategy

### Priority Labels
- `critical` - Financial accuracy, security vulnerabilities
- `high-priority` - Core functionality, authentication
- `medium-priority` - UI improvements, platform features
- `low-priority` - Documentation, minor enhancements

### Category Labels
- `security` - Encryption, authentication, key management
- `data` - Precise calculations, data processing
- `ui` - Modern UI components, accessibility, platform features
- `testing` - Unit tests, integration tests, security testing
- `concurrency` - Modern concurrency patterns, isolation
- `ios` - iOS-specific features and requirements
- `android` - Android-specific features and requirements
- `windows` - Windows-specific features and requirements
- `documentation` - Code docs, guides, examples

### Technical Labels
- `encryption` - Platform-appropriate encryption implementation
- `database` - Data modeling and persistence
- `accessibility` - Platform accessibility compliance
- `performance` - Optimization and benchmarking
- `localization` - Multi-language and cultural support

Remember: Prioritize security and data accuracy issues first, then UI and testing. Ensure all issues include specific platform requirements and modern language feature compliance details.