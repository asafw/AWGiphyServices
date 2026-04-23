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
| `AWGiphyGIF` | `id, title, slug, url, rating, username, images: AWGiphyImages` |
| `AWGiphyImages` | `fixedHeight, fixedHeightStill, fixedHeightSmall, fixedWidth, fixedWidthStill, original, downsized` (all `AWGiphyRendition`) |
| `AWGiphyRendition` | `url?, mp4?, webp?, width?, height?` (all optional strings) |
| `AWGiphyPagination` | `count, offset, totalCount?` |
| `AWGiphySearchRequest` | `query: String`, `limit: Int = 25`, `offset: Int = 0`, `rating: String?` |
| `AWGiphyTrendingRequest` | `limit: Int = 25`, `offset: Int = 0`, `rating: String?` |
| `AWGiphyAPIError` | `.networkError`, `.parsingError`, `.apiError(code: Int, message: String)` |

---

## Test counts

- Unit tests: 40 (across 8 suites)
- Integration tests: 9 (skipped when GIPHY_API_KEY absent or CI env set)

### Unit test suites

| Suite | Count |
|---|---|
| `GiphyEndpointsTests` | 3 |
| `AWGiphyGIFTests` | 11 |
| `AWGiphyPaginationTests` | 1 |
| `AWGiphySearchRequestTests` | 2 |
| `AWGiphyTrendingRequestTests` | 1 |
| `GiphyAPIServiceTests` | 13 |
| `AWGiphyPhotosProtocolTests` | 2 |
| `AWGiphyServiceTests` | 3 |
| `AWGiphyAPIErrorTests` | 4 |

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
| 5d4b1bb | feat: initial AWGiphyServices package |
