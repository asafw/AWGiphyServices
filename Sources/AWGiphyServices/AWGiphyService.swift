// AWGiphyService.swift — Concrete type conforming to AWGiphyPhotosProtocol.

import Foundation

/// A ready-to-use Giphy API client.
///
/// Pass a custom `URLSession` at init to intercept requests for testing or
/// to configure timeouts and caching for production.
///
/// ```swift
/// let service = AWGiphyService()
/// let (gifs, _) = try await service.searchGIFs(apiKey: "KEY", request: AWGiphySearchRequest(query: "dogs"))
/// ```
public final class AWGiphyService: AWGiphyPhotosProtocol {

    /// The URLSession used for all network requests.
    public let urlSession: URLSession

    /// Creates a new `AWGiphyService`.
    /// - Parameter urlSession: Defaults to `URLSession.shared`.
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
}
