//
//  Element8App.swift
//  Element8
//
//  Created by Dynasty Stat Drop on 3/14/25.
//

import SwiftUI

@main
struct Element8App: App {
    var body: some Scene {
        WindowGroup {
            // Wrap the entire app in AppRootView which measures the window
            // and constrains the app's content to that exact size. This provides
            // a global guard that prevents child views from spilling off-screen.
            AppRootView {
                // Main app entry view (navigation is handled inside)
                ContentView()
            }
        }
    }
}

/// AppRootView is a thin top-level wrapper that:
///  - provides the global background (Sepia) that fills the window,
///  - measures the window size via GeometryReader, and
///  - applies a frame(width:height:) and .clipped() to the app content so
///    child views cannot request sizes larger than the visible window.
///
/// This is a conservative global constraint and avoids touching individual
/// view layouts. If you prefer different behavior (scale-to-fit instead of
/// clipping, or automatic scroll fallback), I can add that as a configurable
/// option.
struct AppRootView<Content: View>: View {
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Global background: Sepia applied here so every view in the window group
                // inherits the background and we avoid duplicating full-screen images
                Image("Sepia")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                // Constraining container: make the content match the window size exactly.
                // This prevents views from overflowing the visible area; content that
                // requests larger sizes will be clipped to the window bounds.
                VStack(spacing: 0) {
                    content
                        // Enforce the content to be the same size as the measured window.
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                // Also ensure the container itself matches the window; this makes layout predictable.
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}
