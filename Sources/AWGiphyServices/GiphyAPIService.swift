// GiphyAPIService.swift — Internal HTTP layer for AWGiphyServices.

import Foundation

/// Internal service that performs all HTTP calls to the Giphy REST API.
/// Not part of the public API — consumers interact via `AWGiphyPhotosProtocol`.
struct GiphyAPIService {

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
        let url = try generateURL(path: "/\(id)", params: ["api_key": apiKey])
        let envelope: GiphySingleEnvelope = try await performRequest(url: url)
        return envelope.data
    }

    func downloadImageData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        try validateHTTPResponse(response)
        return data
    }

    // MARK: - Private helpers

    private func performRequest<T: Decodable>(url: URL) async throws -> T {
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validateHTTPResponse(response)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AWGiphyAPIError.parsingError
        }
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AWGiphyAPIError.networkError
        }
        guard (200...299).contains(http.statusCode) else {
            throw AWGiphyAPIError.apiError(code: http.statusCode, message: HTTPURLResponse.localizedString(forStatusCode: http.statusCode))
        }
    }

    private func generateURL(path: String, params: [String: String]) throws -> URL {
        let urlString = GiphyEndpoints.baseURL + path
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
