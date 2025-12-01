//
//  Element8App.swift
//  Element8
//
//  Created by Dynasty Stat Drop on 3/14/25.
//  Updated on 2025-12-01: use scale-to-fit root wrapper to ensure views are centered and fully visible.
//  Purpose: Provide a top-level AppRootView that centers app content and scales it down when it would otherwise overflow.
//

import SwiftUI

@main
struct Element8App: App {
    var body: some Scene {
        WindowGroup {
            // Wrap the entire app in AppRootView which measures the content and the window
            // and scales the content down only when necessary so the entire UI remains visible and centered.
            AppRootView {
                // Main app entry view (navigation is handled inside)
                ContentView()
            }
        }
    }
}

/// A preference key used to pass measured content size from child -> parent.
private struct ContentSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        // Keep the latest non-zero size (or zero if none). This is sufficient for layout measurement.
        let next = nextValue()
        if next != .zero { value = next }
    }
}

/// AppRootView:
/// - draws a global Sepia background that fills the window,
/// - measures the intrinsic size of `content`,
/// - computes a uniform scale factor so content fits in the measured window if needed,
/// - centers the content and applies the computed scale.
///
struct AppRootView<Content: View>: View {
    private let content: Content
    
    // Measured size of the content's natural layout.
    @State private var contentSize: CGSize = .zero
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Global background applied once at the root so child views do not need to add full-screen backgrounds.
                Image("Sepia")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                // Place the content in a centered container.
                // We measure the content's natural size (via a background GeometryReader that writes to a PreferenceKey)
                // and compute a scale so the content always fits within geo.size while keeping its aspect ratio.
                Group {
                    content
                        // Measure the content's natural size.
                        .background(
                            GeometryReader { proxy -> Color in
                                let size = proxy.size
                                // Publish the measured size via preference
                                DispatchQueue.main.async {
                                    // Update on main thread to avoid layout warnings.
                                    self.contentSize = size
                                }
                                return Color.clear
                            }
                        )
                }
                // Compute scale with a safe guard against zero sizes. We only scale down (scale <= 1).
                .scaleEffect(computeScale(container: geo.size, content: contentSize), anchor: .center)
                // Ensure the content is centered in the window and has at most the window size.
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            }
            // Make sure stack fills the available geometry.
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
    
    /// Compute a uniform scale factor (<= 1) so content fits into container while preserving aspect ratio.
    /// If content or container sizes are zero, return 1 (no scaling).
    private func computeScale(container: CGSize, content: CGSize) -> CGFloat {
        guard container.width > 0, container.height > 0, content.width > 0, content.height > 0 else {
            return 1.0
        }
        let scaleX = container.width / content.width
        let scaleY = container.height / content.height
        let scale = min(1.0, min(scaleX, scaleY))
        // Avoid returning NaN or infinite values.
        if scale.isFinite && scale > 0 {
            return scale
        } else {
            return 1.0
        }
    }
}
