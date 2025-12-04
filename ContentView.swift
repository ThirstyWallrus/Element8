//
//  ContentView.swift
//  Element8
//
//  Created by Dynasty Stat Drop on 3/14/25.
//  Updated by Copilot on 2025-12-01 to use global Sepia background, increase title size, and refine layout.
//  Updated by Copilot on 2025-12-01 to include Star Wars-style intro crawl (backstory).
//

import SwiftUI

struct ContentView: View {
    // ----- BEGIN: Edit your backstory here -----
    // Replace the text below with your Star-Wars-style backstory.
    // Keep the string triple-quoted for multi-line content.
    // Example:
    // let storyText = """
    //  A long time ago...
    //  Many things happened...
    //  """
    //
    // NOTE: Do not remove the `storyText` variable — just replace its contents.
    private let storyText: String =
    """
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    Strife and war this world tore
    Conflict betweencities four
    Each one to patron two
    The forces of nature true
    
    Jungle lands of the East
    Revere the Sun Plants and Beast
    Western skies fill with Thunder
    From Magnetic power turned asunder
    
    While Firey volcanoes rise forth
    From the depths of the Northern Earth
    In the South the seas do entrance
    With the Wind in a raging dance
    
    But a greater power than all
    Will soon bring their downfall
    A flare from a dying star
    Tears the world from afar
    
    In the attack the void is sprung
    And thus the requiem is rung
    The chaotic void dispels force
    That animates natures course
    
    Now the elements strive
    That the world will survive
    Defeating the others is the Key
    Willing the sacrifice cannot be
    To preserve the worlds life
    There is purpose to their strife
    
    But who will be the one
    To slay the rest and leave none
    For claim of all life you now fight
    To stem the world of the void's blight
    
    
    
    """
    // ----- END: Edit your backstory here -----

    // Whether to show the cinematic intro. If you prefer to always skip it,
    // set this to false or add persistent logic (UserDefaults) to remember skip.
    @State private var showIntro: Bool = true

    var body: some View {
        NavigationStack {
            ZStack {
                // No per-view full-screen background here — the app's global Sepia background is applied in Element8App.
                if showIntro {
                    IntroView(story: storyText, onFinish: {
                        // When the intro finishes or user skips, show the main landing UI.
                        withAnimation { showIntro = false }
                    })
                    .transition(.opacity)
                } else {
                    // Original landing content preserved (logo + enter button)
                    LandingView()
                        .transition(.opacity)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - LandingView (original simplified landing UI)
private struct LandingView: View {
    var body: some View {
        ZStack {
            VStack {
                Spacer()

                // Central logo / title image (increased size for stronger branding)
                Image("Element8Title")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 640, maxHeight: 260) // increased size
                    .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
                    .padding(.horizontal, 24)

                Spacer()

                // Enter button to proceed into HomeView for continuity
                NavigationLink(destination: HomeView()) {
                    Text("Enter")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 36)
                        .background(.black.opacity(0.6))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
                }
                .padding(.bottom, 36)
            }
        }
    }
}

// MARK: - IntroView: Star Wars-style crawl under the Element8 title
private struct IntroView: View {
    let story: String
    var onFinish: (() -> Void)? = nil

    // Animation state
    @State private var crawlOffset: CGFloat = 0
    @State private var textHeight: CGFloat = 0
    @State private var containerHeight: CGFloat = 0
    @State private var isAnimating: Bool = false
    @State private var didFinish: Bool = false

    // Timing configuration (adjust duration to taste)
    private let initialDelay: TimeInterval = 0.8
    // NOTE: Changed to slow the crawl to 50% of the original speed (i.e., half-speed).
    // Original value: 0.006 seconds per point. Doubling it to 0.012 yields a 50% slower crawl.
    private let crawlDurationPerPoint: Double = 0.012 // seconds per point of movement (tunable)
    private let extraPadding: CGFloat = 60 // extra travel so text fully leaves view

    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(spacing: 16) {
                    Spacer(minLength: 24)

                    // Title image remains centered at top
                    Image("Element8Title")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: min(geo.size.width * 0.9, 640), maxHeight: 220)
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
                        .padding(.top, 12)

                    // Crawl container
                    ZStack {
                        // 3D perspective transform anchor
                        VStack {
                            // The moving text stack (measured)
                            ScrollCrawlText(text: story)
                                .frame(width: geo.size.width * 0.86)
                                .fixedSize(horizontal: false, vertical: true)
                                .background(HeightReader()) // measure the text height
                                .onPreferenceChange(ViewHeightKey.self) { h in
                                    // Save measured height for animation calculations
                                    self.textHeight = h
                                    self.containerHeight = geo.size.height * 1.00 // approximation of visible crawl area
                                    // Set initial offset so text starts just below the visible container
                                    if !isAnimating {
                                        self.crawlOffset = containerHeight
                                    }
                                }
                                .offset(y: crawlOffset)
                                // Apply the classic crawl perspective: tilt backwards and slightly scale
                                .rotation3DEffect(.degrees(33), axis: (x: 1, y: 0, z: 0), anchor: .center)
                                .scaleEffect(0.92)
                                .animation(.linear(duration: animationDuration()), value: crawlOffset)
                                .onAppear {
                                    // Start the crawl after short delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
                                        startCrawlIfNeeded()
                                    }
                                }

                            Spacer()
                        }
                        .frame(height: geo.size.height * 0.82)
                        .clipped()

                        // Top fade
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.45)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 40)
                        .allowsHitTesting(false)
                        .alignmentGuide(.top) { _ in 0 }
                        .offset(y: -geo.size.height * 0.46 / 2 + 20)

                        // Bottom fade
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.45), Color.black.opacity(0.0)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 40)
                        .allowsHitTesting(false)
                        .alignmentGuide(.bottom) { _ in 0 }
                        .offset(y: geo.size.height * 0.46 / 2 - 20)

                    }
                    .frame(height: geo.size.height * 0.46)
                    .padding(.horizontal, 8)

                    Spacer()

                    // Controls: Enter (skip) and small hint
                    HStack(spacing: 12) {
                        NavigationLink(destination: HomeView()) {
                            Text("Enter")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 28)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            // If user taps Enter we should stop animation and call onFinish
                            stopCrawlAndFinish()
                        })

                        Button(action: {
                            // Skip only; remain on this view but stop animation then finish
                            stopCrawlAndFinish()
                        }) {
                            Text("Skip Intro")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.bottom, 28)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Tap anywhere to skip quickly
                    stopCrawlAndFinish()
                }
            }
        }
    }

    // MARK: - Animation helpers

    /// Compute an animation duration scaled to text height so longer stories scroll for longer.
    private func animationDuration() -> Double {
        // default fallback distance
        let distance = max((textHeight + containerHeight + extraPadding), 600)
        return max(4.0, Double(distance) * crawlDurationPerPoint)
    }

    /// Start the crawl if not already started.
    private func startCrawlIfNeeded() {
        guard !isAnimating else { return }
        isAnimating = true
        // Compute final offset: move from containerHeight down to -(textHeight + extraPadding)
        let finalOffset = -(textHeight + extraPadding)
        withAnimation(.linear(duration: animationDuration())) {
            self.crawlOffset = finalOffset
        }
        // Schedule finish callback when animation should complete
        let delay = animationDuration() + 0.15
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.didFinish = true
            self.onFinish?()
        }
    }

    /// Stop any active crawl and notify finish.
    private func stopCrawlAndFinish() {
        guard !didFinish else { return }
        didFinish = true
        isAnimating = false
        // Jump the crawl off-screen immediately
        withAnimation(.easeOut(duration: 0.18)) {
            self.crawlOffset = -(textHeight + extraPadding)
        }
        // Notify
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.onFinish?()
        }
    }
}

// MARK: - ScrollCrawlText: styled multiline text for the crawl
private struct ScrollCrawlText: View {
    let text: String

    var body: some View {
        VStack {
            // Use a monospaced-ish, slightly condensed style often used in crawls
            Text(text)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, 8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Height measurement utility
// PreferenceKey to measure a View's height.
private struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct HeightReader: View {
    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(key: ViewHeightKey.self, value: proxy.size.height)
        }
    }
}

// MARK: - Preview

#Preview {
    // For preview, show ContentView alone — previews won't include Element8App's global background.
    ContentView()
}
