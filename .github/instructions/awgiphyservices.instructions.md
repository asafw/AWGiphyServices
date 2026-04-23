---
applyTo: "**"
---

# AWGiphyServices — Copilot Instructions

> Maintained automatically. Update via `.github/CONTEXT.md` + `AGENTS.md`
> and re-sync this file at the end of each session.

## Project overview

A dependency-free Swift package for integrating the Giphy REST API in iOS and macOS apps.
Uses a **protocol mixin pattern**: consumers conform to `AWGiphyPhotosProtocol` and gain
full API access through protocol extension default implementations. No subclassing or object
injection required.

Created in 2026. iOS 17+ / macOS 14+, pure `async throws` API, zero external dependencies.

- **Repo:** `asafw/AWGiphyServices` (public) — `~/Desktop/asafw/AWGiphyServices/`
- **Active branch:** `main`
- **Authoritative state:** `.github/CONTEXT.md` — always read before making changes.

---

## Repository layout

```
AWGiphyServices/
├── Sources/AWGiphyServices/
│   ├── AWGiphyAPIError.swift       ← Public error enum
│   ├── AWGiphyModels.swift         ← All public request/response models
│   ├── GiphyEndpoints.swift        ← Internal URL constants (caseless enum)
│   ├── GiphyAPIService.swift       ← Internal HTTP layer
│   ├── AWGiphyPhotosProtocol.swift ← Public protocol + mixin defaults
│   └── AWGiphyService.swift        ← Concrete conforming type
├── Tests/AWGiphyServicesTests/
│   └── AWGiphyServicesTests.swift  ← 40 unit tests (8 suites, CapturingURLProtocol)
├── Tests/AWGiphyServicesIntegrationTests/
│   └── AWGiphyServicesIntegrationTests.swift  ← 9 live tests; skip without key
├── Examples/GiphyDemoApp/          ← SwiftUI demo app (macOS + iOS)
├── Package.swift                   ← swift-tools-version:5.9, iOS 17+, macOS 14+
├── README.md
├── AGENTS.md
└── .github/
    ├── CONTEXT.md
    ├── instructions/awgiphyservices.instructions.md
    └── workflows/  (ios.yml, macos.yml, swift.yml)
```

---

## Types and APIs

### Protocol

| Protocol | Purpose |
|---|---|
| `AWGiphyPhotosProtocol` | GIF search, trending, fetch by ID, image download |

```swift
public protocol AWGiphyPhotosProtocol {
    var urlSession: URLSession { get }   // default: URLSession.shared
}
```

All four methods are declared in the protocol and fully implemented in a `public extension`.

| Method | Signature |
|---|---|
| `searchGIFs(apiKey:request:)` | `async throws -> ([AWGiphyGIF], AWGiphyPagination)` |
| `trendingGIFs(apiKey:request:)` | `async throws -> ([AWGiphyGIF], AWGiphyPagination)` |
| `getGIF(apiKey:id:)` | `async throws -> AWGiphyGIF` |
| `downloadImageData(from:)` | `async throws -> Data` |

### `AWGiphyService`

```swift
public final class AWGiphyService: AWGiphyPhotosProtocol {
    public let urlSession: URLSession
    public init(urlSession: URLSession = .shared)
}
```

### Public models

| Type | Key fields / notes |
|---|---|
| `AWGiphyGIF` | `id, title, slug, url, rating, username, images`; conforms to `Decodable, Hashable, Identifiable, Sendable` |
| `AWGiphyImages` | `fixedHeight, fixedHeightStill, fixedHeightSmall, fixedWidth, fixedWidthStill, original, downsized` (all `AWGiphyRendition`); CodingKeys map `fixed_height` etc. |
| `AWGiphyRendition` | `url?, mp4?, webp?, width?, height?` (all optional strings); conforms to `Decodable, Hashable, Sendable` |
| `AWGiphyPagination` | `count, offset, totalCount?`; CodingKey `total_count → totalCount` |
| `AWGiphySearchRequest` | `query: String`, `limit: Int = 25`, `offset: Int = 0`, `rating: String?` |
| `AWGiphyTrendingRequest` | `limit: Int = 25`, `offset: Int = 0`, `rating: String?` |
| `AWGiphyAPIError` | `.networkError`, `.parsingError`, `.apiError(code: Int, message: String)`; conforms to `Error, Equatable` |

### Internal types (do not expose publicly)

- `GiphyAPIService` — `struct`; `init(session:)`; URL building via `URLComponents`; `performRequest<T: Decodable>` delegates to this
- `GiphyEndpoints` — caseless `enum`; all URL string constants
- `GiphyListEnvelope` — `Decodable`; `data: [AWGiphyGIF]`, `pagination: AWGiphyPagination`
- `GiphySingleEnvelope` — `Decodable`; `data: AWGiphyGIF`

---

## Architecture invariants

- **Zero external dependencies** — `Package.swift` must stay dependency-free.
- **No UIKit dependency** — `downloadImageData(from:)` returns `Data`; callers convert to `UIImage`/`NSImage`.
- **Pure `async throws` API** — all public methods. No completion handlers.
- **Non-2xx → `AWGiphyAPIError.apiError(code:message:)`** — `GiphyAPIService.validateHTTPResponse` enforces this for all endpoints including image download.
- **`URLComponents` for URL building** — all query parameters encoded via `URLQueryItem`.
- **`@Observable` demo app** — `DemoViewModel` uses `@Observable`, no `@Published`. `ContentView` uses `@State private var viewModel = DemoViewModel()`.
- **`NavigationStack` only** — iOS 17+/macOS 14+ minimum; no `NavigationView` fallback.
- **`CapturingURLProtocol`** — unit tests inject an ephemeral `URLSession` with this protocol class; zero real network calls.

---

## Coding conventions

- **One file per type** — each public type has its own Swift file.
- **No imports** — source files use only `Foundation`. No `UIKit`, no `AppKit`.
- **`AW` prefix** — all public types are prefixed `AW` (`AWGiphyGIF`, `AWGiphyService`, etc.).
- **Doc comments** — every `public` type and method must have a `///` doc comment.
- **Tests** — every new public method must have a unit test using `CapturingURLProtocol` and an integration test in `AWGiphyServicesIntegrationTests`.
- **Integration test credentials** — read from `GIPHY_API_KEY` env var or `/tmp/GIPHY_API_KEY` via `readCredential(_:)`; skip with `XCTSkipIf`/`XCTSkip` when absent. Never hardcode.
- **`@discardableResult` not needed** — the API is pure `async throws`.

---

## Build and test

```bash
cd ~/Desktop/asafw/AWGiphyServices

swift build

# Unit tests only (fast, no network)
xcodebuild -scheme AWGiphyServices-Package -destination "platform=macOS" \
    -only-testing:AWGiphyServicesTests test

# All tests (integration tests require GIPHY_API_KEY)
xcodebuild -scheme AWGiphyServices-Package -destination "platform=macOS" test
```

---

## Session end checklist

1. Run unit tests — all must pass.
2. Update `.github/CONTEXT.md`: latest commit hash, test counts, any changed APIs.
3. Update this file if architecture, conventions, or type descriptions changed.
4. Commit both together:
   ```bash
   git add .github/CONTEXT.md .github/instructions/awgiphyservices.instructions.md
   git commit -m "docs(context): update session state"
   git push origin main
   ```
