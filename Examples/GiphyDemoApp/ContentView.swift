// ContentView.swift — Root view: search bar + GIF grid with trending fallback.

import SwiftUI
import AWGiphyServices

struct ContentView: View {

    @State private var viewModel = DemoViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                apiKeyRow
                Divider()
                searchBar
                Divider()
                resultArea
            }
            .navigationTitle("Giphy Demo")
            .onAppear {
                if viewModel.gifs.isEmpty {
                    viewModel.loadTrending()
                }
            }
        }
        .sheet(item: $viewModel.selectedGIF) { gif in
            GIFDetailView(gif: gif, viewModel: viewModel)
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var apiKeyRow: some View {
        if viewModel.apiKey.isEmpty {
            HStack {
                Text("API Key")
                    .foregroundStyle(.secondary)
                    .fixedSize()
                TextField("Paste your Giphy API key…", text: $viewModel.apiKey)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    private var searchBar: some View {
        HStack {
            TextField("Search GIFs…", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("search_field")
                .onSubmit { viewModel.search() }

            Button("Search") { viewModel.search() }
                .accessibilityIdentifier("search_button")
                .disabled(viewModel.searchText.isEmpty || viewModel.isLoading)

            Button("Trending") { viewModel.loadTrending() }
                .accessibilityIdentifier("trending_button")
                .disabled(viewModel.isLoading)
        }
        .padding()
    }

    @ViewBuilder
    private var resultArea: some View {
        if let error = viewModel.errorMessage {
            Text(error)
                .foregroundStyle(.red)
                .padding()
            Spacer()
        } else if viewModel.isLoading && viewModel.gifs.isEmpty {
            ProgressView(viewModel.showTrending ? "Loading trending…" : "Searching…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.gifs.isEmpty {
            Text("No results.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            GIFGridView(viewModel: viewModel)
        }
    }
}
