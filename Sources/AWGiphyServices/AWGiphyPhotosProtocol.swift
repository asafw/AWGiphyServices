// AWGiphyPhotosProtocol.swift — Public protocol + mixin default implementations.

import Foundation

/// Provides access to the Giphy REST API via protocol extension defaults.
///
/// Conform any Swift type to `AWGiphyPhotosProtocol` and get all methods for free:
///
/// ```swift
/// struct GiphyRepository: AWGiphyPhotosProtocol { }
/// let repo = GiphyRepository()
/// let gifs = try await repo.searchGIFs(apiKey: "KEY", request: AWGiphySearchRequest(query: "cats"))
/// ```
///
/// Override `urlSession` to inject a custom `URLSession` for testing or custom configuration:
///
/// ```swift
/// struct TestRepository: AWGiphyPhotosProtocol {
///     let urlSession: URLSession  // backed by a CapturingURLProtocol
/// }
/// ```
public protocol AWGiphyPhotosProtocol {
    /// The `URLSession` used for all network requests.
    /// Defaults to `URLSession.shared`. Override to inject a custom session.
    var urlSession: URLSession { get }
}

public extension AWGiphyPhotosProtocol {

    var urlSession: URLSession { .shared }

    // Computed (not stored) so it always picks up the current urlSession value.
    // GiphyAPIService is a lightweight struct that holds only a URLSession
    // reference, so constructing one per call has negligible cost.
    private var service: GiphyAPIService { GiphyAPIService(session: urlSession) }

    // MARK: - Search

    /// Search for GIFs matching a query term.
    ///
    /// - Parameters:
    ///   - apiKey: Your Giphy API key.
    ///   - request: Search parameters (query, limit, offset, rating).
    /// - Returns: A tuple of matching GIFs and pagination metadata.
    /// - Throws: `AWGiphyAPIError`
    func searchGIFs(apiKey: String, request: AWGiphySearchRequest) async throws -> ([AWGiphyGIF], AWGiphyPagination) {
        try await service.searchGIFs(apiKey: apiKey, request: request)
    }

    // MARK: - Trending

    /// Fetch the current trending GIFs.
    ///
    /// - Parameters:
    ///   - apiKey: Your Giphy API key.
    ///   - request: Trending parameters (limit, offset, rating).
    /// - Returns: A tuple of trending GIFs and pagination metadata.
    /// - Throws: `AWGiphyAPIError`
    func trendingGIFs(apiKey: String, request: AWGiphyTrendingRequest) async throws -> ([AWGiphyGIF], AWGiphyPagination) {
        try await service.trendingGIFs(apiKey: apiKey, request: request)
    }

    // MARK: - Single GIF

    /// Fetch metadata for a single GIF by its ID.
    ///
    /// - Parameters:
    ///   - apiKey: Your Giphy API key.
    ///   - id: The GIF's unique ID.
    /// - Returns: The matching `AWGiphyGIF`.
    /// - Throws: `AWGiphyAPIError`
    func getGIF(apiKey: String, id: String) async throws -> AWGiphyGIF {
        try await service.getGIF(apiKey: apiKey, id: id)
    }

    // MARK: - Batch fetch

    /// Fetch metadata for multiple GIFs by their IDs in a single request.
    ///
    /// - Parameters:
    ///   - apiKey: Your Giphy API key.
    ///   - ids: An array of GIF IDs to fetch (max 10 per request per Giphy docs).
    /// - Returns: An array of matching `AWGiphyGIF` values (order not guaranteed).
    /// - Throws: `AWGiphyAPIError`
    func getGIFs(apiKey: String, ids: [String]) async throws -> [AWGiphyGIF] {
        try await service.getGIFs(apiKey: apiKey, ids: ids)
    }

    // MARK: - Random GIF

    /// Fetch a single random GIF, optionally filtered by tag.
    ///
    /// - Parameters:
    ///   - apiKey: Your Giphy API key.
    ///   - request: Random GIF parameters (optional tag, optional rating).
    /// - Returns: An `AWGiphyRandomGIF` with direct image URLs.
    /// - Throws: `AWGiphyAPIError`
    func randomGIF(apiKey: String, request: AWGiphyRandomRequest = AWGiphyRandomRequest()) async throws -> AWGiphyRandomGIF {
        try await service.randomGIF(apiKey: apiKey, request: request)
    }

    // MARK: - Image data

    /// Download raw image data from a GIF rendition URL.
    ///
    /// Uses `.returnCacheDataElseLoad` — repeated calls for the same URL skip the network.
    /// Returns `Data`; convert to `UIImage` / `NSImage` yourself.
    ///
    /// - Parameter url: A URL from any `AWGiphyRendition` (`.url`, `.mp4`, `.webp`).
    /// - Returns: Raw data for the image or video file.
    /// - Throws: `AWGiphyAPIError`
    func downloadImageData(from url: URL) async throws -> Data {
        try await service.downloadImageData(from: url)
    }
}
