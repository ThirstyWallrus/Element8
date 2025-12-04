//
//  Element8App.swift
//  Element8
//
//  Created by Dynasty Stat Drop on 3/14/25.
//  Updated on 2025-12-01: use scale-to-fit root wrapper to ensure views are centered and fully visible.
//  Updated 2025-12-04: register bundled fonts at startup using FontLoader.
//

import SwiftUI

@main
struct Element8App: App {
    init() {
        // Register fonts found in the app bundle at startup.
        // This is safe and idempotent; it helps when Info.plist UIAppFonts is missing
        // or when fonts were added without restarting Xcode / cleaning the build.
        FontLoader.registerAllBundleFonts()

        #if DEBUG
        // Optional: re-print mapping (already printed by FontLoader) so it's clearly visible near app startup logs.
        let mapping = FontLoader.mapRegisteredBundleFonts()
        if !mapping.isEmpty {
            print("Element8App: Font PostScript name -> filename mapping (DEBUG):")
            for (postScript, filename) in mapping.sorted(by: { $0.key < $1.key }) {
                print("  \(postScript)  ->  \(filename)")
            }
        } else {
            print("Element8App: No bundle font mapping found (DEBUG).")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            AppRootView {
                ContentView()
            }
        }
    }
}

/// A preference key used to pass measured content size from child -> parent.
private struct ContentSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

/// AppRootView:
/// - draws a global Sepia background that fills the window,
/// - measures the intrinsic size of `content`,
/// - computes a uniform scale factor so content fits in the measured window if needed,
/// - centers the content and applies the computed scale.
struct AppRootView<Content: View>: View {
    private let content: Content
    @State private var contentSize: CGSize = .zero

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("Sepia BG")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Group {
                    content
                        .background(
                            GeometryReader { proxy -> Color in
                                let size = proxy.size
                                DispatchQueue.main.async {
                                    self.contentSize = size
                                }
                                return Color.clear
                            }
                        )
                }
                .scaleEffect(computeScale(container: geo.size, content: contentSize), anchor: .center)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func computeScale(container: CGSize, content: CGSize) -> CGFloat {
        guard container.width > 0, container.height > 0, content.width > 0, content.height > 0 else {
            return 1.0
        }
        let scaleX = container.width / content.width
        let scaleY = container.height / content.height
        let scale = min(1.0, min(scaleX, scaleY))
        if scale.isFinite && scale > 0 { return scale }
        return 1.0
    }
}
