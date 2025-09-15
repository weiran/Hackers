---
title: Design System
version: 1.0.0
lastUpdated: 2025-09-15
audience: [developers, designers]
tags: [design-system, ui, swiftui, components]
---

# Design System

The Hackers app design system provides reusable UI components, styling guidelines, and design patterns that ensure consistency across the application.

## 📋 Table of Contents

- [Overview](#overview)
- [Design Principles](#design-principles)
- [Color System](#color-system)
- [Typography](#typography)
- [Spacing System](#spacing-system)
- [Components](#components)
- [Layout Patterns](#layout-patterns)
- [Icons & Images](#icons--images)
- [Accessibility](#accessibility)

## Overview

### Design Philosophy

The Hackers app design system follows **iOS Human Interface Guidelines** with these core principles:

- **Clarity**: Clean, readable interface with clear hierarchy
- **Deference**: Content is king - UI supports, doesn't compete
- **Depth**: Layers and motion provide visual hierarchy
- **Accessibility**: Inclusive design for all users
- **Performance**: Optimized for smooth scrolling and interaction

### System Architecture

```
DesignSystem/
├── Sources/DesignSystem/
│   ├── Components/          # Reusable UI components
│   ├── Styles/             # Colors, fonts, spacing
│   ├── Extensions/         # SwiftUI extensions
│   └── Modifiers/          # Custom view modifiers
└── Tests/DesignSystemTests/
```

## Design Principles

### 1. Content-First Design

The interface prioritizes Hacker News content with minimal visual noise.

```swift
// ✅ Clean, content-focused design
VStack(alignment: .leading, spacing: .medium) {
    Text(post.title)
        .font(.headline)
        .foregroundColor(.primary)

    HStack {
        Text(post.author)
            .font(.caption)
            .foregroundColor(.secondary)

        Spacer()

        Text(post.timeAgo)
            .font(.caption)
            .foregroundColor(.secondary)
    }
}
```

### 2. Consistent Interaction Patterns

Standard iOS patterns for familiar user experience:

- **Tap**: Primary actions (open post, navigate)
- **Long Press**: Context menus (share, save)
- **Swipe**: Secondary actions (vote, collapse)
- **Pull-to-Refresh**: Content updates

### 3. Adaptive Design

Responsive layouts that work across iPhone and iPad:

```swift
NavigationSplitView {
    // Sidebar (iPad) / Full screen (iPhone)
    FeedView()
} detail: {
    // Detail view (iPad) / Navigation (iPhone)
    if let selectedPost = navigationStore.selectedPost {
        CommentsView(post: selectedPost)
    } else {
        EmptyStateView()
    }
}
```

## Color System

### Primary Colors

```swift
public enum AppColors {
    static let primary = Color.accentColor
    static let secondary = Color.secondary
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)
}
```

### Semantic Colors

| Color Token | Light Mode | Dark Mode | Usage |
|-------------|------------|-----------|-------|
| `primary` | Blue | Blue | Links, primary actions |
| `secondary` | Gray | Light Gray | Metadata, captions |
| `background` | White | Black | Main backgrounds |
| `secondaryBackground` | Light Gray | Dark Gray | Cards, sections |
| `success` | Green | Green | Upvote indicators |
| `warning` | Orange | Orange | Alert states |
| `error` | Red | Red | Error states |

### Usage Examples

```swift
// ✅ Good: Use semantic colors
Text(post.title)
    .foregroundColor(.primary)

Text(post.author)
    .foregroundColor(.secondary)

Rectangle()
    .fill(AppColors.secondaryBackground)

// ❌ Avoid: Hard-coded colors
Text(post.title)
    .foregroundColor(.blue)  // Use .primary instead
```

## Typography

### Font Scale

The app uses **Dynamic Type** with custom scaling for optimal readability:

```swift
public extension Font {
    static let largeTitle = Font.largeTitle
    static let title = Font.title
    static let title2 = Font.title2
    static let title3 = Font.title3
    static let headline = Font.headline
    static let body = Font.body
    static let callout = Font.callout
    static let subheadline = Font.subheadline
    static let footnote = Font.footnote
    static let caption = Font.caption
    static let caption2 = Font.caption2
}
```

### Typography Usage

| Element | Font Style | Weight | Usage |
|---------|------------|--------|-------|
| Post Title | `.headline` | Regular | Main post titles |
| Comment Text | `.body` | Regular | Comment content |
| Author Name | `.caption` | Medium | Usernames |
| Metadata | `.caption2` | Regular | Timestamps, scores |
| Navigation | `.title2` | Semibold | Section headers |

### Text Scaling Support

```swift
// ✅ Support user text size preferences
struct SettingsView: View {
    @AppStorage("textSize") private var textSize: TextSize = .medium

    var body: some View {
        Text(content)
            .font(.body)
            .scaleEffect(textSize.scale)
    }
}

public enum TextSize: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"

    var scale: CGFloat {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.15
        case .extraLarge: return 1.3
        }
    }
}
```

## Spacing System

### Spacing Scale

Consistent spacing based on 4pt grid system:

```swift
public extension CGFloat {
    static let xxxs: CGFloat = 2    // 2pt
    static let xxs: CGFloat = 4     // 4pt
    static let xs: CGFloat = 8      // 8pt
    static let sm: CGFloat = 12     // 12pt
    static let md: CGFloat = 16     // 16pt (base unit)
    static let lg: CGFloat = 24     // 24pt
    static let xl: CGFloat = 32     // 32pt
    static let xxl: CGFloat = 48    // 48pt
    static let xxxl: CGFloat = 64   // 64pt
}
```

### Spacing Usage

```swift
// ✅ Good: Use semantic spacing
VStack(spacing: .md) {
    Text(title)
    Text(subtitle)
}
.padding(.md)

// ❌ Avoid: Magic numbers
VStack(spacing: 16) {  // Use .md instead
    Text(title)
    Text(subtitle)
}
.padding(16)  // Use .md instead
```

## Components

### PostDisplayView

Primary component for displaying post information:

```swift
public struct PostDisplayView: View {
    let post: Post
    let onTap: (() -> Void)?
    let onUpvote: (() -> Void)?

    public var body: some View {
        VStack(alignment: .leading, spacing: .sm) {
            // Title
            Text(post.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(3)

            // Metadata
            HStack {
                Text(post.author)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("•")
                    .foregroundColor(.secondary)

                Text(post.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if post.commentCount > 0 {
                    Label("\(post.commentCount)", systemImage: "bubble.left")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // URL if available
            if let url = post.url {
                Text(url.host ?? "")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.md)
        .background(AppColors.secondaryBackground)
        .cornerRadius(.md)
        .onTapGesture {
            onTap?()
        }
    }
}
```

### ThumbnailView

Async image loading component with fallback:

```swift
public struct ThumbnailView: View {
    let url: URL?
    let size: CGSize

    public var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(AppColors.secondaryBackground)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundColor(.secondary)
                }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .cornerRadius(.xs)
    }
}
```

### LoadingStateView

Standardized loading states across the app:

```swift
public struct LoadingStateView<Content: View, T>: View {
    let state: LoadingState<T>
    @ViewBuilder let content: (T) -> Content
    @ViewBuilder let emptyState: () -> Content
    let onRetry: (() -> Void)?

    public var body: some View {
        switch state {
        case .idle:
            emptyState()

        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let data):
            content(data)

        case .error(let error):
            ErrorStateView(
                error: error,
                onRetry: onRetry
            )
        }
    }
}
```

### ErrorStateView

Error handling component with retry functionality:

```swift
public struct ErrorStateView: View {
    let error: Error
    let onRetry: (() -> Void)?

    public var body: some View {
        VStack(spacing: .lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("Something went wrong")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let onRetry = onRetry {
                Button("Try Again", action: onRetry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.xl)
    }
}
```

### CommentRowView

Component for displaying individual comments:

```swift
public struct CommentRowView: View {
    let comment: Comment
    let onUpvote: (() -> Void)?
    let onToggleCollapse: (() -> Void)?

    public var body: some View {
        VStack(alignment: .leading, spacing: .sm) {
            // Header
            HStack {
                Text(comment.author)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(comment.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                if comment.children.count > 0 {
                    Button(action: { onToggleCollapse?() }) {
                        Image(systemName: comment.isVisible ? "minus.circle" : "plus.circle")
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Content
            if comment.isVisible {
                Text(comment.text)
                    .font(.body)
                    .textSelection(.enabled)
            }
        }
        .padding(.leading, CGFloat(comment.level) * .lg)
        .padding(.vertical, .xs)
        .swipeActions(edge: .leading) {
            if let onUpvote = onUpvote {
                Button("Upvote", action: onUpvote)
                    .tint(.green)
            }
        }
    }
}
```

## Layout Patterns

### List Layouts

```swift
// ✅ Lazy loading for performance
LazyVStack(spacing: .sm) {
    ForEach(posts) { post in
        PostDisplayView(post: post)
    }
}
.padding(.horizontal, .md)

// ✅ Section grouping
List {
    Section("Recent") {
        ForEach(recentPosts) { post in
            PostRowView(post: post)
        }
    }

    Section("Earlier") {
        ForEach(olderPosts) { post in
            PostRowView(post: post)
        }
    }
}
.listStyle(.grouped)
```

### Navigation Patterns

```swift
// ✅ Split view for iPad, stack for iPhone
NavigationSplitView {
    SidebarView()
} detail: {
    DetailView()
}

// ✅ Standard navigation stack
NavigationStack(path: $navigationPath) {
    FeedView()
        .navigationDestination(for: Post.self) { post in
            CommentsView(post: post)
        }
}
```

## Icons & Images

### System Icons

Prefer SF Symbols for consistency:

```swift
// ✅ Good: SF Symbols
Image(systemName: "arrow.up")        // Upvote
Image(systemName: "bubble.left")     // Comments
Image(systemName: "square.and.arrow.up") // Share
Image(systemName: "person.circle")   // User profile

// ✅ Contextual sizing
Image(systemName: "heart.fill")
    .font(.title2)  // Match surrounding text
```

### Custom Images

```swift
// ✅ Asset catalog images
Image("app-icon")
    .resizable()
    .frame(width: 44, height: 44)

// ✅ Async web images
AsyncImage(url: thumbnailURL) { image in
    image
        .resizable()
        .aspectRatio(contentMode: .fill)
} placeholder: {
    ProgressView()
}
```

## Accessibility

### VoiceOver Support

```swift
// ✅ Good: Descriptive accessibility labels
Button(action: upvote) {
    Image(systemName: "arrow.up")
}
.accessibilityLabel("Upvote post")
.accessibilityHint("Double tap to upvote this post")

// ✅ Group related content
VStack {
    Text(post.title)
    Text(post.author)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(post.title) by \(post.author)")
```

### Dynamic Type Support

```swift
// ✅ Scalable text
Text(content)
    .font(.body)
    .dynamicTypeSize(.small ... .xxxLarge)

// ✅ Scalable layouts
HStack {
    VStack { /* Content */ }
}
.dynamicTypeSize(.small ... .large) {
    // Horizontal layout for smaller text
} else: {
    // Vertical layout for larger text
    VStack { /* Content */ }
}
```

### Color Contrast

All color combinations meet WCAG AA standards:
- Text on background: 4.5:1 minimum
- Large text on background: 3:1 minimum
- Interactive elements: Clear focus indicators

---

## Usage Guidelines

### Do's ✅

- Use semantic spacing tokens (`.md`, `.lg`)
- Implement proper accessibility labels
- Support Dynamic Type scaling
- Use system colors for dark mode compatibility
- Test across different device sizes
- Follow iOS Human Interface Guidelines

### Don'ts ❌

- Hard-code spacing or colors
- Ignore accessibility requirements
- Create custom components without design system approval
- Use non-system fonts without justification
- Skip testing on different accessibility settings

---

*For component usage examples, see the respective source files in the DesignSystem module.*