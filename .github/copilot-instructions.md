# Cross-Platform Development Instructions

## Project Overview
This is a cross-platform application targeting multiple platforms with native implementations for optimal user experience and performance.

## Supported Platforms
- **Apple Platforms**: Modern Swift with native UI frameworks
- **Android**: Kotlin with modern Android development stack
- **Windows**: .NET with native Windows UI frameworks

## Platform-Specific Instructions
Based on the issue or task platform, refer to the appropriate instruction file:

- **Apple Development**: `.github/instructions/apple.instructions.md`
- **Android Development**: `.github/instructions/android.instructions.md`
- **Windows Development**: `.github/instructions/windows.instructions.md`

## Universal Development Principles

### Security First (All Platforms)
- All financial data must be encrypted at rest
- Use platform-specific secure storage mechanisms
- Implement biometric authentication where available
- Apply secure coding practices and input validation
- Never store sensitive data in plain text

### Platform-Native Design
- Follow platform-specific design guidelines
- Use native UI patterns and navigation
- Implement proper accessibility features
- Support cultural localization for target markets

### Modern Development Patterns
- Use platform-appropriate async patterns
- Implement comprehensive error handling
- Apply dependency injection for testability
- Follow clean architecture principles
- Write comprehensive unit and integration tests

### Code Quality Standards
- Follow platform-specific naming conventions
- Use modern language features appropriately
- Maintain clean separation of concerns
- Document complex business logic
- Implement comprehensive testing strategies

## Architecture Guidelines

### Core Data Models
Refer to platform-specific instruction files for detailed data model implementations:
- Apple platforms: Use modern Swift data modeling patterns
- Android: Use Kotlin data classes with appropriate frameworks
- Windows: Use .NET data models with proper encapsulation

### Service Layer
Implement service-oriented architecture following platform conventions:
- Use protocol-oriented design patterns
- Apply appropriate concurrency models for each platform
- Implement dependency injection for testability
- Follow platform-specific async/await patterns

### UI Components
Build modern, accessible user interfaces following platform guidelines:
- Use platform-native UI frameworks and patterns
- Implement proper accessibility features
- Apply modern design principles (Material Design, Fluent Design, Human Interface Guidelines)
- Support dark mode and responsive layouts

## MCP Tools Integration

### GitHub Issue Management
When working with GitHub issues, use these MCP tools:
- `mcp_github_list_issues` - List open issues for project planning
- `mcp_github_get_issue` - Get detailed issue information
- `mcp_github_create_issue` - Create new issues from feature requests
- `mcp_github_update_issue` - Update issue status and progress
- `mcp_github_add_issue_comment` - Add progress comments and documentation

### Repository Operations
- `mcp_github_list_commits` - Review recent changes and code history
- `activate_github_pull_request_management` - Manage PRs and reviews
- `mcp_github_list_notifications` - Check for pending reviews and mentions

### Automated Workflow Pattern
```
1. List issues → 2. Analyze requirements → 3. Create branch → 
4. Implement solution → 5. Test thoroughly → 6. Commit changes → 
7. Create PR → 8. Link to issue → 9. Request review
```

## Feature Implementation Guidelines

### Financial Data Processing
- Always validate input data before processing
- Use Decimal for currency calculations (never Float/Double)
- Implement proper rounding rules for Indian currency
- Support multiple account types (bank, credit card, UPI, brokerage)

### User Interface Standards
- Implement proper loading states and error handling
- Use haptic feedback for important actions
- Support both light and dark modes
- Ensure accessibility with VoiceOver support
- Implement proper keyboard navigation

### Performance Optimization
- Use lazy loading for large data sets
- Implement proper database batch processing
- Cache frequently accessed data appropriately
- Use background processing for heavy computations

## Testing Requirements

### Unit Testing
- Test critical business logic components
- Use dependency injection for testability
- Mock external dependencies and services
- Verify error handling and edge cases
- Maintain high code coverage for core functionality

### UI Testing
- Test critical user flows and navigation
- Verify accessibility features work correctly
- Test on target platforms and configurations
- Validate error states and edge cases
- Ensure responsive design works across screen sizes

## Code Generation Preferences

### Naming Conventions
- Use descriptive names for variables and functions
- Follow platform-specific naming conventions
- Use meaningful abbreviations sparingly
- Apply consistent naming patterns across codebase

### Error Handling
- Use platform-appropriate error handling patterns
- Implement comprehensive error types and messages
- Provide clear error descriptions for user-facing errors
- Follow platform conventions for error propagation
- Use structured error handling for better debugging

### Documentation Standards
- Add documentation comments for public APIs
- Explain complex business logic
- Include code examples for non-trivial functions
- Document security considerations

## Platform Integration

### Cross-Platform Patterns
- Implement shared business logic components
- Use platform-appropriate abstractions
- Maintain consistent data models across platforms
- Share networking and persistence layers where possible
- Apply dependency injection for platform-specific implementations

## Security Implementation

### Data Encryption
- All sensitive data must be encrypted at rest
- Use platform-appropriate encryption mechanisms
- Implement proper key management and rotation
- Follow security best practices for each platform

### Authentication Flow
- Implement biometric authentication as primary method
- Fall back to platform-appropriate secondary authentication
- Use proper session management
- Implement automatic logout on security events

## Performance Guidelines

### Memory Management
- Use platform-appropriate memory management patterns
- Implement proper caching strategies
- Use lazy initialization for expensive resources
- Monitor memory usage during development

### Database Operations
- Use batch operations for multiple changes
- Implement proper indexing for search queries
- Use background processing for heavy operations
- Cache frequently accessed reference data

## Localization Support

### String Management
- Use platform-native localization features
- Support right-to-left languages
- Implement proper number and currency formatting
- Use culturally appropriate date formats

### Cultural Adaptations
- Support regional financial patterns and requirements
- Implement locale-specific banking integrations
- Use appropriate currency symbols and formatting
- Support regional languages as enhancement