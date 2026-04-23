// GIFGridView.swift — Scrollable grid of GIF thumbnails with infinite scroll.

import SwiftUI
import AWGiphyServices

struct GIFGridView: View {

    var viewModel: DemoViewModel

    private let columns = [GridItem(.adaptive(minimum: 120, maximum: 160))]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(viewModel.gifs) { gif in
                    GIFThumbnailView(gif: gif, viewModel: viewModel)
                        .onAppear {
                            if gif.id == viewModel.gifs.last?.id {
                                viewModel.loadNextPage()
                            }
                        }
                }
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .gridCellColumns(columns.count)
                        .padding()
                }
            }
            .padding()
        }
    }
}

// MARK: - Thumbnail cell

private struct GIFThumbnailView: View {

    let gif: AWGiphyGIF
    var viewModel: DemoViewModel

    @State private var imageData: Data? = nil

    private struct Loader: AWGiphyPhotosProtocol {}
    private let loader = Loader()

    var body: some View {
        Button {
            viewModel.selectGIF(gif)
        } label: {
            Group {
                if let data = imageData, let image = platformImage(from: data) {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .foregroundStyle(.quaternary)
                        .overlay { ProgressView() }
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(.rect(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .task(id: gif.id) {
            guard let urlString = gif.images.fixedHeightSmall.url,
                  let url = URL(string: urlString) else { return }
            imageData = try? await loader.downloadImageData(from: url)
        }
    }

    #if canImport(UIKit)
    private func platformImage(from data: Data) -> Image? {
        guard let ui = UIImage(data: data) else { return nil }
        return Image(uiImage: ui)
    }
    #elseif canImport(AppKit)
    private func platformImage(from data: Data) -> Image? {
        guard let ns = NSImage(data: data) else { return nil }
        return Image(nsImage: ns)
    }
    #endif
}
