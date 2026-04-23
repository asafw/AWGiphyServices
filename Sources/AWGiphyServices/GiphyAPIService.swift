// GiphyAPIService.swift — Internal HTTP layer for AWGiphyServices.

import Foundation

/// Internal service that performs all HTTP calls to the Giphy REST API.
/// Not part of the public API — consumers interact via `AWGiphyPhotosProtocol`.
struct GiphyAPIService: Sendable {

    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public endpoints

    func searchGIFs(apiKey: String, request: AWGiphySearchRequest) async throws -> ([AWGiphyGIF], AWGiphyPagination) {
        var params: [String: String] = [
            "api_key": apiKey,
            "q":       request.query,
            "limit":   String(request.limit),
            "offset":  String(request.offset),
        ]
        if let rating = request.rating { params["rating"] = rating }
        let url = try generateURL(path: GiphyEndpoints.searchPath, params: params)
        let envelope: GiphyListEnvelope = try await performRequest(url: url)
        return (envelope.data, envelope.pagination)
    }

    func trendingGIFs(apiKey: String, request: AWGiphyTrendingRequest) async throws -> ([AWGiphyGIF], AWGiphyPagination) {
        var params: [String: String] = [
            "api_key": apiKey,
            "limit":   String(request.limit),
            "offset":  String(request.offset),
        ]
        if let rating = request.rating { params["rating"] = rating }
        let url = try generateURL(path: GiphyEndpoints.trendingPath, params: params)
        let envelope: GiphyListEnvelope = try await performRequest(url: url)
        return (envelope.data, envelope.pagination)
    }

    func getGIF(apiKey: String, id: String) async throws -> AWGiphyGIF {
        // Percent-encode the ID before inserting it as a URL path segment.
        // Without this, characters such as '?', '#', or spaces in an ID
        // would be misinterpreted as query-string delimiters or fragment
        // markers, breaking the request URL.
        guard let encodedID = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw AWGiphyAPIError.parsingError
        }
        let url = try generateURL(path: "/\(encodedID)", params: ["api_key": apiKey])
        let envelope: GiphySingleEnvelope = try await performRequest(url: url)
        return envelope.data
    }

    func getGIFs(apiKey: String, ids: [String]) async throws -> [AWGiphyGIF] {
        // The Giphy batch endpoint is the base URL itself (no extra path segment).
        // IDs are passed as a comma-separated 'ids' query parameter.
        // Example: GET https://api.giphy.com/v1/gifs?api_key=KEY&ids=abc,def
        let url = try generateURL(path: "", params: [
            "api_key": apiKey,
            "ids": ids.joined(separator: ","),
        ])
        let envelope: GiphyMultiEnvelope = try await performRequest(url: url)
        return envelope.data
    }

    func randomGIF(apiKey: String, request: AWGiphyRandomRequest) async throws -> AWGiphyRandomGIF {
        var params: [String: String] = ["api_key": apiKey]
        // Guard against both nil and empty-string tags: callers may pass
        // AWGiphyRandomRequest(tag: "") to mean "no filter", and sending
        // tag= to Giphy returns a 400 error.
        if let tag = request.tag, !tag.isEmpty { params["tag"] = tag }
        if let rating = request.rating { params["rating"] = rating }
        let url = try generateURL(path: GiphyEndpoints.randomPath, params: params)
        let envelope: GiphyRandomEnvelope = try await performRequest(url: url)
        return envelope.data
    }

    func downloadImageData(from url: URL) async throws -> Data {
        // Cache-first policy: if the same image URL was already fetched during
        // this process lifetime, return the cached bytes without a network
        // round-trip. Giphy rendition URLs are content-addressed and stable,
        // so serving stale cache data is always correct.
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        request.httpMethod = "GET"
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AWGiphyAPIError.networkError
        }
        try validateHTTPResponse(response)
        return data
    }

    // MARK: - Private helpers

    // Shared across all requests. JSONDecoder is a class but is not mutated
    // after creation, so sharing it across concurrent calls is safe and avoids
    // the small but non-zero per-request allocation cost of creating a new instance.
    private static let decoder = JSONDecoder()

    // Generic request helper — all JSON endpoints go through here.
    // URLSession errors (no connectivity, timeout, cancelled) are caught and
    // unified into AWGiphyAPIError.networkError so callers handle one error type.
    private func performRequest<T: Decodable>(url: URL) async throws -> T {
        let request = URLRequest(url: url)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AWGiphyAPIError.networkError
        }
        try validateHTTPResponse(response)
        do {
            return try GiphyAPIService.decoder.decode(T.self, from: data)
        } catch {
            // Remap Swift's opaque DecodingError into a single typed case so
            // callers do not need to import or pattern-match Foundation types.
            throw AWGiphyAPIError.parsingError
        }
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        // URLSession can theoretically return non-HTTP responses (e.g. file://
        // schemes used in tests). Casting guards against that defensively;
        // in production all Giphy requests are HTTPS.
        guard let http = response as? HTTPURLResponse else {
            throw AWGiphyAPIError.networkError
        }
        guard (200...299).contains(http.statusCode) else {
            throw AWGiphyAPIError.apiError(
                code: http.statusCode,
                message: HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            )
        }
    }

    private func generateURL(path: String, params: [String: String]) throws -> URL {
        let urlString = GiphyEndpoints.baseURL + path
        // URLComponents is used rather than manual string concatenation because it
        // correctly percent-encodes query-parameter values that contain spaces,
        // ampersands, equals signs, or other reserved characters — preventing both
        // malformed URLs and URL-injection through user-supplied query strings.
        guard let baseURL = URL(string: urlString),
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        else {
            throw AWGiphyAPIError.parsingError
        }
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components.url else {
            throw AWGiphyAPIError.parsingError
        }
        return url
    }
}
