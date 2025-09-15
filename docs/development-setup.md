---
title: Development Setup
version: 1.0.0
lastUpdated: 2025-01-15
audience: [new-developers, contributors]
tags: [setup, development, tools, getting-started]
---

# Development Setup

Complete guide for setting up a local development environment for the Hackers iOS app.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Project Setup](#project-setup)
- [Development Tools](#development-tools)
- [Build & Run](#build--run)
- [Testing Setup](#testing-setup)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Prerequisites

### System Requirements

- **macOS**: 15.0+ (Sequoia or later)
- **Xcode**: 16.0+ with iOS 26.0 SDK
- **Git**: Latest version
- **Homebrew**: For package management (optional but recommended)

### Required Software

#### 1. Xcode

Install Xcode from the Mac App Store or Apple Developer portal:

```bash
# Check Xcode version
xcodebuild -version

# Expected output:
# Xcode 16.0
# Build version 16A242
```

#### 2. Command Line Tools

```bash
# Install Xcode command line tools
xcode-select --install

# Verify installation
xcode-select -p
# Expected: /Applications/Xcode.app/Contents/Developer
```

#### 3. Git (if not already installed)

```bash
# Check Git version
git --version

# Install via Homebrew if needed
brew install git
```

## Installation

### 1. Clone Repository

```bash
# Clone the repository
git clone https://github.com/weiran/Hackers.git
cd Hackers

# Verify you're on the correct branch
git branch
# Should show: * master
```

### 2. Verify Project Structure

```bash
# Check project structure
ls -la

# Expected structure:
# App/              - Main app target
# Features/         - Feature modules
# Domain/           - Business logic
# Data/             - Data layer
# Networking/       - HTTP client
# DesignSystem/     - UI components
# Shared/           - Cross-cutting concerns
# docs/             - Documentation
# Hackers.xcodeproj - Xcode project file
```

### 3. Open Project

```bash
# Open in Xcode
open Hackers.xcodeproj

# Or use Xcode from command line
xed .
```

## Project Setup

### 1. Dependencies

The project uses **minimal external dependencies**:

- **SwiftSoup**: HTML parsing
- **Drops**: Toast notifications

Dependencies are managed through Swift Package Manager and should resolve automatically when opening the project.

### 2. Build Configuration

#### Verify Build Settings

1. Open Xcode
2. Select "Hackers" project in navigator
3. Check build settings:
   - **iOS Deployment Target**: 26.0
   - **Swift Language Version**: Swift 6
   - **Strict Concurrency Checking**: On

#### Target Configuration

| Setting | Value |
|---------|--------|
| Bundle Identifier | `com.weiranzhang.Hackers` |
| Version | 5.0.0 |
| Build | 135 |
| Deployment Target | iOS 26.0 |
| Swift Version | 6.2 |

### 3. Simulator Setup

Configure iOS Simulator for development:

```bash
# List available simulators
xcrun simctl list devices

# Boot a simulator (example)
xcrun simctl boot "iPhone 17 Pro"

# Or use Xcode: Window > Devices and Simulators
```

**Recommended Test Devices**:
- iPhone 17 Pro (primary)
- iPhone SE (3rd generation) (compact size)
- iPad Pro 13" (iPad layout)

## Development Tools

### 1. SwiftLint (Recommended)

Install SwiftLint for code style enforcement:

```bash
# Install via Homebrew
brew install swiftlint

# Verify installation
swiftlint version

# Run linting
swiftlint
```

### 2. SwiftFormat (Optional)

For automatic code formatting:

```bash
# Install via Homebrew
brew install swiftformat

# Format all Swift files
swiftformat .
```

### 3. GitHub CLI (Optional)

For GitHub integration:

```bash
# Install GitHub CLI
brew install gh

# Authenticate
gh auth login

# Useful commands
gh repo clone weiran/Hackers
gh pr create
gh issue list
```

## Build & Run

### 1. Build Commands

#### Xcode GUI
1. Select "Hackers" scheme
2. Choose target device/simulator
3. Press ⌘+B to build or ⌘+R to run

#### Command Line

```bash
# Clean build
xcodebuild clean build -project Hackers.xcodeproj -scheme Hackers -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Build only
xcodebuild build -project Hackers.xcodeproj -scheme Hackers -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Quick build status check
xcodebuild build -project Hackers.xcodeproj -scheme Hackers -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep "BUILD"
```

### 2. Scheme Configuration

The project includes these schemes:
- **Hackers**: Main app target
- **HackersActionExtension**: Share extension

### 3. Build Troubleshooting

#### Common Issues

**Issue**: "Could not find module 'SwiftSoup'"
```bash
# Solution: Reset package cache
rm -rf ~/Library/Developer/Xcode/DerivedData
# Then rebuild in Xcode
```

**Issue**: "iOS deployment target too low"
```bash
# Solution: Update deployment target
# In Xcode: Project Settings > Deployment Info > iOS 26.0
```

## Testing Setup

### 1. Test Framework

The project uses **Swift Testing** framework (not XCTest):

```swift
import Testing
@testable import Domain

@Suite("Example Tests")
struct ExampleTests {
    @Test("Example test case")
    func exampleTest() {
        #expect(true == true)
    }
}
```

### 2. Running Tests

#### Command Line (Recommended)

```bash
# Run all tests
./run_tests.sh

# Run specific module tests
./run_tests.sh Domain
./run_tests.sh Feed
./run_tests.sh Networking

# Verbose output
./run_tests.sh --verbose
```

#### Xcode

1. Open Test Navigator (⌘+6)
2. Run all tests (⌘+U)
3. Run specific test suites as needed

### 3. Test Coverage

View test coverage in Xcode:
1. Edit Scheme > Test > Options
2. Enable "Code Coverage"
3. Run tests
4. View Report Navigator for coverage details

Current coverage targets:
- Domain: ≥90%
- Data: ≥85%
- Presentation: ≥80%

## Development Workflow

### 1. Branch Strategy

```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make changes, commit
git add .
git commit -m "Add feature description"

# Push to remote
git push origin feature/your-feature-name

# Create pull request via GitHub
```

### 2. Code Style

Follow the [Coding Standards](./coding-standards.md):

```bash
# Run SwiftLint before committing
swiftlint

# Auto-fix some issues
swiftlint --fix
```

### 3. Commit Guidelines

Use conventional commit format:

```bash
# Examples
git commit -m "feat: add voting functionality"
git commit -m "fix: resolve comment parsing issue"
git commit -m "docs: update API documentation"
git commit -m "test: add integration tests for feed"
```

## Troubleshooting

### Build Issues

#### 1. Clean Build Environment

```bash
# Clean Xcode caches
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clean project
xcodebuild clean -project Hackers.xcodeproj -scheme Hackers

# Reset package dependencies
# File > Packages > Reset Package Caches (in Xcode)
```

#### 2. Simulator Issues

```bash
# Reset simulator
xcrun simctl erase all

# Restart simulator
xcrun simctl shutdown booted
xcrun simctl boot "iPhone 17 Pro"
```

#### 3. Git Issues

```bash
# Reset to latest master
git fetch origin
git reset --hard origin/master

# Clean untracked files
git clean -fd
```

### Common Errors

**Error**: "Module compiled with Swift X cannot be imported by Swift Y"
- **Solution**: Clean build folder and rebuild

**Error**: "Could not launch 'Hackers'"
- **Solution**: Reset simulator or try different device

**Error**: "Build input file cannot be found"
- **Solution**: Check file references in Xcode project

## Development Environment

### Recommended Xcode Settings

#### 1. Editor Preferences
- **Font**: SF Mono, 13pt
- **Tab Width**: 4 spaces
- **Indent Width**: 4 spaces
- **Line Endings**: macOS/Unix (LF)

#### 2. Build Settings
- **Build Active Architecture Only**: Yes (Debug)
- **Debug Information Format**: DWARF with dSYM (Release)
- **Swift Compilation Mode**: Incremental (Debug), Whole Module (Release)

#### 3. Behaviors
Set up behaviors for:
- Build starts: Hide navigator
- Build succeeds: Show navigator
- Tests succeed: Show test report

### Debugging Setup

#### 1. Breakpoints
Common breakpoint locations:
- ViewModels: State changes
- Repositories: API calls
- Parsers: HTML processing

#### 2. Instruments
Useful Instruments for this app:
- **Time Profiler**: For scrolling performance
- **Allocations**: For memory leaks
- **Network**: For API call analysis

## Contributing

### 1. Pull Request Process

1. Fork the repository
2. Create feature branch
3. Make changes following coding standards
4. Add/update tests
5. Update documentation if needed
6. Run full test suite
7. Create pull request

### 2. Code Review Checklist

Before submitting:
- [ ] Code follows style guidelines
- [ ] Tests pass and coverage maintained
- [ ] Documentation updated
- [ ] No compiler warnings
- [ ] Performance considerations addressed

### 3. Issue Reporting

When reporting issues:
1. Include iOS version and device model
2. Provide reproduction steps
3. Include relevant logs or screenshots
4. Check for existing similar issues

---

## Quick Start Checklist

For new developers:

- [ ] Install Xcode 16.0+
- [ ] Clone repository
- [ ] Open `Hackers.xcodeproj`
- [ ] Build project (⌘+B)
- [ ] Run tests: `./run_tests.sh`
- [ ] Run app on simulator (⌘+R)
- [ ] Read [Architecture Guide](./architecture.md)
- [ ] Review [Coding Standards](./coding-standards.md)

## Next Steps

After setup:
1. Explore the [Architecture Guide](./architecture.md)
2. Review the [API Reference](./api-reference.md)
3. Check out [Testing Guide](./testing-guide.md)
4. Browse the [Design System](./design-system.md)

---

*If you encounter any setup issues, please check the Troubleshooting section or create an issue on GitHub.*