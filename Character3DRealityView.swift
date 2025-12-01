
//
//  Character3D_RealityKit.swift
//  Element8
//
//  Created by Copilot on 2025-12-01 (example).
//  RealityKit-based SwiftUI wrapper that loads a USDZ model and plays named animations.
//  Uses ARView for rendering; does not enable AR by default (use non-AR camera).
//
//  Usage:
//    Character3DRealityView(profileKey: "fire", preferredAnimation: "idle")
// Note: Add RealityKit and import ARKit if you want AR features. This wrapper uses RealityKit.ModelEntity.
//
// Requirements:
//   - iOS 13+ with RealityKit available (RealityKit 1+). Some runtime methods are newer — test on your target OS.
//
import SwiftUI
import RealityKit
import Combine
#if canImport(ARKit)
import ARKit
#endif

/// A SwiftUI wrapper that hosts an ARView (RealityKit) and loads a ModelEntity from a USDZ file
/// named "<profileKey>.usdz" found in main bundle. It plays available animation clips by name.
public struct Character3DRealityView: UIViewRepresentable {
    public var profileKey: String
    public var preferredAnimation: String? = "idle"
    public var autoPlay: Bool = true
    public var modelScale: SIMD3<Float> = SIMD3(repeating: 1.0)
    public var loopAnimation: Bool = true
    public var onTap: (() -> Void)? = nil

    public init(profileKey: String,
                preferredAnimation: String? = "idle",
                autoPlay: Bool = true,
                modelScale: SIMD3<Float> = SIMD3(repeating: 1.0),
                loopAnimation: Bool = true,
                onTap: (() -> Void)? = nil) {
        self.profileKey = profileKey
        self.preferredAnimation = preferredAnimation
        self.autoPlay = autoPlay
        self.modelScale = modelScale
        self.loopAnimation = loopAnimation
        self.onTap = onTap
    }

    public func makeUIView(context: Context) -> ARView {
        // Create ARView but disable AR tracking for an ordinary non-AR scene.
        let arView = ARView(frame: .zero)
        arView.environment.background = .color(.clear)
        arView.automaticallyConfigureSession = false

        // Add a camera transform to view entities without AR.
        let cameraEntity = PerspectiveCamera()
        cameraEntity.transform.translation = SIMD3(0, 0.6, 2.4)
        cameraEntity.look(at: SIMD3(0, 0.4, 0))
        arView.scene.anchors.append(AnchorEntity(world: .zero)) // ensure scene exists

        // Disable gestures if you don't want default gestures enabled
        arView.installGestures([.all], for: nil) // optional, set to [] to disable

        // Load the model async
        Task {
            await loadModelAsync(into: arView)
        }

        // Add tap recognizer using RealityKit gestures
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        return arView
    }

    public func updateUIView(_ uiView: ARView, context: Context) {
        // Could swap model or update playback state here
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Loading

    private func modelURLForProfileKey(_ key: String) -> URL? {
        if let url = Bundle.main.url(forResource: key, withExtension: "usdz") { return url }
        if let url2 = Bundle.main.url(forResource: key, withExtension: "rcproject") { return url2 } // optional
        return nil
    }

    private func anchorName(for profileKey: String) -> String {
        "anchor_\(profileKey)"
    }

    @MainActor
    private func loadModelAsync(into arView: ARView) async {
        guard let modelURL = modelURLForProfileKey(profileKey) else {
            return
        }

        // Load the model as a ModelEntity via RealityKit's async loader
        do {
            let modelEntity = try await Entity.loadAsync(contentsOf: modelURL)
            // Build anchor at origin
            let anchor = AnchorEntity(world: SIMD3<Float>(0, 0, 0))
            modelEntity.name = profileKey
            modelEntity.transform.scale = modelScale
            anchor.addChild(modelEntity)
            arView.scene.anchors.append(anchor)

            // Try to play the preferred animation if found
            if autoPlay, let animName = preferredAnimation {
                // List available animations
                if let available = modelEntity.availableAnimations, !available.isEmpty {
                    // Try to find matching animation by name
                    if let match = available.first(where: { $0.name == animName }) {
                        let playback = modelEntity.playAnimation(match.repeat(loopAnimation ? .repeatForever : .limit(1)), transitionDuration: 0.15, startsPaused: false)
                        // Optionally store playback token somewhere (events, etc.)
                        _ = playback
                    } else {
                        // If not found by name, play the first animation
                        let first = available.first!
                        _ = modelEntity.playAnimation(first.repeat(loopAnimation ? .repeatForever : .limit(1)))
                    }
                }
            }
        } catch {
            print("Failed to load model for key \(profileKey): \(error)")
        }
    }

    // MARK: - Coordinator

    public class Coordinator: NSObject {
        var parent: Character3DRealityView
        init(_ parent: Character3DRealityView) {
            self.parent = parent
            super.init()
        }
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            parent.onTap?()
        }
    }
}
