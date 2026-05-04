# Hackers iOS App Documentation

Welcome to the technical documentation for the Hackers iOS app - a modern, clean architecture implementation for browsing Hacker News.

## 📚 Documentation Overview

This documentation suite is designed to be both human and machine readable, providing comprehensive technical guidance for developers working on the app.

### Quick Navigation

| Document | Description | Audience |
|----------|-------------|----------|
| [Architecture Guide](./architecture.md) | Complete architectural overview and patterns | All developers |
| [API Reference](./api-reference.md) | Domain models, protocols, and interfaces | All developers |
| [Coding Standards](./coding-standards.md) | Conventions, patterns, and best practices | All developers |
| [Design System](./design-system.md) | UI components and design guidelines | Frontend developers |
| [Testing Guide](./testing-guide.md) | Testing strategies and test running | All developers |
| [Development Setup](./development-setup.md) | Local development and tooling | New developers |
| [Release Process](./release-process.md) | TestFlight release workflow and operational runbook | Maintainers |

## 🏗️ Architecture at a Glance

The app follows **Clean Architecture** principles with these layers:

```
┌─ App (Main Target)
├─ Features/ (SwiftUI Views + ViewModels)
│  ├─ Feed
│  ├─ Comments
│  ├─ Settings
│  └─ Onboarding
├─ DesignSystem (Reusable UI Components)
├─ Shared (Navigation, DI Container)
├─ Domain (Business Logic, Use Cases)
├─ Data (Repository Implementations)
└─ Networking (HTTP Client)
```

## 🚀 Current Status

- **Architecture**: ✅ Clean Architecture fully implemented
- **UI Framework**: ✅ SwiftUI with modern patterns
- **Swift Version**: ✅ Swift 6.2 with strict concurrency
- **iOS Target**: ✅ iOS 26+
- **Testing**: ✅ Swift Testing framework (100+ tests)
- **Build System**: ✅ Swift Package Manager modules

## 📖 Getting Started

1. **New Developers**: Start with [Development Setup](./development-setup.md)
2. **Understanding the Codebase**: Read [Architecture Guide](./architecture.md)
3. **Contributing**: Review [Coding Standards](./coding-standards.md)
4. **Building Features**: Check [Design System](./design-system.md)
5. **Writing Tests**: Follow [Testing Guide](./testing-guide.md)

## 🤖 Machine-Readable Documentation

This documentation includes structured metadata for automated tools:

- **JSON schemas** for API contracts
- **Mermaid diagrams** for architecture visualization
- **YAML frontmatter** for document metadata
- **OpenAPI specs** for internal service contracts

## 📄 Document Status

| Document | Last Updated | Version | Status |
|----------|-------------|---------|---------|
| README.md | 2025-09-15 | 1.0.0 | ✅ Current |
| architecture.md | 2025-09-15 | 1.0.0 | ✅ Current |
| api-reference.md | 2025-09-15 | 1.0.0 | ✅ Current |
| coding-standards.md | 2025-09-15 | 1.0.0 | ✅ Current |
| design-system.md | 2025-09-15 | 1.0.0 | ✅ Current |
| testing-guide.md | 2025-09-15 | 1.0.0 | ✅ Current |
| development-setup.md | 2025-09-15 | 1.0.0 | ✅ Current |
| release-process.md | 2026-05-04 | 1.0.0 | ✅ Current |

---

*Documentation generated for Hackers iOS App v5.0.0 (Build 135)*
