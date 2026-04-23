// AWGiphyServicesIntegrationTests.swift — Live network tests for AWGiphyServices.
// These tests require a valid Giphy API key and make real network requests.
// They are skipped automatically in CI (where the CI env var is set).

import XCTest
@testable import AWGiphyServices

private func readCredential(_ name: String) -> String? {
    if let env = ProcessInfo.processInfo.environment[name], !env.isEmpty { return env }
    let path = "/tmp/\(name)"
    return (try? String(contentsOfFile: path, encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines)
}

private let isCI = ProcessInfo.processInfo.environment["CI"] != nil

// MARK: - GiphySearchIntegrationTests

final class GiphySearchIntegrationTests: XCTestCase {

    private var apiKey: String!
    private var service: AWGiphyService!

    override func setUp() async throws {
        try await super.setUp()
        try XCTSkipIf(isCI, "Skipping live network tests in CI")
        guard let key = readCredential("GIPHY_API_KEY") else {
            throw XCTSkip("Set GIPHY_API_KEY env var or write key to /tmp/GIPHY_API_KEY")
        }
        apiKey = key
        service = AWGiphyService()
    }

    func testSearchReturnsResults() async throws {
        let (gifs, pagination) = try await service.searchGIFs(
            apiKey: apiKey,
            request: AWGiphySearchRequest(query: "cats", limit: 5)
        )
        XCTAssertFalse(gifs.isEmpty, "Expected at least one GIF")
        XCTAssertEqual(gifs.count, pagination.count)
    }

    func testSearchResultsHaveIDs() async throws {
        let (gifs, _) = try await service.searchGIFs(
            apiKey: apiKey,
            request: AWGiphySearchRequest(query: "dogs", limit: 3)
        )
        for gif in gifs {
            XCTAssertFalse(gif.id.isEmpty, "GIF id should not be empty")
        }
    }

    func testSearchPaginationDistinctIDs() async throws {
        let (page1, _) = try await service.searchGIFs(
            apiKey: apiKey,
            request: AWGiphySearchRequest(query: "space", limit: 5, offset: 0)
        )
        let (page2, _) = try await service.searchGIFs(
            apiKey: apiKey,
            request: AWGiphySearchRequest(query: "space", limit: 5, offset: 5)
        )
        let ids1 = Set(page1.map(\.id))
        let ids2 = Set(page2.map(\.id))
        XCTAssertTrue(ids1.isDisjoint(with: ids2), "Pages should return distinct GIFs")
    }

    func testSearchFixedHeightURLNotEmpty() async throws {
        let (gifs, _) = try await service.searchGIFs(
            apiKey: apiKey,
            request: AWGiphySearchRequest(query: "happy", limit: 1)
        )
        let url = gifs.first?.images.fixedHeight.url ?? ""
        XCTAssertFalse(url.isEmpty, "fixedHeight URL should not be empty")
    }

    func testSearchInvalidKeyThrowsAPIError() async throws {
        do {
            _ = try await service.searchGIFs(
                apiKey: "invalid_key",
                request: AWGiphySearchRequest(query: "cats")
            )
            XCTFail("Expected error for invalid API key")
        } catch AWGiphyAPIError.apiError(let code, _) {
            XCTAssertEqual(code, 403, "Expected 403 for invalid key, got \(code)")
        } catch {
            XCTFail("Expected AWGiphyAPIError.apiError, got \(error)")
        }
    }

    func testTrendingReturnsResults() async throws {
        let (gifs, _) = try await service.trendingGIFs(
            apiKey: apiKey,
            request: AWGiphyTrendingRequest(limit: 5)
        )
        XCTAssertFalse(gifs.isEmpty, "Expected trending GIFs")
    }

    func testGetGIFByID() async throws {
        let (gifs, _) = try await service.searchGIFs(
            apiKey: apiKey,
            request: AWGiphySearchRequest(query: "celebrate", limit: 1)
        )
        let first = try XCTUnwrap(gifs.first, "Expected at least one GIF from search")
        let fetched = try await service.getGIF(apiKey: apiKey, id: first.id)
        XCTAssertEqual(fetched.id, first.id)
    }

    func testDownloadImageDataNonEmpty() async throws {
        let (gifs, _) = try await service.searchGIFs(
            apiKey: apiKey,
            request: AWGiphySearchRequest(query: "fire", limit: 1)
        )
        let gif = try XCTUnwrap(gifs.first, "Expected at least one GIF from search")
        let urlString = try XCTUnwrap(gif.images.fixedHeightSmall.url, "Expected fixedHeightSmall URL")
        let url = try XCTUnwrap(URL(string: urlString), "Expected valid URL")
        let data = try await service.downloadImageData(from: url)
        XCTAssertFalse(data.isEmpty, "Downloaded data should not be empty")
    }

    func testDownloadImageDataIsGIFMagicBytes() async throws {
        let (gifs, _) = try await service.searchGIFs(
            apiKey: apiKey,
            request: AWGiphySearchRequest(query: "dance", limit: 1)
        )
        let gif = try XCTUnwrap(gifs.first, "Expected at least one GIF from search")
        let urlString = try XCTUnwrap(gif.images.fixedHeightSmall.url, "Expected fixedHeightSmall URL")
        let url = try XCTUnwrap(URL(string: urlString), "Expected valid URL")
        let data = try await service.downloadImageData(from: url)
        // GIF89a or GIF87a magic bytes
        let magic = Array(data.prefix(6))
        XCTAssertEqual(magic[0], 0x47, "Expected 'G'")
        XCTAssertEqual(magic[1], 0x49, "Expected 'I'")
        XCTAssertEqual(magic[2], 0x46, "Expected 'F'")
    }
}
