# Hackers App - Clean Architecture

## Architecture Layers

* **Domain** (`Domain/`): Business logic, models, use case protocols
  - Models: Post, Comment, User, TextSize
  - Use Cases: PostUseCase, CommentUseCase, SettingsUseCase, VoteUseCase
  - VotingService protocol and implementation

* **Data** (`Data/`): Repository implementations, API interactions
  - Implements Domain protocols (PostRepository → PostUseCase)
  - Protocol-based UserDefaults for testability

* **Features** (`Features/`): UI modules with MVVM pattern
  - Separate Swift Package per feature (Feed, Comments, Settings, Onboarding)
  - ViewModels: ObservableObject with @Published properties
  - SwiftUI views with @EnvironmentObject navigation

* **Shared** (`Shared/`): DependencyContainer (singleton), navigation, common utilities

* **DesignSystem** (`DesignSystem/`): Reusable UI components and styling

* **Networking** (`Networking/`): NetworkManagerProtocol for API calls

## Development Standards

### Swift Configuration
* iOS 26+ target, Swift 6.2
* Swift concurrency (async/await)
* @MainActor for UI code
* Sendable conformance for thread safety

### MVVM & Dependency Injection
* ViewModels inject dependencies via protocols
* DependencyContainer.shared provides all dependencies
* Combine for reactive bindings
* @StateObject for view-owned ViewModels
* @EnvironmentObject for navigation/session state

### Testing
* Swift Testing framework (`import Testing`)
* @Suite and @Test attributes
* Test ViewModels, not Views
* Mock dependencies with protocols

## Build & Test Commands

### Important: Working Directory
**Always run xcodebuild from the project directory:** `/Users/weiran/git/Hackers/Hackers/`

### Build Commands
```bash
# Build the app
cd /Users/weiran/git/Hackers/Hackers && xcodebuild -project Hackers.xcodeproj -scheme Hackers -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Clean and build
cd /Users/weiran/git/Hackers/Hackers && xcodebuild clean build -project Hackers.xcodeproj -scheme Hackers -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Quick build status check
cd /Users/weiran/git/Hackers/Hackers && xcodebuild build -project Hackers.xcodeproj -scheme Hackers -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | grep "BUILD"
```

### Test Commands

#### Comprehensive Test Suite (Recommended)
```bash
# Run all module tests with actual test execution and comprehensive reporting
cd /Users/weiran/git/Hackers/Hackers && ./run-all-tests.sh

# Build all modules for testing only (no test execution)
cd /Users/weiran/git/Hackers/Hackers && ./run-all-tests.sh --build-only

# Test specific modules with test execution attempts
cd /Users/weiran/git/Hackers/Hackers && ./run-all-tests.sh Domain Data DesignSystem

# Build specific modules only (no test execution)
cd /Users/weiran/git/Hackers/Hackers && ./run-all-tests.sh -b Feed Comments

# Show help for all options and usage examples
cd /Users/weiran/git/Hackers/Hackers && ./run-all-tests.sh --help
```

#### Individual Commands
```bash
# Build for testing (required before running tests)
cd /Users/weiran/git/Hackers/Hackers && xcodebuild build-for-testing -project Hackers.xcodeproj -scheme Hackers -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Build individual module for testing
cd /Users/weiran/git/Hackers/Hackers && xcodebuild build-for-testing -project Hackers.xcodeproj -scheme [ModuleName] -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Test main scheme (note: may show "no test bundles available")
cd /Users/weiran/git/Hackers/Hackers && xcodebuild test -project Hackers.xcodeproj -scheme Hackers -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### Test Structure Notes
* Tests are in Swift Package modules: `Domain/Tests/`, `Data/Tests/`, `Features/*/Tests/`
* Each module has its own test target: `DomainTests`, `DesignSystemTests`, `DataTests`, etc.
* Tests use Swift Testing framework with `@Suite` and `@Test` attributes
* **Do NOT use `swift test`** - it runs on macOS and fails with iOS-only APIs
* Tests must be run through Xcode with iOS Simulator destination

### Comprehensive Test Script
The project includes `run-all-tests.sh` which supports:

#### Execution Modes
* **Test Mode** (default): Build and run tests for modules
* **Build Mode** (`-b` or `--build-only`): Build modules for testing only

#### Module Selection
* **All Modules** (default): Process all 9 Swift Package modules
* **Specific Modules**: Target individual modules by name

#### Features
* **Flexible Command-Line Interface**: Full argument parsing with help
* **Actual Test Execution**: Attempts to run Swift package tests with multiple approaches
* **Test Result Parsing**: Analyzes test output and provides detailed feedback
* **Colored Output**: Success/failure reporting with visual indicators
* **Proper iOS Simulator Integration**: Uses correct destination for testing
* **Error Validation**: Validates module names and provides helpful error messages
* **Comprehensive Reporting**: Detailed summaries with statistics and test results
* **Lint Integration**: Includes SwiftLint checking as part of build process
* **Multiple Test Strategies**: Uses various methods to execute tests when possible

### Test Modules Included
1. **Domain** - Business logic and models
2. **DesignSystem** - UI components and theming
3. **Data** - Repository implementations and API
4. **Networking** - Network layer
5. **Shared** - Common utilities and services
6. **Feed** - Feed feature module
7. **Comments** - Comments feature module
8. **Settings** - Settings feature module
9. **Onboarding** - Onboarding feature module

### Known Configuration
* Main Hackers.xcscheme properly configured with code coverage enabled
* Individual module schemes auto-generated by Swift Package Manager
* Test execution integrated with main project build system
* All tests compatible with iOS 26+ and Swift 6.2

## Critical Guidelines

* Do what has been asked; nothing more, nothing less
* NEVER create files unless absolutely necessary
* ALWAYS prefer editing existing files
* NEVER proactively create documentation files
* Never use `git add .` - add specific relevant changes only
* Commit messages should be concise and descriptive
