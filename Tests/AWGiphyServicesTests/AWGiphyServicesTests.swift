// AWGiphyServicesTests.swift — Unit tests for AWGiphyServices (zero network).

import XCTest
@testable import AWGiphyServices

// MARK: - CapturingURLProtocol

/// A URLProtocol subclass that intercepts all requests and returns stubbed data.
/// Register it on an ephemeral URLSession and inject that session via `urlSession`.
final class CapturingURLProtocol: URLProtocol {
    static var stubbedData: Data = Data()
    static var stubbedStatusCode: Int = 200
    static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        CapturingURLProtocol.lastRequest = request
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: CapturingURLProtocol.stubbedStatusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: CapturingURLProtocol.stubbedData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

/// A URLProtocol that always fails with a URLError, simulating no connectivity.
final class FailingURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
    }
    override func stopLoading() {}
}

// MARK: - Test helpers

private func makeSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [CapturingURLProtocol.self]
    return URLSession(configuration: config)
}

private struct StubService: AWGiphyPhotosProtocol {
    let urlSession: URLSession
}

private func stub(json: String, statusCode: Int = 200) -> StubService {
    CapturingURLProtocol.stubbedData = json.data(using: .utf8)!
    CapturingURLProtocol.stubbedStatusCode = statusCode
    CapturingURLProtocol.lastRequest = nil
    return StubService(urlSession: makeSession())
}

// MARK: - Sample JSON

private let sampleGIF = """
{
  "id": "abc123",
  "title": "Funny Cat",
  "slug": "funny-cat-abc123",
  "url": "https://giphy.com/gifs/funny-cat-abc123",
  "rating": "g",
  "username": "testuser",
  "images": {
    "fixed_height": {"url": "https://media.giphy.com/media/abc123/200.gif", "mp4": "https://media.giphy.com/media/abc123/200.mp4", "webp": null, "width": "267", "height": "200"},
    "fixed_height_still": {"url": "https://media.giphy.com/media/abc123/200_s.gif", "mp4": null, "webp": null, "width": "267", "height": "200"},
    "fixed_height_small": {"url": "https://media.giphy.com/media/abc123/100.gif", "mp4": null, "webp": null, "width": "133", "height": "100"},
    "fixed_width": {"url": "https://media.giphy.com/media/abc123/200w.gif", "mp4": null, "webp": null, "width": "200", "height": "150"},
    "fixed_width_still": {"url": "https://media.giphy.com/media/abc123/200w_s.gif", "mp4": null, "webp": null, "width": "200", "height": "150"},
    "original": {"url": "https://media.giphy.com/media/abc123/giphy.gif", "mp4": "https://media.giphy.com/media/abc123/giphy.mp4", "webp": null, "width": "480", "height": "360"},
    "downsized": {"url": "https://media.giphy.com/media/abc123/giphy-downsized.gif", "mp4": null, "webp": null, "width": "480", "height": "360"}
  }
}
"""

private let sampleListJSON = """
{
  "data": [\(sampleGIF)],
  "pagination": {"count": 1, "offset": 0, "total_count": 100}
}
"""

private let sampleSingleJSON = """
{"data": \(sampleGIF)}
"""

// MARK: - GiphyEndpointsTests

final class GiphyEndpointsTests: XCTestCase {
    func testBaseURL() {
        XCTAssertEqual(GiphyEndpoints.baseURL, "https://api.giphy.com/v1/gifs")
    }

    func testSearchPath() {
        XCTAssertEqual(GiphyEndpoints.searchPath, "/search")
    }

    func testTrendingPath() {
        XCTAssertEqual(GiphyEndpoints.trendingPath, "/trending")
    }
}

// MARK: - AWGiphyGIFTests

final class AWGiphyGIFTests: XCTestCase {

    private var gif: AWGiphyGIF!

    override func setUp() {
        super.setUp()
        gif = try! JSONDecoder().decode(AWGiphyGIF.self, from: sampleGIF.data(using: .utf8)!)
    }

    func testIDDecoded() { XCTAssertEqual(gif.id, "abc123") }
    func testTitleDecoded() { XCTAssertEqual(gif.title, "Funny Cat") }
    func testSlugDecoded() { XCTAssertEqual(gif.slug, "funny-cat-abc123") }
    func testRatingDecoded() { XCTAssertEqual(gif.rating, "g") }
    func testUsernameDecoded() { XCTAssertEqual(gif.username, "testuser") }

    func testFixedHeightURL() {
        XCTAssertEqual(gif.images.fixedHeight.url, "https://media.giphy.com/media/abc123/200.gif")
    }

    func testFixedHeightMp4() {
        XCTAssertEqual(gif.images.fixedHeight.mp4, "https://media.giphy.com/media/abc123/200.mp4")
    }

    func testOriginalURL() {
        XCTAssertEqual(gif.images.original.url, "https://media.giphy.com/media/abc123/giphy.gif")
    }

    func testDownsizedURL() {
        XCTAssertEqual(gif.images.downsized.url, "https://media.giphy.com/media/abc123/giphy-downsized.gif")
    }

    func testNilWebpDecodedAsNil() {
        XCTAssertNil(gif.images.fixedHeight.webp)
    }

    func testIdentifiable() {
        // AWGiphyGIF.id is the Identifiable identifier
        let gifs = [gif!]
        XCTAssertEqual(gifs.first(where: { $0.id == "abc123" })?.title, "Funny Cat")
    }
}

// MARK: - AWGiphyPaginationTests

final class AWGiphyPaginationTests: XCTestCase {
    func testPaginationDecoded() throws {
        let envelope = try JSONDecoder().decode(GiphyListEnvelope.self, from: sampleListJSON.data(using: .utf8)!)
        XCTAssertEqual(envelope.pagination.count, 1)
        XCTAssertEqual(envelope.pagination.offset, 0)
        XCTAssertEqual(envelope.pagination.totalCount, 100)
    }
}

// MARK: - AWGiphySearchRequestTests

final class AWGiphySearchRequestTests: XCTestCase {
    func testDefaults() {
        let req = AWGiphySearchRequest(query: "cats")
        XCTAssertEqual(req.query, "cats")
        XCTAssertEqual(req.limit, 25)
        XCTAssertEqual(req.offset, 0)
        XCTAssertNil(req.rating)
    }

    func testCustomValues() {
        let req = AWGiphySearchRequest(query: "dogs", limit: 10, offset: 20, rating: "pg")
        XCTAssertEqual(req.limit, 10)
        XCTAssertEqual(req.offset, 20)
        XCTAssertEqual(req.rating, "pg")
    }
}

// MARK: - AWGiphyTrendingRequestTests

final class AWGiphyTrendingRequestTests: XCTestCase {
    func testDefaults() {
        let req = AWGiphyTrendingRequest()
        XCTAssertEqual(req.limit, 25)
        XCTAssertEqual(req.offset, 0)
        XCTAssertNil(req.rating)
    }
}

// MARK: - GiphyAPIServiceTests

final class GiphyAPIServiceTests: XCTestCase {

    // MARK: searchGIFs

    func testSearchGIFsReturnsGIFs() async throws {
        let service = stub(json: sampleListJSON)
        let (gifs, pagination) = try await service.searchGIFs(
            apiKey: "test_key",
            request: AWGiphySearchRequest(query: "cats")
        )
        XCTAssertEqual(gifs.count, 1)
        XCTAssertEqual(gifs[0].id, "abc123")
        XCTAssertEqual(pagination.totalCount, 100)
    }

    func testSearchGIFsURLContainsQuery() async throws {
        let service = stub(json: sampleListJSON)
        _ = try await service.searchGIFs(apiKey: "KEY", request: AWGiphySearchRequest(query: "space cats"))
        let url = CapturingURLProtocol.lastRequest?.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains("q=space%20cats") || url.contains("q=space+cats"), "URL should encode query: \(url)")
    }

    func testSearchGIFsURLContainsApiKey() async throws {
        let service = stub(json: sampleListJSON)
        _ = try await service.searchGIFs(apiKey: "MYKEY", request: AWGiphySearchRequest(query: "cats"))
        let url = CapturingURLProtocol.lastRequest?.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains("api_key=MYKEY"), "URL should contain api_key: \(url)")
    }

    func testSearchGIFsURLContainsLimit() async throws {
        let service = stub(json: sampleListJSON)
        _ = try await service.searchGIFs(apiKey: "KEY", request: AWGiphySearchRequest(query: "cats", limit: 10))
        let url = CapturingURLProtocol.lastRequest?.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains("limit=10"), "URL should contain limit: \(url)")
    }

    func testSearchGIFsURLContainsRatingWhenProvided() async throws {
        let service = stub(json: sampleListJSON)
        _ = try await service.searchGIFs(apiKey: "KEY", request: AWGiphySearchRequest(query: "cats", rating: "g"))
        let url = CapturingURLProtocol.lastRequest?.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains("rating=g"), "URL should contain rating: \(url)")
    }

    func testSearchGIFsHTTP500ThrowsAPIError() async {
        let service = stub(json: "", statusCode: 500)
        do {
            _ = try await service.searchGIFs(apiKey: "KEY", request: AWGiphySearchRequest(query: "cats"))
            XCTFail("Expected error")
        } catch let error as AWGiphyAPIError {
            if case .apiError(let code, _) = error {
                XCTAssertEqual(code, 500)
            } else {
                XCTFail("Expected apiError, got \(error)")
            }
        } catch {
            XCTFail("Expected AWGiphyAPIError, got \(error)")
        }
    }

    func testSearchGIFsBadJSONThrowsParsingError() async {
        let service = stub(json: "{bad json}")
        do {
            _ = try await service.searchGIFs(apiKey: "KEY", request: AWGiphySearchRequest(query: "cats"))
            XCTFail("Expected error")
        } catch AWGiphyAPIError.parsingError {
            // expected
        } catch {
            XCTFail("Expected parsingError, got \(error)")
        }
    }

    func testSearchGIFsURLErrorBecomesNetworkError() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [FailingURLProtocol.self]
        let failSession = URLSession(configuration: config)
        let service = StubService(urlSession: failSession)
        do {
            _ = try await service.searchGIFs(apiKey: "KEY", request: AWGiphySearchRequest(query: "cats"))
            XCTFail("Expected error")
        } catch AWGiphyAPIError.networkError {
            // expected
        } catch {
            XCTFail("Expected networkError, got \(error)")
        }
    }

    // MARK: trendingGIFs

    func testTrendingGIFsReturnsGIFs() async throws {
        let service = stub(json: sampleListJSON)
        let (gifs, _) = try await service.trendingGIFs(apiKey: "KEY", request: AWGiphyTrendingRequest())
        XCTAssertEqual(gifs.count, 1)
    }

    func testTrendingGIFsURLContainsTrendingPath() async throws {
        let service = stub(json: sampleListJSON)
        _ = try await service.trendingGIFs(apiKey: "KEY", request: AWGiphyTrendingRequest())
        let url = CapturingURLProtocol.lastRequest?.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains("/trending"), "URL should contain /trending: \(url)")
    }

    // MARK: getGIF

    func testGetGIFReturnsGIF() async throws {
        let service = stub(json: sampleSingleJSON)
        let gif = try await service.getGIF(apiKey: "KEY", id: "abc123")
        XCTAssertEqual(gif.id, "abc123")
        XCTAssertEqual(gif.title, "Funny Cat")
    }

    func testGetGIFURLContainsID() async throws {
        let service = stub(json: sampleSingleJSON)
        _ = try await service.getGIF(apiKey: "KEY", id: "xyz999")
        let url = CapturingURLProtocol.lastRequest?.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains("xyz999"), "URL should contain GIF ID: \(url)")
    }

    // MARK: downloadImageData

    func testDownloadImageDataReturnsData() async throws {
        let expected = "fake-image-bytes".data(using: .utf8)!
        CapturingURLProtocol.stubbedData = expected
        CapturingURLProtocol.stubbedStatusCode = 200
        let service = StubService(urlSession: makeSession())
        let data = try await service.downloadImageData(from: URL(string: "https://media.giphy.com/test.gif")!)
        XCTAssertEqual(data, expected)
    }

    func testDownloadImageDataNonOKThrows() async {
        CapturingURLProtocol.stubbedData = Data()
        CapturingURLProtocol.stubbedStatusCode = 404
        let service = StubService(urlSession: makeSession())
        do {
            _ = try await service.downloadImageData(from: URL(string: "https://media.giphy.com/test.gif")!)
            XCTFail("Expected error")
        } catch AWGiphyAPIError.apiError(let code, _) {
            XCTAssertEqual(code, 404)
        } catch {
            XCTFail("Expected AWGiphyAPIError, got \(error)")
        }
    }
}

// MARK: - AWGiphyPhotosProtocolTests

final class AWGiphyPhotosProtocolTests: XCTestCase {
    func testDefaultURLSessionIsShared() {
        struct Conformer: AWGiphyPhotosProtocol {}
        XCTAssertTrue(Conformer().urlSession === URLSession.shared)
    }

    func testCustomURLSessionInjected() {
        let custom = makeSession()
        let svc = StubService(urlSession: custom)
        XCTAssertTrue(svc.urlSession === custom)
    }
}

// MARK: - AWGiphyServiceTests

final class AWGiphyServiceTests: XCTestCase {
    func testDefaultInitUsesSharedSession() {
        let svc = AWGiphyService()
        XCTAssertTrue(svc.urlSession === URLSession.shared)
    }

    func testCustomSessionInjected() {
        let custom = makeSession()
        let svc = AWGiphyService(urlSession: custom)
        XCTAssertTrue(svc.urlSession === custom)
    }

    func testConformsToProtocol() {
        let svc: any AWGiphyPhotosProtocol = AWGiphyService()
        XCTAssertNotNil(svc)
    }
}

// MARK: - AWGiphyAPIErrorTests

final class AWGiphyAPIErrorTests: XCTestCase {
    func testNetworkErrorEquality() {
        XCTAssertEqual(AWGiphyAPIError.networkError, AWGiphyAPIError.networkError)
    }

    func testParsingErrorEquality() {
        XCTAssertEqual(AWGiphyAPIError.parsingError, AWGiphyAPIError.parsingError)
    }

    func testAPIErrorEquality() {
        XCTAssertEqual(AWGiphyAPIError.apiError(code: 404, message: "Not Found"),
                       AWGiphyAPIError.apiError(code: 404, message: "Not Found"))
    }

    func testAPIErrorDifferentCodeNotEqual() {
        XCTAssertNotEqual(AWGiphyAPIError.apiError(code: 404, message: "Not Found"),
                          AWGiphyAPIError.apiError(code: 500, message: "Not Found"))
    }
}
