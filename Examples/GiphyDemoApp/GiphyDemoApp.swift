// GiphyDemoApp.swift — Entry point for the GiphyDemoApp example.
//
// macOS: swift run GiphyDemoApp  (from the package root)
// Set GIPHY_API_KEY env var or write the key to /tmp/GIPHY_API_KEY.

import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

@main
struct GiphyDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                #if os(macOS)
                .frame(minWidth: 640, minHeight: 520)
                #endif
                .onAppear {
                    #if canImport(AppKit)
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                    #endif
                }
        }
    }
}
