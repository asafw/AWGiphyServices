// DemoViewModel.swift — Observable state connecting the UI to AWGiphyServices.

import Foundation
import Observation
import AWGiphyServices

/// Drives the demo UI. Conforms to `AWGiphyPhotosProtocol` so it can exercise
/// the full public API surface of AWGiphyServices directly.
@Observable @MainActor final class DemoViewModel: AWGiphyPhotosProtocol {

    // Both protocol default and concrete conformance use URLSession.shared.
    var urlSession: URLSession { .shared }

    // MARK: - Configuration

    /// Set via GIPHY_API_KEY env var or the in-app field.
    var apiKey: String = ProcessInfo.processInfo.environment["GIPHY_API_KEY"]
        ?? (try? String(contentsOfFile: "/tmp/GIPHY_API_KEY", encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines)
        ?? ""

    // MARK: - Search state

    var searchText: String = ""
    var gifs: [AWGiphyGIF] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var currentOffset: Int = 0
    var totalCount: Int = 0
    var showTrending: Bool = true

    // MARK: - Detail

    var selectedGIF: AWGiphyGIF? = nil

    // MARK: - Init

    init() {
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if env["MOCK_GIFS"] != nil {
            gifs = DemoViewModel.mockGIFs
        }
        #endif
    }

    // MARK: - Actions

    var hasMorePages: Bool { gifs.count < totalCount }

    func loadTrending() {
        guard !apiKey.isEmpty else {
            errorMessage = "Set your API key via GIPHY_API_KEY env var or the field above."
            return
        }
        isLoading = true
        errorMessage = nil
        currentOffset = 0
        showTrending = true
        Task {
            do {
                let (fetched, pagination) = try await trendingGIFs(
                    apiKey: apiKey,
                    request: AWGiphyTrendingRequest(limit: 25, offset: 0)
                )
                gifs = fetched
                totalCount = pagination.totalCount ?? 0
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func search() {
        guard !apiKey.isEmpty else {
            errorMessage = "Set your API key via GIPHY_API_KEY env var or the field above."
            return
        }
        guard !searchText.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        currentOffset = 0
        showTrending = false
        Task {
            do {
                let (fetched, pagination) = try await searchGIFs(
                    apiKey: apiKey,
                    request: AWGiphySearchRequest(query: searchText, limit: 25, offset: 0)
                )
                gifs = fetched
                totalCount = pagination.totalCount ?? 0
                currentOffset = fetched.count
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func loadNextPage() {
        guard !isLoading, hasMorePages, !showTrending else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let (fetched, pagination) = try await searchGIFs(
                    apiKey: apiKey,
                    request: AWGiphySearchRequest(query: searchText, limit: 25, offset: currentOffset)
                )
                gifs.append(contentsOf: fetched)
                totalCount = pagination.totalCount ?? 0
                currentOffset += fetched.count
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func selectGIF(_ gif: AWGiphyGIF) {
        selectedGIF = gif
    }

    // MARK: - Mock data

    #if DEBUG
    static let mockGIFs: [AWGiphyGIF] = {
        let json = """
        [
          {"id":"mock1","title":"Mock GIF 1","slug":"mock-gif-1","url":"https://giphy.com/gifs/mock1","rating":"g","username":"","images":{"fixed_height":{"url":"https://media.giphy.com/media/mock1/200.gif","mp4":null,"webp":null,"width":"267","height":"200"},"fixed_height_still":{"url":"https://media.giphy.com/media/mock1/200_s.gif","mp4":null,"webp":null,"width":"267","height":"200"},"fixed_height_small":{"url":"https://media.giphy.com/media/mock1/100.gif","mp4":null,"webp":null,"width":"133","height":"100"},"fixed_width":{"url":"https://media.giphy.com/media/mock1/200w.gif","mp4":null,"webp":null,"width":"200","height":"150"},"fixed_width_still":{"url":null,"mp4":null,"webp":null,"width":"200","height":"150"},"original":{"url":"https://media.giphy.com/media/mock1/giphy.gif","mp4":null,"webp":null,"width":"480","height":"360"},"downsized":{"url":"https://media.giphy.com/media/mock1/giphy-downsized.gif","mp4":null,"webp":null,"width":"480","height":"360"}}},
          {"id":"mock2","title":"Mock GIF 2","slug":"mock-gif-2","url":"https://giphy.com/gifs/mock2","rating":"g","username":"","images":{"fixed_height":{"url":"https://media.giphy.com/media/mock2/200.gif","mp4":null,"webp":null,"width":"267","height":"200"},"fixed_height_still":{"url":"https://media.giphy.com/media/mock2/200_s.gif","mp4":null,"webp":null,"width":"267","height":"200"},"fixed_height_small":{"url":"https://media.giphy.com/media/mock2/100.gif","mp4":null,"webp":null,"width":"133","height":"100"},"fixed_width":{"url":"https://media.giphy.com/media/mock2/200w.gif","mp4":null,"webp":null,"width":"200","height":"150"},"fixed_width_still":{"url":null,"mp4":null,"webp":null,"width":"200","height":"150"},"original":{"url":"https://media.giphy.com/media/mock2/giphy.gif","mp4":null,"webp":null,"width":"480","height":"360"},"downsized":{"url":"https://media.giphy.com/media/mock2/giphy-downsized.gif","mp4":null,"webp":null,"width":"480","height":"360"}}}
        ]
        """
        return (try? JSONDecoder().decode([AWGiphyGIF].self, from: json.data(using: .utf8)!)) ?? []
    }()
    #endif
}
