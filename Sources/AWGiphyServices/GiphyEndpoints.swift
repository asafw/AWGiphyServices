// GiphyEndpoints.swift — Internal URL and path constants for the Giphy REST API.

/// Namespace for Giphy REST API URL constants.
/// Caseless enum — not intended to be instantiated.
enum GiphyEndpoints {
    static let baseURL = "https://api.giphy.com/v1/gifs"
    static let searchPath = "/search"
    static let trendingPath = "/trending"
    static let randomPath = "/random"
}
