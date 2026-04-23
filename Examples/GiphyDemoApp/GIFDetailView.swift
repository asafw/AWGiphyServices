// GIFDetailView.swift — Detail sheet showing the original rendition + metadata.

import SwiftUI
import AWGiphyServices

struct GIFDetailView: View {

    let gif: AWGiphyGIF
    var viewModel: DemoViewModel

    @State private var imageData: Data? = nil
    @Environment(\.dismiss) private var dismiss

    private struct Loader: AWGiphyPhotosProtocol {}
    private let loader = Loader()

    /// nil on macOS (treated as non-compact → HStack layout)
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if sizeClass == .compact {
                VStack(alignment: .leading, spacing: 16) {
                    imageArea.frame(maxHeight: 320)
                    metadataArea
                        .padding(.horizontal)
                }
            } else {
                HStack(alignment: .top, spacing: 24) {
                    imageArea.frame(maxWidth: 400, maxHeight: 400)
                    metadataArea.frame(width: 240)
                }
                .padding()
            }
        }
        #if os(macOS)
        .frame(minWidth: 560, minHeight: 360)
        #endif
        .navigationTitle(gif.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        #endif
        .task {
            guard let urlString = gif.images.original.url ?? gif.images.downsized.url,
                  let url = URL(string: urlString) else { return }
            imageData = try? await loader.downloadImageData(from: url)
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var imageArea: some View {
        Group {
            if let data = imageData, let image = platformImage(from: data) {
                image
                    .resizable()
                    .scaledToFit()
            } else {
                Rectangle()
                    .foregroundStyle(.quaternary)
                    .overlay { ProgressView("Loading…") }
            }
        }
        .clipShape(.rect(cornerRadius: 10))
    }

    private var metadataArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(gif.title.isEmpty ? "(no title)" : gif.title)
                .font(.title2).bold()

            if !gif.username.isEmpty {
                infoRow(label: "By", value: gif.username)
            }
            infoRow(label: "Rating", value: gif.rating.uppercased())

            Link("View on Giphy", destination: URL(string: gif.url)!)
                .font(.subheadline)
                .padding(.top, 4)

            Spacer()
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(label + ":")
                .foregroundStyle(.secondary)
                .fixedSize()
            Text(value)
        }
        .font(.subheadline)
    }

    // MARK: - Platform image helper

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
