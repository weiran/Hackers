# Voting System Consolidation Plan

## Current State Analysis

### Problems Identified

1. **Scattered Implementation**
   - Voting logic is spread across multiple layers and modules
   - UI components handle voting directly in Views (FeedView, CommentsView)
   - ViewModels duplicate voting logic (FeedViewModel, CommentsViewModel)
   - Context menus have inline voting logic
   - Swipe actions contain redundant voting implementations

2. **Code Duplication**
   - Similar voting error handling in FeedView and CommentsView
   - Duplicate optimistic UI update logic in ViewModels
   - Repeated authentication checks in multiple places
   - Context menu voting logic duplicated between PostContextMenu and CommentContextMenu

3. **Inconsistent Behavior**
   - Different error handling strategies between feed and comments
   - Inconsistent optimistic UI updates (FeedViewModel doesn't update score, CommentsViewModel does)
   - Missing validation for vote links availability
   - No centralized state management for voting status

4. **Testing Challenges**
   - UI-coupled voting logic is hard to test
   - Mock implementations scattered across test files
   - No centralized testing utilities for voting scenarios

## Proposed Architecture

### Core Principles
- **Single Responsibility**: Each component has one clear purpose
- **Dependency Inversion**: UI depends on abstractions, not concrete implementations
- **Testability**: All voting logic can be unit tested in isolation
- **Reusability**: Voting components can be reused across different views

### Module Structure

```
Domain/
├── Sources/Domain/
│   ├── UseCases/
│   │   └── VoteUseCase.swift (existing, keep as-is)
│   ├── Services/
│   │   └── VotingService.swift (NEW - orchestration layer)
│   └── Models/
│       └── VotingState.swift (NEW - voting state model)

Data/
├── Sources/Data/
│   └── PostRepository.swift (existing, implements VoteUseCase)

Shared/
├── Sources/Shared/
│   └── ViewModels/
│       └── VotingViewModel.swift (NEW - reusable voting logic)

DesignSystem/
├── Sources/DesignSystem/
│   └── Components/
│       ├── VoteButton.swift (NEW - reusable vote button)
│       ├── VoteIndicator.swift (NEW - vote status indicator)
│       └── VotingContextMenuItems.swift (NEW - reusable menu items)
```

## Implementation Plan

### Phase 1: Domain Layer Enhancement
**Goal**: Create a robust voting service layer

1. **Create VotingState Model**
   ```swift
   public struct VotingState: Sendable {
       public let isUpvoted: Bool
       public let score: Int
       public let canVote: Bool
       public let isVoting: Bool
       public let error: Error?
   }
   ```

2. **Create VotingService**
   ```swift
   public protocol VotingService: Sendable {
       func voteState(for item: Votable) -> VotingState
       func toggleVote(for item: Votable) async throws
       func upvote(item: Votable) async throws
       func downvote(item: Votable) async throws
   }
   ```

3. **Create Votable Protocol**
   ```swift
   public protocol Votable: Identifiable, Sendable {
       var id: Int { get }
       var upvoted: Bool { get set }
       var score: Int { get set }
       var voteLinks: VoteLinks? { get }
   }
   ```

### Phase 2: Shared ViewModel Layer
**Goal**: Create reusable voting view models

1. **Create VotingViewModel**
   - Handles optimistic UI updates
   - Manages error states
   - Provides consistent voting interface
   - Emits state changes for UI updates

2. **Create VotingError Handling**
   - Unified error types for voting
   - Consistent authentication prompts
   - Retry mechanisms

### Phase 3: UI Components
**Goal**: Create reusable UI components for voting

1. **VoteButton Component**
   - Configurable for posts and comments
   - Handles loading states
   - Animated transitions
   - Accessibility support

2. **VoteIndicator Component**
   - Shows current vote status
   - Displays score with animations
   - Color-coded states

3. **VotingContextMenuItems**
   - Factory for creating vote menu items
   - Consistent labeling and icons
   - State-aware menu generation

### Phase 4: Migration
**Goal**: Replace existing implementations with new components

1. **Update FeedView**
   - Replace inline voting logic with VotingViewModel
   - Use VoteButton component
   - Integrate VotingContextMenuItems

2. **Update CommentsView**
   - Replace voting handlers with VotingViewModel
   - Use shared components
   - Remove duplicate logic

3. **Update Context Menus**
   - Use VotingContextMenuItems factory
   - Remove hardcoded voting logic

### Phase 5: Testing
**Goal**: Comprehensive test coverage

1. **Unit Tests**
   - VotingService tests
   - VotingViewModel tests
   - Error handling scenarios

2. **Integration Tests**
   - End-to-end voting workflows
   - Authentication flow testing
   - Error recovery testing

3. **UI Tests**
   - Vote button interactions
   - Context menu voting
   - Swipe action voting

## Benefits

1. **Maintainability**
   - Single source of truth for voting logic
   - Easy to modify voting behavior globally
   - Clear separation of concerns

2. **Testability**
   - All voting logic can be unit tested
   - Mock implementations are centralized
   - UI tests become simpler

3. **Consistency**
   - Uniform voting behavior across the app
   - Consistent error handling
   - Predictable optimistic UI updates

4. **Performance**
   - Reduced code duplication
   - Optimized state updates
   - Better memory management

5. **Developer Experience**
   - Clear interfaces for voting operations
   - Reusable components reduce development time
   - Self-documenting code structure

## Migration Strategy

### Step 1: Non-Breaking Additions (Week 1)
- Add new Domain layer components
- Create shared ViewModels
- Build reusable UI components
- All existing code continues to work

### Step 2: Gradual Migration (Week 2)
- Update one view at a time
- Start with less critical views (Settings)
- Move to Feed, then Comments
- Maintain backward compatibility

### Step 3: Cleanup (Week 3)
- Remove old implementations
- Delete duplicate test mocks
- Update documentation
- Performance optimization

## Success Metrics

1. **Code Reduction**
   - Target: 40% reduction in voting-related code
   - Eliminate all duplicate implementations

2. **Test Coverage**
   - Target: 95% coverage for voting logic
   - All edge cases covered

3. **Bug Reduction**
   - Fix all known voting bugs
   - No new voting-related issues

4. **Performance**
   - Faster vote operations
   - Smoother UI updates
   - Reduced memory footprint

## Risk Mitigation

1. **Backward Compatibility**
   - Keep old implementations during migration
   - Feature flags for new voting system
   - Rollback plan if issues arise

2. **Testing Strategy**
   - Comprehensive test suite before migration
   - A/B testing in production
   - Beta testing with power users

3. **Documentation**
   - Clear migration guide for developers
   - API documentation for new components
   - Usage examples and best practices

## Timeline

- **Week 1**: Domain layer and shared components
- **Week 2**: UI components and initial migration
- **Week 3**: Complete migration and cleanup
- **Week 4**: Testing, documentation, and optimization

## Next Steps

1. Review and approve this plan
2. Create detailed technical specifications
3. Set up feature branch for development
4. Begin Phase 1 implementation
5. Regular progress reviews and adjustments