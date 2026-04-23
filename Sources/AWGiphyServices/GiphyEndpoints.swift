// GiphyEndpoints.swift — Internal URL and path constants for the Giphy REST API.

/// Namespace for Giphy REST API URL constants.
/// Caseless enum — not intended to be instantiated.
enum GiphyEndpoints {
    // All v1 GIF endpoints share this base. Path segments or query parameters
    // are appended per-endpoint in GiphyAPIService.
    static let baseURL      = "https://api.giphy.com/v1/gifs"
    // GET /v1/gifs/search  — keyword search
    static let searchPath   = "/search"
    // GET /v1/gifs/trending — editorial trending feed
    static let trendingPath = "/trending"
    // GET /v1/gifs/random  — single random GIF (different response schema: flat URL fields, no `images`)
    static let randomPath   = "/random"
}
