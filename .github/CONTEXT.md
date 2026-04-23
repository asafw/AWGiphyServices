# AWGiphyServices

A dependency-free Swift Package for integrating the Giphy REST API in iOS and macOS apps.
Uses the protocol mixin pattern — conform to `AWGiphyPhotosProtocol` to get all
functionality via default implementations.

- **Repo:** `asafw/AWGiphyServices` (public) — `~/Desktop/asafw/AWGiphyServices/`
- **Active branch:** `main`

---

## Repository layout

```
AWGiphyServices/
├── Sources/AWGiphyServices/
│   ├── AWGiphyAPIError.swift       ← Public error enum
│   ├── AWGiphyModels.swift         ← All public request/response models
│   ├── GiphyEndpoints.swift        ← Internal URL constants
│   ├── GiphyAPIService.swift       ← Internal HTTP layer
│   ├── AWGiphyPhotosProtocol.swift ← Public protocol + mixin defaults
│   └── AWGiphyService.swift        ← Concrete conforming type
├── Tests/AWGiphyServicesTests/
│   └── AWGiphyServicesTests.swift  ← Unit tests (no network)
├── Tests/AWGiphyServicesIntegrationTests/
│   └── AWGiphyServicesIntegrationTests.swift  ← Live tests (skip when key absent)
├── Examples/GiphyDemoApp/          ← SwiftUI demo app (macOS + iOS)
│   ├── GiphyDemoApp.swift
│   ├── ContentView.swift
│   ├── DemoViewModel.swift
│   ├── GIFGridView.swift
│   └── GIFDetailView.swift
├── Package.swift                   ← swift-tools-version:5.9, iOS 17+, macOS 14+
├── README.md
├── AGENTS.md
└── .github/
    ├── CONTEXT.md
    ├── instructions/
    │   └── awgiphyservices.instructions.md
    └── workflows/
        ├── ios.yml
        ├── macos.yml
        └── swift.yml
```

---

## Types and APIs

### `AWGiphyPhotosProtocol`

```swift
public protocol AWGiphyPhotosProtocol {
    var urlSession: URLSession { get }
}
```

Default `urlSession` is `URLSession.shared`. Override to inject a custom session.

| Method | OAuth required | Signature |
|---|---|---|
| `searchGIFs(apiKey:request:)` | No | `async throws -> ([AWGiphyGIF], AWGiphyPagination)` |
| `trendingGIFs(apiKey:request:)` | No | `async throws -> ([AWGiphyGIF], AWGiphyPagination)` |
| `getGIF(apiKey:id:)` | No | `async throws -> AWGiphyGIF` |
| `getGIFs(apiKey:ids:)` | No | `async throws -> [AWGiphyGIF]` |
| `randomGIF(apiKey:request:)` | No | `async throws -> AWGiphyRandomGIF` |
| `downloadImageData(from:)` | No | `async throws -> Data` |

### `AWGiphyService`

```swift
public final class AWGiphyService: AWGiphyPhotosProtocol {
    public let urlSession: URLSession
    public init(urlSession: URLSession = .shared)
}
```

### Public models

| Type | Key fields |
|---|---|
| `AWGiphyGIF` | `id, title, slug, url, rating, username, images: AWGiphyImages, importDatetime: String?, createDatetime: String?`; conforms to `Decodable, Hashable, Identifiable, Sendable, CustomStringConvertible` |
| `AWGiphyImages` | `fixedHeight, fixedHeightStill, fixedHeightSmall, preview?, fixedWidth, fixedWidthStill, original, downsized` (all `AWGiphyRendition`) |
| `AWGiphyRendition` | `url?, mp4?, webp?, width?, height?` (all optional strings); `widthInt`, `heightInt` computed |
| `AWGiphyPagination` | `count, offset, totalCount?` |
| `AWGiphySearchRequest` | `query: String`, `limit: Int = 25`, `offset: Int = 0`, `rating: String?` |
| `AWGiphyTrendingRequest` | `limit: Int = 25`, `offset: Int = 0`, `rating: String?` |
| `AWGiphyRandomRequest` | `tag: String?`, `rating: String?` |
| `AWGiphyRandomGIF` | `id, title, rating, username, imageUrl?, imageOriginalUrl?`; returned by `/v1/gifs/random` (no `images` object) |
| `AWGiphyAPIError` | `.networkError`, `.parsingError`, `.apiError(code: Int, message: String)` |

---

## Test counts

- Unit tests: 72 (across 11 suites)
- Integration tests: 12 (skipped when GIPHY_API_KEY absent or CI env set)

### Unit test suites

| Suite | Count |
|---|---|
| `GiphyEndpointsTests` | 4 |
| `AWGiphyGIFTests` | 19 |
| `AWGiphyPaginationTests` | 1 |
| `AWGiphySearchRequestTests` | 2 |
| `AWGiphyTrendingRequestTests` | 1 |
| `AWGiphyRandomRequestTests` | 2 |
| `AWGiphyRandomGIFTests` | 5 |
| `GiphyAPIServiceTests` | 23 |
| `AWGiphyPhotosProtocolTests` | 2 |
| `AWGiphyServiceTests` | 3 |
| `AWGiphyAPIErrorTests` | 9 |

---

## Build commands

```bash
cd ~/Desktop/asafw/AWGiphyServices

swift build

# Unit tests (macOS, fast, no network)
xcodebuild -scheme AWGiphyServices-Package -destination "platform=macOS" \
    -only-testing:AWGiphyServicesTests test

# All tests
xcodebuild -scheme AWGiphyServices-Package -destination "platform=macOS" test
```

---

## Commit history

| Hash | Message |
|---|---|
| f8073e5 | docs: add inline reasoning comments to all non-trivial internals |
| 7886084 | feat: add getGIFs(ids:), randomGIF, preview rendition, dates, CustomStringConvertible |
| 4a8c696 | feat: improve macOS screenshot wait times; real GIF loaded in detail |
| bc1056c | feat: real macOS screenshots (cat search); remove stale macos_gif_grid |
| d2a0f11 | feat: real-API screenshots (cat search); keyboard dismiss fix; AUTO_SEARCH seam |
| c10394f | docs: add screenshot section to README; add iOS/macOS demo app screenshots |
