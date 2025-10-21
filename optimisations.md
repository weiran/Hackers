## Comments Screen Performance Optimisations

### 1. Move Comment Fetching off the Main Actor
- **Problem**: `LoadingStateManager.performLoad()` runs under `@MainActor`, so `CommentsViewModel.fetchComments()` performs HTML downloads and parsing on the main thread, stalling the UI for ~7 s (`Shared/Sources/Shared/LoadingStateManager.swift`).
- **Improvement**: Run `loadData` inside a detached task (or drop `@MainActor` until the data is ready) and hop back to `MainActor` only to publish state. This frees the UI thread while comments load.

### 2. Avoid Re-parsing the Post HTML
- **Problem**: `PostRepository.makePost` calls `comments(from:)` with the raw HTML, causing SwiftSoup to parse the entire document a second time (~2.7 s) even though a `Document` was already created (`Data/Sources/Data/PostRepository.swift`, `Data/Sources/Data/PostRepository+Parsing.swift`).
- **Improvement**: Pass the existing `Document` (or the `.comtr` nodes) down to `makePost`/`comments(from:)` so the expensive parse happens only once.

### 3. Reduce SwiftUI Layout Churn
- **Problem**: The first render of 1 000+ `CommentRow`s triggers ~0.8 s in `GraphHost.flushTransactions`, amplified by each row’s `GeometryReader` updating `visibleCommentPositions` (`Features/Comments/Sources/Comments/CommentsComponents.swift`).
- **Improvement**: Throttle or relocate the geometry tracking (e.g. aggregate updates higher in the tree or gate them by scroll state) to prevent per-frame dictionary writes and preference changes for every row.

### 4. Cache Comment Typography
- **Problem**: Each row builds a fresh `CommentFontProvider`, and base attributed strings are re-styled on every render (~60 ms total per pass) (`Features/Comments/Sources/Comments/CommentsComponents.swift`).
- **Improvement**: Cache the font sets per text-scaling value and persist fully styled `AttributedString`s when comments load, letting rows reuse them during scrolling.

### 5. Streamline Vote Link Extraction
- **Problem**: `PostRepository.voteLinks(from:)` repeatedly queries the DOM, showing up as ~0.5 s in the latest trace (`Data/Sources/Data/PostRepository+Voting.swift`).
- **Improvement**: Collect link candidates once and scan them in a single pass for the various id/text checks.

### 6. Optional: Parallelise Heavy Parsing
- **Problem**: `CommentHTMLParser.parseHTMLText` shows up when loading many comments.
- **Improvement**: If needed after the above, process comment bodies off the main actor (e.g. in the same detached task) or deliver comments in batches so the UI can start rendering sooner.
